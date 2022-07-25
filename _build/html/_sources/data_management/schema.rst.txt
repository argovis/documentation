.. _schema:

Argovis data schema
===================
All data indexed by Argovis follows the schema described in this document. The purpose of this schema is to standardize the representation of profile-, grid-,and sea surface-type datasets to promote their interoperability and underwrite a standardized API to serve them all.

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

- **required:** whether or not this attribute can be omitted
- **type:** the primitive type,  format,  or object description of a valid entry for this field
- **description:** short comment on what this variable is
- **fill value** (optional): what this should be filled by if absent
- **current vocabulary** (optional): current set of possible values for this key,  with explanations as required.

Schema enforcement & population
+++++++++++++++++++++++++++++++

Argovis uses Mongodb as its backend. All datasets have their data and metadata schema defined in `https://github.com/argovis/db-schema <https://github.com/argovis/db-schema>`_, which includes enforcement of these schema when uploaded to mongodb; therefore, the schema implementation in that code should be considered the most reliable document of our schema.

Generic Schema
--------------

As noted above, generic schema form the basis of all schema in Argovis; this section describes the minimum viable information needed to populate these schema. Subsequent sections describe how specific datasets extend and implement these core definitions.

Generic Data Schema
+++++++++++++++++++

In general, data records are intended to represent data that is unique or frequently changing per longitude / latitude / timestamp triple, in order to support efficient temporospatial indexing of these records in Mongodb. All data records contain the following fields:


- ``_id``

  - **required:** true
  - **type:** string
  - **description:** unique record identifier that encodes something meaningful, such as measurement order per platform.

- ``metadata``

  - **required:** true
  - **type:** string
  - **description:** foreign key that matches the ``_id`` of the corresponding metadata record. Preferentially chosen to encode something physically meaningful that corresponds to metadata groupings, like Argo platform ID.

- ``geolocation``

  - **required:** true
  - **type:** geojson Point object
  - **description:** geojson Point tagging the lon/lat of this record.
  - **fill value:** ``{"type": "Point",  "coordinates": [0,  -90]}``

- ``basin``

  - **required:** true
  - **type:** int
  - **description:** integer index of basin.
  - **fill value:** -1,  used if reported lon/lat are on land.

- ``timestamp``

  - **required:** true
  - **type:** ISO 8601 UTC datestring,  example ``1999-12-31T23:59:59Z``
  - **description:** time the record measurement was made at.
  - **fill_value:** ``9999-01-01T00:00:00Z``

- ``data``

  - **required:** false
  - **type:** optional array of non-nested JSON documents, OR optional array of arrays of floats
  - **description:** in both formats, array indexes depth / altitude; array elements present the measurement values for that level, either as a dictionary with keys that match ``data_keys``, or as an array of floats in the same order as ``data_keys``.
  - **current vocabulary:** measurements defined per dataset; see dataset-specific extensions below.

Generic Metadata Schema
+++++++++++++++++++++++

In general, metadata records in Argovis are meant to factor out constant or infrequently-changing data from the data records. They only have one required field:

- ``_id``

  - **required:** true
  - **type:** string
  - **description:** unique record identifier referred to by the ``metadata`` field in records from the corresponding data collection.

Besides the trivially required ``_id`` field, there are a set of generic metadata fields, presented in this section, that may, if required or desired, appear in *exactly one* of the metadata or data schemas for a given dataset, depending on which choice provides the most efficient encoding for that dataset. Each dataset specified below includes the division of these fields between data and metadata.

- ``data_type``

  - **required:** true
  - **type:** string
  - **description:** token indicating the general class of data
  - **current vocabulary:** ``oceanicProfile``,  ``tropicalCyclone``, ``drifter``, ``grid``

- ``data_keys`` 

  - **required:** true
  - **type:** array of strings
  - **description:** a complete list of all the keys found in any element in the ``data`` object, ordered as the inner lists of ``data`` when ``data`` is presented as a list of lists of floats.

- ``units`` 

  - **required:** true
  - **type:** array of strings
  - **description:** strings describing the units of each measurement, in the same order as ``data_keys``.

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
  - **description:** data origin, typically used to label major project subdivisions like ``argo_core``, ``argo_bgc`` and ``argo_deep``

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
  - **description:** date and time the upstream source file for this record was last modified

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
  - **description:** name(s) of principle investigator(s)

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

The Argo data and metadata collections extend and implement the generic schema as follows.

Generic Metadata Division
+++++++++++++++++++++++++

Argo profiles divide the generic metadata fields between data and metadata records per the following. In general, Argo metadata records describe things that are consistent or slowly changing for a particular physical float, while a data record represents an individual profile.

 - Data records:

   - ``date_updated_argovis``
   - ``source``
   - ``data_warning``

 - Metadata records:

   - ``data_type``
   - ``data_keys``
   - ``units``
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

The following fields extend the generic data record for Argo:

- ``cycle_number``

  - **required:** true
  - **type:** int
  - **description:** probe cycle index

- ``data_keys_mode``

  - **required:** false
  - **type:** non-nested JSON document
  - **description:** JSON document with keys matching the entries of ``data_keys``,  and values indicating the variable's data mode
  - **current vocabulary:** ``R`` ealtime,  realtime ``A`` djusted,  or ``D`` elayed mode.

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

Implementation of Argo's schema and pipelines to load the data from IFREMER can be found at the following links.

 - Schema implementation and indexing: TBD
 - Upload pipeline: `https://github.com/argovis/ifremer-sync <https://github.com/argovis/ifremer-sync>`_

GO-SHIP Schema Extension
------------------------

The GO-SHIP data and metadata collections extend and implement the generic schema as follows.

Generic Metadata Division
+++++++++++++++++++++++++

GO-SHIP profiles divide the generic metadata fields between data and metadata records per the following. In general, GO-SHIP metadata records describe things that are consistent or slowly changing for a particular GO-SHIP cruise, while a data record represents a single profile.

 - Data records:

   - ``source``
   - ``data_warning``
   - ``data_keys``
   - ``units``

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

GO-SHIP-Specific Data Record Fields
+++++++++++++++++++++++++++++++++++

The following fields extend the generic data records for GO-SHIP:

 - ``station``
 - ``cast``

GO-SHIP-Specific Metadata Record Fields
+++++++++++++++++++++++++++++++++++++++

The following fields extend the generic metadata records for GO-SHIP:

 - ``expocode``
 - ``cchdo_cruise_id``
 - ``woce_lines``

Implementation
++++++++++++++

Implementation of GO-SHIP's schema and pipelines to load the data from CCHDO can be found at the following links.

 - Schema implementation and indexing: TBD
 - Upload pipeline: `https://github.com/cchdo/argovis_convert_netcdf_to_json <https://github.com/cchdo/argovis_convert_netcdf_to_json>`_

Drifter Schema Extension
------------------------

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

None. Drifter data records are exactly the generic data record specification.

Drifter-Specific Metadata Record Fields
+++++++++++++++++++++++++++++++++++++++

  - ``rowsize``
  - ``WMO``
  - ``expno``
  - ``deploy_date``
  - ``deploy_lon``
  - ``deploy_lat``
  - ``end_date``
  - ``end_lon``
  - ``end_lat``
  - ``drogue_lost_date``
  - ``typedeath``
  - ``typebuoy``
  - ``long_name``

Implementation
++++++++++++++

 - Schema implementation and indexing: `https://github.com/argovis/db-schema/blob/main/drifters.py <https://github.com/argovis/db-schema/blob/main/drifters.py>`_
 - Upload pipeline: `https://github.com/argovis/drifter-sync <https://github.com/argovis/drifter-sync>`_

Tropical Cyclone Schema Extension
---------------------------------

HURDAT and JTWC tropical cyclone data and metadata collections extend and implement the generic schema as follows.

Generic Metadata Division
+++++++++++++++++++++++++

Tropical cyclone records place all generic metadata fields in their metadata records.

``_id`` construction
++++++++++++++++++++

 - Data records ``_id``: ``<TCID>_<YYYY><MM><DD><HH><MM><SS>``, where ``<TCID>`` is the ID of the cyclone measurement from the upstream data source.
 - Metadata records ``_id``: ``<TCID>``

TC-Specific Data Record Fields
++++++++++++++++++++++++++++++

 - ``record_identifier``
 - ``class``

TC-Specific Metadata Record Fields
++++++++++++++++++++++++++++++++++

 - ``name``
 - ``num``

Implementation
++++++++++++++

Implementation of tropical cyclone schema and pipelines to load the data from source CSVs can be found at the following links.

 - Schema implementation and indexing: TBD
 - Upload pipeline: `https://github.com/argovis/tc-sync <https://github.com/argovis/tc-sync>`_

Gridded Product Schema Extension
--------------------------------

Gridded product data and metadata collections extend and implement the generic schema as follows.

Generic Metadata Division
+++++++++++++++++++++++++

Gridded products place all metadata fields in their metadata records; grid data records correspond exactly to generic data records, while metadata records are per grid product.

``_id`` construction
++++++++++++++++++++

 - Data records ``_id``: ``<yyyymmddhhmmss>_<longitude>_<latitude>``
 - Metadata records ``_id``: ``<grid name>``

Grid-Specific Data Record Fields
++++++++++++++++++++++++++++++++

None. Grid data records are exactly the generic data record specification.

Grid-Specific Metadata Record Fields
++++++++++++++++++++++++++++++++++++

 - ``levels``
 - ``lonrange``
 - ``latrange``
 - ``timerange``
 - ``loncell``
 - ``latcell``

.. admonition:: Shared grid metadata collection

   Unlike other data products which each get their own metadata collection, all gridded products share the same metadata collection, ``gridMeta``. This is because for a given gridded data product, there should be exactly one metadata record - it seems silly to make a collection for each.

Implementation
++++++++++++++

 - Schema implementation and indexing: TBD
 - Upload pipeline: TBD

*Last reviewed 2022-07-08*