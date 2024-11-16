.. _qsp:

API Query String Parameters
===========================

Argovis' core goal is to allow users to search, filter and download ocean data easily and incisively, in order to get exactly the data relevant to your porject as quickly as possible. To achieve this, we provide an API over all the datasets described in the :ref:`schema` section; use and function of the query string parameters (which describe what data you want to download and how you want to filter it) available for the core routes of this API are described in this document.

Standard routes
---------------

All the datasets described in the :ref:`schema` section have three principle routes for exploring them:

- **data**, for searching, filtering and downloading data documents
- **metadata**, for searching, filtering and downloading metadata documents
- **vocab**, for discovering the possible values of QSPs in the data and metadata routes.

In what follows, we will describe the querys string parameters (QSPs) available for each of these types of route, for each dataset.

Standardized query string parameters
------------------------------------

Wherever possible, our API defines QSPs consistently across datasets. The following QSPs are resused across many routes, and will be referred to in following sections:

.. admonition:: QSPs AND

   In all cases, searches that include more than one QSP AND the results of those filters together, meaning the documents returned must satisfy *all* the filters described.

Generic data QSPs
+++++++++++++++++

- ``id`` (string): make an exact match on the document's ``id`` field.
- ``startDate`` (ISO 8601 UTC datestring, example ``1999-12-31T23:59:59Z``): search for ``timestamp`` on or after this date, inclusive.
- ``endDate`` (ISO 8601 UTC datestring, example ``1999-12-31T23:59:59Z``): search for ``timestamp`` on or before this date, exclusive.
- ``polygon`` (list of coordinates ordered as [longitude, latitude] for a single-ring geoJSON polygon, example ``[[0,0],[0,1],[1,1],[0,0]]``): search for documents whose ``geolocation`` field is within this polygon, where the vertexes listed are joined by great circles.
- ``box`` ([[southwest longitude, latitude], [northeast longitude, latitude]]): search for documents whose ``geolocation`` field is within the described box, bounded by lines of constant latitude and longitude.
- ``center`` ([longitude, latitude], must be used in conjunction with ``radius``): search for documents whose ``geolocation`` field is is within the circle described by this center and radius.
- ``radius`` (float, must be used in conjunction with ``center``): search for documents whose ``geolocation`` field is within the circle described by this center and radius.
- ``metadata`` (string): search for documents whose ``metadata`` field contains this string.
- ``compression`` (string): return a minimal stub for each data document. Stub contents are specified per dataset, and typically contain just enough information to make maps of matching documents.
- ``verticalRange`` (list of floats, example ``0,1000``): filter for levels within data documents that fall in this vertical range, expressed in either dbar or meters, whichever the levels are measured by in that dataset. Upper bound is inclusive, lower bound is exclusive.
- ``batchMeta`` (string): if set, perform the search over data documents described by the other QSPs, but return the metadata documents that match those data documents instead. This is useful for getting metadata for a set of data documents without having to specify an explicit metadata search.
- ``data`` (list of strings and integers, example ``pressure,temperature,1,~salinity``): search for data documents that meet the following requirements and perform the following filtering:

  - Returns documents that have data for all variables listed.
  - If a ~ preceeds a variable name, throw out any document that does have data for that variable.
  - If a list of integers follows a variable name, these are the allowed values for that variable's corresponding QC flag, per level. That variable will be suppressed to null on any level where their QC doesn't fall in the list.
  - When data variables are listed, any level that contains no information for any of the listed variables will be suppressed from the results. Any data document that has no non-null information for any one of the listed data documents will be suppressed from the results.
  - If pressure is available in the dataset, it is always returned whether requested or not.

The purpose of this sophisticated data filtering is to allow you to demand data documents and vertical levels that definitely have the data you're interested in. Some examples:

- ``data=temperature,doxy``: return only data documents that have both temperature and dissolved oxygen data, only keep vertical levels that have a non null value for at least one of these, and keep only temperature, doxy, and pressure in the list of data variables returned.
- ``data=temperature,~salinity``: return only data documents that have temperature data but no salinity data, only keep vertical levels that have a non null value for temperature, and keep only temperature and pressure in the list of data variables returned.
- ``data=temperature,1,2``: return only data documents that have non-null temperature data after setting temperature to null for any level where the temperature QC flag is not 1 or 2, only keep vertical levels that have a non null value for temperature after this QC filtering, and keep only temperature and pressure in the list of data variables returned.
- ``data=doxy&verticalRange=0,100``: return only data documents that have non-null dissolved oxygen data between 0 and 100 dbar or meters, only keep vertical levels that have a non null value for doxy, and keep only doxy and pressure in the list of data variables returned.

In addition, there are two special cases for the ``data`` QSP:

- ``data=all``: keep all data variables available for matching documents. Accepts QC filters where available, so ``data=all,1`` would return all data variables for matching documents, but set to null any data value on a vertical level where its corresponding QC flag isn't 1.
- ``data=...,except-data-values``: perform the data filter as described by the rest of this QSP, but drop the ``data`` parameter from the returned data documents. For example, ``data=temperature,except-data-values`` would filter for documents that have temperature data, but doesn't actually download the data values. This is useful for quickly making maps or timeseries of where and when data documents are available that have data of interest, while minimizing the size of the download needed to complete this task.

Generic metadata QSPs
+++++++++++++++++++++

- ``id`` (string): make an exact match on the document's ``id`` field.

Generic vocab QSPs
++++++++++++++++++

- ``parameter`` (string): find the allowed values for this parameter in the data or metadata QSPs.

.. admonition:: Vocab enum

	All vocab routes support ``parameter=enum``, which is a special case that lists all the other variables which that vocabulary route can list the possible values of.

Argo QSPs
---------

The documents described in :ref:`schema_argo` are searchable via the following routes and QSPs.

Data
++++

Route: ``/argo``

QSPs:

- ``id``
- ``startDate``
- ``endDate``
- ``polygon``
- ``box``
- ``center``
- ``radius``
- ``metadata``
- ``compression``
- ``verticalRange``
- ``batchMeta``
- ``data``, accepts QC filters.
- ``platform`` (string): search for argo data documents whose corresponding metadata's ``platform`` field matches this string.
- ``platform_type`` (string): search for argo data documents whose corresponding metadata's ``platform_type`` field matches this string.
- ``positionqc`` (list of integers, example ``0,1``): match data documents whose ``geolocation_argoqc`` value is in this list.
- ``source`` (list of strings, example ``argo_bgc,~argo_core``): match data documents whose ``source.source`` value is in this list. Negatable with ~ similarly to ``data``. Must be combined with a temporospatial search or other metadata match. 

Metadata
++++++++

Route: ``/argo/meta``

QSPs:

- ``id``
- ``platform`` (string): search for argo metadata documents whose ``platform`` field matches this string.

Vocab
+++++

Route: ``/argo/vocabulary``

QSPs:

- ``parameter``. See ``parameter=enum`` for a list of all the parameters that can be enumerated with this QSP.

*Last reviewed 24-11-16*