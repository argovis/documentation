.. _argo_merge:

Managing Argo Data
==================

Other than the ``argo`` collection, all other collections in Argovis are essentially *static*: the expectation is that they will be updated infrequently and ad-hoc, and the scripts linked above that translate from upstream formats to MongoDB documents are largely simple and unopinionated, mapping keys to keys.

Argo data, on the other hand, is actively managed in two ways:

 - Argovis constructs a *simplified, opinionated profile* for each profile object, that imposes some expertise in interpreting Argo data correctly. This is intended to help downstream consumers who are not experts in Argo's data collection patterns interpret data correctly, while removing as few useful options for them as possible.
 - The Argo collections in MongoDB are automatically updated nightly, and actively monitored for corruption.

Considerations around both these points are enumerated below.

Opinionated profiles
--------------------

A given Argo profile may contain two separate data objects: a core profile measuring pressure, temperature, and salinity; and a BGC profile measuring one or several of many biogeochemical properties. Furthermore, this data may be presented in one of several different modes reflecting the level of cleanup the data has undergone. Argovis seeks to create a single unified JSON document for each profile that merges the core and BGC information and makes good and consistent choices on what mode of data to present, simplifying the consumption of Argo data for users while still accommodating the majority of use cases. This document describes how we take upstream data, and compose it into a JSON document; it effectively describes the algorithm implemented in https://github.com/argovis/ifremer-sync.

Upstream file selection
+++++++++++++++++++++++

For a given profile, first we choose which upstream netcdf files to consider. There are six possibilities: core, BGC, and synthetic files, each reflecting either realtime or delayed data. We choose at most two of these:

 - We prefer the synthetic delayed file to capture BGC information, but accept the synthetic realtime in lieu;
 - We prefer the delayed core file to capture core information, but accept the realtime core file in lieu.

Under no circumstances are standalone BGC files considered at this time.

Data extraction
+++++++++++++++

Once at most one core and at most one synthetic file are identified for a profile, we extract data from each separately as follows.

Metadata extraction
^^^^^^^^^^^^^^^^^^^

Some metadata variables undergo cleaning decisions at this step, as enumerated here:

- **Latitude and longitude** are read from the Argo file's LATITUDE and LONGITUDE variables. If either value is NaN or a fill value, they are set to longitude = 0, latitude = -90 and a ``missing_location`` warning is logged in the ``data_warnings`` record. If longitude is reported on [0,360], it is normalized to [-180,180].
- **_id** is constructed as ``<platform_id>_<cycle_number>``, with ``D`` appended for decending profiles.
- **Basin** is read from a lookup table as a function of extracted latitude and longitude, if a valid pair was found. If the nearest basin gridpoint is NaN, the nearest non-NaN grid point is taken. If all four surrounding grid points are NaN, a ``missing_basin`` warning is logged and the basin index is set to -1.
- **source_info.source** is populated as ``argo_core`` for core files and ``argo_bgc`` for synthetic files. If the deepest pressure in the file is greater than 2500 dbar, an ``argo_deep`` flag is also added.

All other metadata variables are read directly from the corresponding netcdf variables, with minimal typecasting and cleanup.

Level data extraction
^^^^^^^^^^^^^^^^^^^^^

Per-level data is extracted slightly differently for core versus BGC variables.

- **Core variables** are read with the following considerations:

  - Only pressure, temperature, and salinity and their QC are considered in core files. If any other per-level variables are present, they are discarded.
  - If ``DATA_MODE`` for the file is delayed or adjusted, only variables marked ``_ADJUSTED`` are considered.
  - If ``DATA_MODE`` for the file is realtime, then non-adjusted variables are accepted.
  - All variables are assigned a per-variable data mode that matches the file-level data mode
  - If two levels report the same pressure, a ``degenerate_level`` warning is logged
  - Levels are thrown out if they report NaN for pressure.

- **BGC variables** are read with the following considerations:

  - Data mode is determined per variable; if delayed or adjusted mode data is available for a given variable, its ``_ADJUSTED`` entry is taken; if only realtime is available for that variable, then the unadjusted value is accepted.
  - Degenerate level warnings and NaN-pressure level ommissions are per the core data case.
  - If ``temp`` or ``psal`` are reported in a synthetic file, they are relabeled as ``temp_sfile`` and ``psal_sfile`` respectively, along with their QC.

Data merging
++++++++++++

At this stage, there may be as many as two metadata objects, and the same number of data objects for the profile in question. These are merged to a single record per the following.

Metadata merge
^^^^^^^^^^^^^^

- For mandatory keys that should be the same in both metadata objects (like ``_id`` and ``geolocation``), the value from the first metadata record is accepted.
- For optional keys that should be the same in both metadata objects, the value from the first metadata object that reports that key is accepted.
- For keys that preserve a record from each file (like ``source_info`` and ``data_warnings``), the value from each metadata record, if present, is appended to a list.

Level data merge
^^^^^^^^^^^^^^^^

Per-level data is merged along a one-dimensional pressure axis with the following considerations:

- If an individual file's data object carries a ``degenerate_levels`` warning, the per level data from that file is discarded.
- For each observed pressure level, the value of each observed variable and their corresponding QC is recorded, with ``None`` used as a fill for absent information.
- Per-variable data mode is preserved for each variable. If pressure reports a different data mode in core versus synthetic files, the lowest confidence mode is reported: realtime supersedes adjusted supersedes delayed.
- For each individual value, the following normalization is performed:
 
  - bytes are converted to ints (Argo reports QC as byte characters)
  - NaNs are converted to pythonic ``None``
  - Floats are rounded to at most six decimal places

Database considerations
+++++++++++++++++++++++

At the end of the process described above, we have a single JSON document describing the profile of interest, to be written to MongoDB. Write considerations are as follows:

- MongoDB's internal time bson type does not capture sub-millisecond precision; therefore, all times will be rounded off to the ms on write.

Known omissions
+++++++++++++++

Some pathologies in the original data files can cause a profile to fail to write to MongoDB. Observed such conditions are listed here:

 - Missing ``PARAMETER_DATA_MODE``: Argovis has a firm expectation that all variables in a BGC file are reported as exactly one of real-time, adjusted or delayed; if a fill value is detected for any variable in a profile, the profile is omitted.

Nightly updates & integrity checking
------------------------------------

See our `Kubernetes cron job specification <https://github.com/argovis/ifremer-sync/blob/main/ifremer-cron.yaml>`_ for the orchestration and logic that govern nightly Argo collection updates. At high level:

 - ``rsync`` downloads anything new since last time to Argovis' local IFREMER mirror.
 - A script parses the ``rsync`` logs and decides on CRUD operations to perform on the database.
 - A python script performs the enumerated CRUD ops.
 - A log is preserved for auditing purposes

Integrity checking is described in detail in `these docs <https://github.com/argovis/ifremer-sync#integrity-checking>`_ and related scripts. It's best practice for Argovis operators to review the logs of this auditing script periodically to ensure nothing unexpected is happening in the nightly updates.

*Last reviewed 23-03-06*