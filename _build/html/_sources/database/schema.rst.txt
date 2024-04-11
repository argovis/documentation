.. _schema:

Argovis data schema
===================
All data indexed by Argovis follows the schema described in this document. The purpose of this schema is to standardize the representation of profile-, grid-, and sea surface-type datasets to promote their interoperability and underwrite a standardized API to serve them all.

.. admonition:: The Last Word

   In the event of conflicts in schema definition, the implementation at `https://github.com/argovis/db-schema <https://github.com/argovis/db-schema>`_ is to be taken as correct above all others.

A heritable generic schema
--------------------------

Argovis schema are designed to inherited from a semi-well-defined generic schema that structures the most universal aspects of earth system data in a regular fashion, thereby standardizing the commonalities between these dataset representations, while preserving the ability for individual datasets to represent unique data. All datasets in Argovis are thus represented by a pair of collections, one for data, and one for metadata, where the dataset-specific records in each inherit from the generic data and metadata schemas respectively. This can be visualized as per:

.. image:: ../images/schema.png

In other words, *all* data records for *all* datasets include the fields defined below in the generic data record section, and similarly for metadata records. Each dataset can append additional fields to each to capture their specifics; each dataset supported by Argovis has its extension specifics detailed in subsequent sections of this document.

How to read this schema
+++++++++++++++++++++++

Each entry in the schema fragments below contain a few keys:

- **required:** whether or not this attribute can be omitted; "case" indicates case-by-case decisions for different datasets
- **type:** the primitive type,  format,  or object description of a valid entry for this field
- **description:** short comment on what this variable is
- **fill value** (optional): what this should be filled by if absent
- **current vocabulary** (optional): current set of possible values for this key,  with explanations as required.

Schema enforcement & population
+++++++++++++++++++++++++++++++

Argovis uses MongoDB as its backend. All datasets have their data and metadata schema defined in `https://github.com/argovis/db-schema <https://github.com/argovis/db-schema>`_, which includes enforcement of these schema when uploaded to mongodb; therefore, the schema implementation in that code should be considered the most reliable document of our schema.

Generic Point Schema
--------------------

As noted above, generic schema form the basis of all schema in Argovis; this section describes the minimum viable information needed to populate these schema for our point-like datasets. Subsequent sections describe how specific datasets extend and implement these core definitions.

Generic Data Schema
+++++++++++++++++++

In general, data records are intended to represent data that is unique or frequently changing per longitude / latitude / timestamp triple, in order to support efficient temporospatial indexing of these records in Mongodb. All data records contain the following fields:


- ``_id``

  - **required:** true
  - **type:** string
  - **description:** unique record identifier that encodes something meaningful, such as measurement order per platform.

- ``metadata``

  - **required:** true
  - **type:** array
  - **description:** foreign key(s) that matches the ``_id`` of the corresponding metadata record. Preferentially chosen to encode something physically meaningful that corresponds to metadata groupings, like Argo platform ID. If array references exactly one metadata document, then that metadata doc applies to all values in ``data_info[0]`` for this data document; if ``metadata`` lists more than one element, they are to be interpreted as per-item in ``data_info[0]`` (ie, ``metadata[i]`` is the metadata corresponding to ``data_info[0][i]``).

- ``geolocation``

  - **required:** true
  - **type:** geojson Point object
  - **description:** geojson Point tagging the lon/lat of this record.
  - **fill value:** ``{"type": "Point",  "coordinates": [0,  -90]}``

- ``basin``

  - **required:** case
  - **type:** int
  - **description:** integer index of basin.
  - **fill value:** -1,  used if reported lon/lat are not associated with a basin (possibly on land) according to our basin index raster.

- ``timestamp``

  - **required:** case
  - **type:** ISO 8601 UTC datestring,  example ``1999-12-31T23:59:59Z``
  - **description:** time the record measurement was made at.
  - **fill_value:** ``9999-01-01T00:00:00Z``

- ``data``

  - **required:** true in MongoDB; may be filtered out in API.
  - **type:** array of arrays of floats, ints, strings and / or nulls
  - **description:** a matrix of per-level measurements and flags, where ``data[i][j]`` represents the ith variable as ordered by ``data_info[0]``, at the jth depth or pressure level.

Generic Metadata Schema
+++++++++++++++++++++++

In general, metadata records in Argovis are meant to factor out constant or infrequently-changing data from the data records. They only have one required field:

- ``_id``

  - **required:** true
  - **type:** string
  - **description:** unique record identifier referred to by the ``metadata`` field in records from the corresponding data collection.

Besides the trivially required ``_id`` field, there are a set of generic metadata fields, presented in this section, that may, if required or desired, appear in the metadata or data schemas for a given dataset, depending on which choice provides the most efficient encoding for that dataset. Each dataset specified below includes the division of these fields between data and metadata.

- ``data_info``

  - **required:** true
  - **type:** array of arrays of floats, ints, strings and / or nulls
  - **description:** 

    - ``data_info[0]``: array of strings naming the measurements, estimates or flags, in order, found in ``data``.
    - ``data_info[1]``: array of strings naming per-variable metadata items (commonly things like units or long descriptions)
    - ``data_info[2]``: matrix of per-variable metadata, with rows labeled by ``data_info[0]`` and columns labeled by ``data_info[1]``.

- ``data_type``

  - **required:** true
  - **type:** string
  - **description:** token indicating the general class of data
  - **current vocabulary:** ``oceanicProfile``,  ``tropicalCyclone``, ``drifter``, and ``argo_trajectory`` for point-like data, and ``temperature``, ``salinity``, ``ocean_heat_content`` and ``covariance`` for grids.

- ``date_updated_argovis``

  - **required:** true
  - **type:** ISO 8601 UTC datestring,  example ``1999-12-31T23:59:59Z``
  - **description:** time the record was added to Argovis; applies to both metadata records and corresponding data records.

- ``source``

  - **required**: true (insofar as some of its subkeys, below, are required)
  - **type**: array of objects
  - **description**: objects contain information about the upstream files from which this data / metadata was derived; see immediately below for keys of these objects.

- ``source.source``

  - **required:** true
  - **type:** array of strings
  - **description:** data origin, typically used to label major project subdivisions like ``argo_core``, ``argo_bgc`` and ``argo_deep``.

- ``source.url``

  - **required:** false
  - **type:** string
  - **description:** url from where the original data file from which this data and metadata was extracted can be downloaded from.

- ``source.doi``

  - **required:** false
  - **type:** string
  - **description:** DOI for this file.

- ``source.date_updated``

  - **required:** false
  - **type:** ISO 8601 UTC datestring,  example ``1999-12-31T23:59:59Z``
  - **description:** date and time the upstream source file for this record was last modified.

- ``country``

  - **required:** false
  - **type:** string
  - **description:** ISO 3166-1 country code.

- ``data_center``

  - **required:** false
  - **type:** string
  - **description:** entity responsible for processing this record, once received.

- ``data_warning``

  - **required:** false
  - **type:** array of strings
  - **description:** short string tokens indicating possible problems with this record.
  - **current vocabulary:**
  
    - ``degenerate_levels``: data is reported twice for a given pressure / altitude level in a way that cannot be readily resolved
    - ``missing_basin``: unable to determine meaningful basin code, despite having a meaningful lat / lon (edge case in basins lookup grid)
    - ``missing_location``: one or both of longitude and latitude are missing
    - ``missing_timestamp``: no date or time of measurement associated with this profile.

- ``instrument``

  - **required:** false
  - **type:** string
  - **description:** string token describing the device used to make this measurement,  like ``profiling_float``,  ``ship_ctd`` etc.

- ``pi_name``

  - **required:** false
  - **type:** array of strings
  - **description:** name(s) of principle investigator(s).

- ``platform``

  - **required:** false
  - **type:** string
  - **description:** unique identifier for the platform or device responsible for making the measurements included in this recor, where applicable.

- ``platform_type``

  - **required:** false
  - **type:** string
  - **description:** make or model of the platform.

Argo Schema Extension
---------------------

Argovis maintains and indexes a full sync of ifremer's argo data, updated nightly. The Argo data and metadata collections extend and implement the generic schema as follows.

Generic Metadata Division
+++++++++++++++++++++++++

Argo profiles divide the generic metadata fields between data and metadata records per the following. In general, Argo metadata records describe things that are consistent or slowly changing for a particular physical float, while a data record represents an individual profile.

 - Data records:

   - ``date_updated_argovis``
   - ``source``
   - ``data_warning``
   - ``data_info``

 - Metadata records:

   - ``data_type``
   - ``country``
   - ``data_center``
   - ``instrument``
   - ``pi_name``
   - ``platform``
   - ``platform_type``

``_id`` construction
++++++++++++++++++++

 - Data records  ``_id``: ``<platform>_<cycle_number>``
 - Metadata records ``_id``: ``<platform>_m<metadata_number>``, where ``<metadata_number>`` counts from 0 and is prefixed with ``m`` to easily distinguish it from cycle number; allows distinctions to be made if a slow-changing metadata value, like ``pi_name``, changes over the lifetime of the float.

Argo-Specific Data Record Fields
++++++++++++++++++++++++++++++++

Argo treats ``timestamp`` and ``basin`` all as required items on the data document.

The following fields extend the generic data record for Argo:

- ``cycle_number``

  - **required:** true
  - **type:** int
  - **description:** probe cycle index

- ``geolocation_argoqc``

  - **required:** false
  - **type:** int
  - **description:** Argo's position QC flag
  - **fill value:** -1

- ``profile_direction``

  - **required:** false
  - **type:** string
  - **description:** whether the profile was gathered as the float ascended or descended
  - **current vocabulary:** ``A`` scending or ``D`` escending.

- ``timestamp_argoqc``

  - **required:** false
  - **type:** int
  - **description:** Argo's date QC flag
  - **fill value:** -1

- ``vertical_sampling_scheme``

  - **required:** false
  - **type:** string
  - **description:** sampling scheme for this profile.
  - **current vocabulary:** see Argo ref table 16

Argo-Specific Metadata Record Fields
++++++++++++++++++++++++++++++++++++

The following fields extend the generic metadata records for Argo:

- ``fleetmonitoring``

  - **required:** false
  - **type:** string
  - **description:** URL for this float at https://fleetmonitoring.euro-argo.eu/float/

- ``oceanops``

  - **required:** false
  - **type:** string
  - **description:** URL for this float at https://www.ocean-ops.org/board/wa/Platform

- ``positioning_system``

  - **required:** false
  - **type:** string
  - **description:** positioning system for this float.
  - **current vocabulary**: see Argo ref table 9

- ``wmo_inst_type``

  - **required:** false
  - **type**: string
  - **description:** instrument type as indexed by Argo.
  - **current vocabulary:** see Argo ref table 8

Implementation
++++++++++++++

Implementation of Argo's schema and pipelines to load the data from ifremer can be found at the following links.

- Schema implementation and indexing: `https://github.com/argovis/db-schema/blob/main/argo.py <https://github.com/argovis/db-schema/blob/main/argo.py>`_
- Upload pipeline: `https://github.com/argovis/ifremer-sync <https://github.com/argovis/ifremer-sync>`_

CCHDO Schema Extension
------------------------

Argovis serves a selection of ship-based profiles curated by our colleagues at CCHDO. The CCHDO data and metadata collections extend and implement the generic schema as follows.

Generic Metadata Division
+++++++++++++++++++++++++

CCHDO profiles divide the generic metadata fields between data and metadata records per the following. In general, CCHDO metadata records describe things that are consistent or slowly changing for a particular CCHDO cruise, while a data record represents a single profile.

 - Data records:

   - ``source``
   - ``data_warning``
   - ``data_info``

 - Metadata records:

   - ``date_updated_argovis``  
   - ``data_type``
   - ``country``
   - ``data_center``
   - ``instrument``
   - ``pi_name``

``_id`` construction
++++++++++++++++++++

 - Data records ``_id``: ``expo_<expocode>_sta_<station>_cast_<cast>``
 - Metadata records ``_id``: ``<cchdo_cruise_id>_m<metadata_number>``,  where ``<metadata_number>``` counts from 0 and is prefixed with ``m`` similar to Argo; allows distinctions to be made if a slow-changing metadata value, like ``pi_name``, changes over the lifetime of the cruise.

CCHDO-Specific Data Record Fields
+++++++++++++++++++++++++++++++++++

CCHDO treats ``timestamp`` and ``basin`` all as required items on the data document.

The following fields extend the generic data records for CCHDO:

 - ``station``
 - ``cast``

CCHDO-Specific Metadata Record Fields
+++++++++++++++++++++++++++++++++++++++

The following fields extend the generic metadata records for CCHDO:

 - ``expocode``
 - ``cchdo_cruise_id``
 - ``woce_lines``

Implementation
++++++++++++++

Implementation of CCHDO's schema and pipelines to load the data from CCHDO can be found at the following links.

- Schema implementation and indexing: `https://github.com/argovis/db-schema/blob/main/cchdo.py <https://github.com/argovis/db-schema/blob/main/cchdo.py>`_
- Upload pipeline: original from CCHDO: `https://github.com/cchdo/argovis_convert_netcdf_to_json <https://github.com/cchdo/argovis_convert_netcdf_to_json>`_; also see fork and branch `https://github.com/BillMills/argovis_convert_netcdf_to_json/tree/2022Q3 <https://github.com/BillMills/argovis_convert_netcdf_to_json/tree/2022Q3>`_ for schema compliance and mongo upload.

Drifter Schema Extension
------------------------

Argovis indexes a subset of the hourly dataset from the `NOAA Global Drifter Program <https://www.aoml.noaa.gov/phod/gdp/index.php>`_, version 2.00 (beta pre-release) (`Elipot et al. 2016 <http://dx.doi.org/10.1002/2016JC011716>`_, `Elipot et al. 2022 arXiv preprint <https://arxiv.org/abs/2201.08289v1>`_). See `https://github.com/argovis/drifter-sync <https://github.com/argovis/drifter-sync>`_ for data parsing and loading.

Global Drifter Program data and metadata collections extend and implement the generic schema as follows.

Generic Metadata Division
+++++++++++++++++++++++++

Global Drifter Program measurements place all metadata fields in their metadata records; drifter data records correspond exactly to generic data records, while metadata records are per platform.

``_id`` construction
++++++++++++++++++++

 - Data records ``_id``: ``<platform>_<measurement_index>``
 - Metadata records ``_id``: ``<platform>``.

Drifter-Specific Data Record Fields
+++++++++++++++++++++++++++++++++++

The drifter collectoin treats ``timestamp`` and ``basin`` all as required items on the data document.

Otherwise, drifter data records are exactly the generic data record specification.

Drifter-Specific Metadata Record Fields
+++++++++++++++++++++++++++++++++++++++

- ``rowsize``

  - **required:** true
  - **type:** int
  - **description:** number of obs for this trajectory

- ``WMO``

  - **required:** true
  - **type:** string
  - **description:**  World Meteorological Organization buoy identification number

- ``expno``

  - **required:** true
  - **type:** int
  - **description:** experiment number 

- ``deploy_date``

  - **required:** true
  - **type:** ISO 8601 UTC datestring
  - **description:** Deployment date and time

- ``deploy_lon``

  - **required:** true
  - **type:** float
  - **description:** Deployment longitude 

- ``deploy_lat``

  - **required:** true
  - **type:** float 
  - **description:** Deployment latitude 

- ``end_date``

  - **required:** true
  - **type:** ISO 8601 UTC datestring
  - **description:**  End date and time

- ``end_lon``

  - **required:** true
  - **type:** float 
  - **description:** End longitude 

- ``end_lat``

  - **required:** true
  - **type:** float
  - **description:** End longitude 

- ``drogue_lost_date``

  - **required:** true
  - **type:** ISO 8601 UTC datestring
  - **description:** Date of drogue loss (Null=drogue still attached; "1970-01-01T00:00:00Z"=drogue status uncertain from beginning)

- ``typedeath``

  - **required:** true
  - **type:** int
  - **description:** Type of death (0=buoy still alive, 1=buoy ran aground, 2=picked up by vessel, 3=stop transmitting, 4=sporadic transmissions, 5=bad batteries, 6=inactive status) 

- ``typebuoy``

  - **required:** true
  - **type:** string
  - **description:** 'Buoy type (see https://www.aoml.noaa.gov/phod/dac/dirall.html)'


Implementation
++++++++++++++

- Schema implementation and indexing: `https://github.com/argovis/db-schema/blob/main/drifters.py <https://github.com/argovis/db-schema/blob/main/drifters.py>`_
- Upload pipeline: `https://github.com/argovis/drifter-sync <https://github.com/argovis/drifter-sync>`_

Tropical Cyclone Schema Extension
---------------------------------

HURDAT and JTWC tropical cyclone data is indexed by Argovis; TC data and metadata collections extend and implement the generic schema as follows.

Generic Metadata Division
+++++++++++++++++++++++++

Tropical cyclone records place all generic metadata fields in their metadata records.

``_id`` construction
++++++++++++++++++++

 - Data records ``_id``: ``<TCID>_<YYYY><MM><DD><HH><MM><SS>``, where ``<TCID>`` is the ID of the cyclone measurement from the upstream data source.
 - Metadata records ``_id``: ``<TCID>``

TC-Specific Data Record Fields
++++++++++++++++++++++++++++++

Tropical cyclones treat ``timestamp`` and ``basin`` all as required items on the data document. Specific data record fields are as follows:

 - ``class``
 - ``record_identifier``

TC-Specific Metadata Record Fields
++++++++++++++++++++++++++++++++++

 - ``name``
 - ``num``

Implementation
++++++++++++++

Implementation of tropical cyclone schema and pipelines to load the data from source CSVs can be found at the following links.

- Schema implementation and indexing: `https://github.com/argovis/db-schema/blob/main/tc.py <https://github.com/argovis/db-schema/blob/main/tc.py>`_
- Upload pipeline: `https://github.com/argovis/tc-sync <https://github.com/argovis/tc-sync>`_

Gridded Product Schema Extension
--------------------------------

Argovis includes the total temperature and salinity grids from `Roemmich-Gilson <https://sio-argo.ucsd.edu/RG_Climatology.html>`_, the ocean heat content grid described at `https://zenodo.org/record/6131625 <https://zenodo.org/record/6131625>`_, and the `GLODAP v2.2016b mapped data product <https://glodap.info/index.php/mapped-data-product/>`_. These gridded product data and metadata collections extend, implement and modify the generic schema as follows (see below for other, bespoke grids).

Generic Metadata Division
+++++++++++++++++++++++++

Gridded products place ``data_type``, ``date_updated_argovis``, ``data_info``, and ``source`` in their metadata documents.

``_id`` construction
++++++++++++++++++++

 - Data records ``_id``: ``<yyyymmddhhmmss>_<longitude>_<latitude>``
 - Metadata records ``_id``: 

   - For RG: ``rg09_<temperature | salinity>_<yyymm of originating file>_Total``
   - For KG: ``kg21_ohc15to300``
   - For GLODAP: ``glodapv2.2016b``

Grid-Specific Data Record Fields
++++++++++++++++++++++++++++++++

Gridded data does not define any new data record fields. Do note however that gridded data documents often contain more than one key in their ``metadata`` field. As noted above, these correspond in order to the different grids listed in ``data``.


Grid-Specific Metadata Record Fields
++++++++++++++++++++++++++++++++++++

- ``levels``

  - **required:** true
  - **type:** array of floats
  - **description:** Pressure or depth levels corresponding to each list of measurements in ``data``. Note the same spectrum of levels applies to all measurements in ``data``, as grids are required to have the same level spectrum in order to share a data document. 

- ``level_units``

  - **required:** true
  - **type:** string
  - **description:** units associated with the values in the ``levels`` array, typically dbar or m.

- ``lattice``

  - **required:** true
  - **type:** object
  - **description:** describes the shape and extent of the longitude / latitude grid data has been interpolated to. All subfields are required.

- ``lattice.center``

  - **type:** array of two floats
  - **description:** [longitude, latitude] of a point on the grid close to [0,0].

- ``lattice.spacing``

  - **type:** array of two floats
  - **description:** [longitude stride, latitude stride] between points on the grid

- ``[min / max](Lon / Lat)``

  - **type:** float
  - **description:** [minimum / maximum] (longitude / latitude) seen in the dataset 

- ``snr`` (GLODAP only)

  - **required:** false
  - **type:** JSON object keyed by GLODAP variable
  - **description:** Signal to noise ratio reported for this variable.

- ``cl`` (GLODAP only)

  - **required:** false
  - **type:** JSON object keyed by GLODAP variable
  - **description:** Correlation length, units of degrees north. Comment from the GLODAP upstream data: "Note that the [sic]correlation length is scaled to be 2x this number in the zonal direction, in order to account for the typically stronger flow zonally than meridionally in the world oceans."

Implementation
++++++++++++++

- Schema implementation and indexing: `https://github.com/argovis/db-schema/blob/main/grids.py <https://github.com/argovis/db-schema/blob/main/grids.py>`_
- Upload pipeline: `https://github.com/argovis/grid-sync <https://github.com/argovis/grid-sync>`_

Easy Ocean Gridded Schema Extension
-----------------------------------

The Easy Ocean grid is indexed by Argovis; Easy Ocean data and metadata collections extend and implement the generic schema as follows.

Generic Metadata Division
+++++++++++++++++++++++++

Easy Ocean places all generic metadata on the data document, save ``date_updated_argovis``, and ``country``, which is replaced by ``section_countries`` on the data document.

``_id`` construction
++++++++++++++++++++

 - Data records ``_id``: ``woce_<WOCE_line>_date_<YYYYMMDD>_lat_<lat>_lon_<lon>``, where decimals in lat and lon are hyphenated, ie 54.3 is written as 54-3 in the id.
 - Metadata records ``_id``: ``<WOCE line>``

Easy Ocean-Specific Data Record Fields
++++++++++++++++++++++++++++++++++++++

- ``section_expocodes``

  - **required:** false
  - **type:** array of strings
  - **description:** Expocodes of contributing sections.

- ``section_start_date``

  - **required:** false
  - **type:** ISO 8601 UTC datestring
  - **description:** date this section began

- ``section_end_date``

  - **required:** false
  - **type:** ISO 8601 UTC datestring
  - **description:** date this section concluded

- ``woce_lines``

  - **required:** false
  - **type:** array of strings
  - **description:** WOCE lines present

- ``references``

  - **required:** false
  - **type:** string
  - **description:** reference for this data

- ``dataset_created``

  - **required:** false
  - **type:** ISO 8601 UTC datestring
  - **description:**

- ``section_countries``

  - **required:** false
  - **type:** array of strings
  - **description:** country codes for contributing countries

- ``positioning_system``

  - **required:** false
  - **type:** string
  - **description:** positioning system used for this section

Easy Ocean-Specific Metadata Record Fields
++++++++++++++++++++++++++++++++++++++++++

- ``occupancies``

  - **required:** true
  - **type:** array of objects
  - **description:** array of data objects describing each occupancy of the WOCE line.

- ``occupancies[x].varying_direction``

  - **required:** true
  - **type:** string
  - **description:** which direction, lat or lon, is varying in this Easy Ocean entry

- ``occupancies[x].static_direction``

  - **required:** true
  - **type:** string
  - **description:** which direction, lat or lon, is interpolated to constant in this Easy Ocean entry

- ``occupancies[x].expocodes``

  - **required:** true
  - **type:** array of strings
  - **description:** expocodes for this occupancy

- ``occupancies[x].time_boundaries``

  - **required:** true
  - **type:** array of two ISO 8601 UTC datestrings
  - **description:** start and end times for this occupancy.

Implementation
++++++++++++++

Implementation of Easy Ocean schema and pipelines to load the data from source CSVs can be found at the following links.

- Schema implementation and indexing: `https://github.com/argovis/db-schema/blob/main/easyocean.py <https://github.com/argovis/db-schema/blob/main/easyocean.py>`_
- Upload pipeline: `https://github.com/argovis/convert_easy_ocean <https://github.com/argovis/convert_easy_ocean>`_


ARGONE Argo float forecast data
-------------------------------

Argovis includes a tabulation of forecasts of Argo float locations based on ARGONE (link / DOI forthcoming).

Generic Metadata Division
+++++++++++++++++++++++++

``data_type``, ``data_info``, ``date_updated_argovis``, and ``source`` all live on the argone metadata document.

``_id`` construction
++++++++++++++++++++

 - Data records: ``<origin_lon>_<origin_lat>_<forecast_lon>_<forecast_lat>``
 - Metadata records: there is only one for the entire dataset, ``argone``.

ARGONE-specific data record fields
++++++++++++++++++++++++++++++++++

 - ``geolocation_forecast``

  - **required:** true
  - **type:** geojson Point 
  - **description:** forecast location for this record

ARGONE-specific metadata record fields
++++++++++++++++++++++++++++++++++++++

- ``levels``

  - **required:** true
  - **type:** array of floats
  - **description:** a single entry, ``[0]``, indicating this is all surface data

Also note ``data_info[0]`` for ARGONE data indicates forecast length in days; the first entry indicates the probability a float will move from ``geolocation`` to ``geolocation_forecast`` in 90 days, for example.

Implementation
++++++++++++++

- Schema implementation and indexing: `https://github.com/argovis/db-schema/blob/main/argone.py <https://github.com/argovis/db-schema/blob/main/argone.py>`_
- Upload pipeline: `https://github.com/argovis/ARGONE <https://github.com/argovis/ARGONE>`_

Argo trajectory data
--------------------

Argovis includes estimates of Argo float trajectories from `https://doi.org/10.6075/J0FQ9WS6 <https://doi.org/10.6075/J0FQ9WS6>`_.

Generic Metadata Division
+++++++++++++++++++++++++

``data_type``, ``data_info``, ``date_updated_argovis``, and ``source`` all live on the trajectories metadata documents.

``_id`` construction
++++++++++++++++++++

 - Data records: ``<platform>_<cycle_number>``
 - Metadata records: ``<platform>_m<metadata_number>``, analogos to Argo metadata

Argo trajectory-specific data record fields
+++++++++++++++++++++++++++++++++++++++++++

- ``cycle_number``

  - **required:** true
  - **type:** int
  - **description:** probe cycle index

The following ``geolocation_*`` and ``timestamp_*`` data fields are all required; all geolocations have type geojson Point, and all timestamps have type datetime.

- ``geolocation_descending``
- ``timestamp_descending``
- ``geolocation_ascending``
- ``timestamp_ascending``
- ``geolocation_descending_transmitted``
- ``timestamp_descending_transmitted``
- ``geolocation_ascending_transmitted``
- ``timestamp_ascending_transmitted``
- ``geolocation_midpoint_transmitted``
- ``timestamp_midpoint_transmitted``

Note that Argovis' ``geolocation`` corresponds to the original files' ``LONGITUDE_`` and ``LATITUDE_MIDPOINT``, and ``timestamp`` corresponds to the upstream ``JULD_MIDPOINT``.

Argo trajectory-specific metadata record fields
+++++++++++++++++++++++++++++++++++++++++++++++

- ``platform``
- ``positioning_system_flag``
- ``sensor_type_flag``
- ``mission_flag``
- ``extrapolation_flag``
- ``positioning_system``
- ``platform_type``

Implementation
++++++++++++++

- Schema implementation and indexing: `https://github.com/argovis/db-schema/blob/main/trajectories.py <https://github.com/argovis/db-schema/blob/main/trajectories.py>`_
- Upload pipeline: `https://github.com/argovis/argo_trajectories <https://github.com/argovis/argo_trajectories>`_

Generic Timeseries Schema
-------------------------

The generic point schema described above and its specific instances works well for data that can be feasilby captured as documents with unique latitude, longitude, and timestamps. However, when considering higher-resolution datasets, indexing independent documents for each such coordinate triple can dramatically exceed the scale of computing resources the point data above requires; for example, while Argo has roughly 3 million such documents to consider at the time of writing, a global, quarter-degree grid measured daily for 30 years (a typical scale for satellite products) would have on the order of *10 billion* such documents. In order to represent, index and serve such high-resolution grids on similar compute infrastructure to the point data, we make a minor modification to the generic point schema to form the *generic timeseries schema*:

 - Vectors in the ``data`` object represent surface measurements, estimates or flags as an ordered timeseries.
 - The ``data`` document no longer has a single ``timestamp`` key, as the data within corresponds to many timestamps.
 - The ``metadata`` or ``data`` document must bear a ``timeseries`` key, which is an ordered list of timestamps corresponding to the times associated with each element in the ``data`` vectors.

The observant reader will notice that this is very similar to the gridded products which have a ``levels`` key indicating the model depths for each entry in their ``data`` vectors. All timeseries metadata documents also include a ``lattice`` key that is interepreted identically to the lattice metadata for gridded products. All other aspects of the generic schema remain consistent between point and timeseries datasets.

NOAA sea surface temperature timeseries
---------------------------------------

Argovis represents the satellite grid of sea surface temperatures from `https://psl.noaa.gov/data/gridded/data.noaa.oisst.v2.html <https://psl.noaa.gov/data/gridded/data.noaa.oisst.v2.html>`_ as a timeseries dataset.

Generic Metadata Division
+++++++++++++++++++++++++

``data_type``, ``data_info``, ``date_updated_argovis``, ``source`` and ``timeseries`` all live on the SST metadata documents.

``_id`` construction
++++++++++++++++++++

 - Data records: ``<longitude>_<latitude>``
 - Metadata records: ``noaa-oi-sst-v2`` is the sole metadata document for this collection.

NOAA sst-specific data record fields
++++++++++++++++++++++++++++++++++++

None.

NOAA sst-specific metadata record fields
++++++++++++++++++++++++++++++++++++++++

None.

Implementation
++++++++++++++

- Schema: `https://github.com/argovis/db-schema/blob/main/timeseries.py <https://github.com/argovis/db-schema/blob/main/timeseries.py>`_
- Upload pipeline: `https://github.com/argovis/noaa-sst <https://github.com/argovis/noaa-sst>`_

Copernicus sea level anomaly timeseries
---------------------------------------

Argovis represents the satellite grid of sea level anomaly from `https://cds.climate.copernicus.eu/cdsapp#!/dataset/satellite-sea-level-global <https://cds.climate.copernicus.eu/cdsapp#!/dataset/satellite-sea-level-global>`_ as a timeseries dataset. Note this data is averaged down to weekly averages from the daily dataset; averaging periods are selected to align with the NOAA SST timeseries.

Generic Metadata Division
+++++++++++++++++++++++++

``data_type``, ``data_info``, ``date_updated_argovis``, ``source`` and ``timeseries`` all live on the SLA metadata documents.

``_id`` construction
++++++++++++++++++++

 - Data records: ``<longitude>_<latitude>``
 - Metadata records: ``copernicusSLA`` is the sole metadata document for this collection.

Copernicus sla-specific data record fields
++++++++++++++++++++++++++++++++++++++++++

None.

Copernicus sla-specific metadata record fields
++++++++++++++++++++++++++++++++++++++++++++++

None.

Implementation
++++++++++++++

- Schema: `https://github.com/argovis/db-schema/blob/main/timeseries.py <https://github.com/argovis/db-schema/blob/main/timeseries.py>`_
- Upload pipeline: `https://github.com/argovis/copernicus-ssh <https://github.com/argovis/copernicus-ssh>`_

REMSS CCMP wind vector timeseries
---------------------------------

Argovis represents the satellite grid of wind vector data from `https://www.remss.com/measurements/ccmp/ <https://www.remss.com/measurements/ccmp/>`_ as a timeseries dataset. Note this data is averaged down to weekly averages from the 6-hourly dataset; averaging periods are selected to align with the NOAA SST timeseries.

Generic Metadata Division
+++++++++++++++++++++++++

``data_type``, ``data_info``, ``date_updated_argovis``, ``source`` and ``timeseries`` all live on the CCMP wind metadata documents.

``_id`` construction
++++++++++++++++++++

 - Data records: ``<longitude>_<latitude>``
 - Metadata records: ``ccmpwind`` is the sole metadata document for this collection.

CCMP wind-specific data record fields
+++++++++++++++++++++++++++++++++++++

None.

CCMP wind-specific metadata record fields
+++++++++++++++++++++++++++++++++++++++++

None.

Implementation
++++++++++++++

- Schema: `https://github.com/argovis/db-schema/blob/main/timeseries.py <https://github.com/argovis/db-schema/blob/main/timeseries.py>`_
- Upload pipeline: `https://github.com/argovis/ccmp_parse <https://github.com/argovis/ccmp_parse>`_

Generic Extended Objects Schema
-------------------------------

The generic point schema described above and its specific instances works well for data localized to a specific latitude and longitude as well as timestamp. However, when considering phenomena with large spatial extent like weather events, a point-based schema can't on its own capture these regions. In order to represent, index and serve data with large phenomenological extent, we make a minor modification to the generic point schema to form the *generic extended objects schema*:

 - ``geolocation`` in the ``data`` documents is a geoJSON MultiPolygon object that represents the boundaries of the phenomenon, rather than a single geoJSON Point object.
 - ``basin`` is replaced with ``basins``, defined similarly but as a list of such tags, in order to accommodate objects that extend to more than one ocean basin.

 Note that the ``data`` key in the ``data`` documents for extended objects works exactly the same as it does for other datasets, but will always include longitude and latitude measurements; these values and the measurement values associated by index with them from the other data vectors capture localized data in the interior of the phenomenological boundary, such as integrated water vapor transport at specific locations inside an atmospheric river.

Atmospheric river extended objects
----------------------------------

Argovis represents the atmospheric river (AR) climatology presented in `https://doi.org/10.1175/MWR-D-13-00168.1 <https://doi.org/10.1175/MWR-D-13-00168.1>`_ as an extended object dataset.

Generic Metadata Division
+++++++++++++++++++++++++

``data_type``, ``data_info``, ``date_updated_argovis`` and ``source``  all live on the AR metadata documents.

``_id`` construction
++++++++++++++++++++

 - Data records: ``<YYYY><MM><DD><decimal hour>_<index of phenomenon at this timestep>``
 - Metadata records: ``ar`` is the sole metadata document for this collection.

AR-specific data record fields
++++++++++++++++++++++++++++++

- ``flags``

  - **required:** false
  - **type:** array of strings
  - **description:** flags of possible pathologies from phenomenological boundaty construction
  - **current vocabulary:**
  
    - ``annulus``: this shape wraps around the entire globe.
    - ``dateline``: this shape crosses the dateline.
    - ``holes``: this shape has interior holes.
    - ``north_pole`` and ``south_pole``: this shape covers the respective pole.
    - ``noise_added``: in rare cases, a MultiPolygon will fail to index in mongodb due to the database bug `https://jira.mongodb.org/browse/SERVER-52928 <https://jira.mongodb.org/browse/SERVER-52928>`_. In this case, the shape is randomly shifted by much less than the resolution of the original climatology.
    - ``manually_corrected``: in cases of very large ARs, typically annular ARs wrapping the planet near the equator, it can be difficult to correctly define the interior of such a region in MongoDB. In these cases, we place an artificial 'seam' in the annulus that is much smaller than the resolution of the original grid and therefore won't affect geolocation searches, but which makes it easier to describe and index these phenomenological boundaries.

- ``true_geolocation``

  - **required:** false
  - **type:** geojson MultiPolygon
  - **description:** the phenomenological boundary automatically generated by the boundary detection algorithm in `https://github.com/argovis/argovis_helpers <https://github.com/argovis/argovis_helpers>`_; added when ``noise_added`` or ``manually_corrected`` flags are present to provide the unmodified geolocation.

AR-specific metadata record fields
++++++++++++++++++++++++++++++++++

- ``lattice``

  - **required:** true
  - **type:** object
  - **description:** describes the shape and extent of the longitude / latitude grid data has been interpolated to. All subfields are required.

- ``lattice.center``

  - **type:** array of two floats
  - **description:** [longitude, latitude] of a point on the grid close to [0,0].

- ``lattice.spacing``

  - **type:** array of two floats
  - **description:** [longitude stride, latitude stride] between points on the grid

- ``[min / max](Lon / Lat)``

  - **type:** float
  - **description:** [minimum / maximum] (longitude / latitude) seen in the dataset 

Implementation
++++++++++++++

- Schema: `https://github.com/argovis/db-schema/blob/main/extended.py <https://github.com/argovis/db-schema/blob/main/extended.py>`_
- Upload pipeline: `https://github.com/argovis/arShapes <https://github.com/argovis/arShapes>`_

*Last reviewed 2024-04-11*