Profiles API Alpha Product
==========================

An alpha demo of new ``/profiles``, ``/platforms`` and ``/dacs`` endpoints are available as part of our `goship demo <http://143.198.150.42:8080/profiles?startDate=2021-05-01T00:00:00Z&endDate=2021-05-02T00:00:00Z>`_.

Project Goals
-------------

 - We hope to design and build an API that is intuitive for users and easy to maintain for the Argovis team. Currently, many ``/catalog`` and ``/selection`` API endpoints return very similar profile-like data, with differences that aren't always obvious from the route names. An API design pattern intended to keep APIs organized and easy to understand is a *noun-based route pattern*:

   - Routes should be named after things (nouns) that are easily recognizable to the intended users of the API (profiles, platforms and dacs, for example).
   - Requests should always return objects that are consistent with a schema that matches the corresponding route; all ``/profiles`` requests should return schema-compliant profile documents, for example.
   - Filtering should be done consistently in the query string, not the route.
 - Looking to the future, we hope to offer an API tier that spans all profile-like data, whether it comes from Argo, go-ship, or other endeavors.
 - The goal of this alpha demo is to gather feedback on design decisions as development continues.

Usage
-----

Unless otherwise noted, all routes support only ``GET`` requests at this time.

.. admonition:: Longitudes and Latitudes

   For all queries on all endpoints, where longitudes and latitudes are supported, they must fall on [-180,180] and [-90,90], respectively.

/profiles
+++++++++

The base ``/profiles`` endpoint is the place to go for all profile data. Reducing the amount of data returned can be achieved with the following query string parameters; using multiple query string parameters ``AND`` s the corresponding requirements. All parameters are optional, but see the note below about limiting response sizes.

 - ``startDate``: formatted as ISO 8601 UTC: ``1999-12-31T23:59:59Z``. Profiles will be returned if they are timestamped at or after this time.
 - ``endDate``: formatted as ISO 8601 UTC: ``1999-12-31T23:59:59Z``. Profiles will be returned if they are timestamped before this time.
 - ``polygon``: formatted as ``[[lon,lat],[lon,lat],[lon,lat]...]``; note the first and last ``[lon,lat]`` pairs must be identical. Profiles will be returned if they fall within the closed polygon created by connecting the coordinate pairs in the order they are serialized.
 - ``box``: formatted as ``[[lower left lon,lower left lat],[upper right lon,upper right lat]]``. Profiles will be returned if they fall within the box defined by its lower left and upper right coordinate corners.
 - ``center`` plus ``radius``, formatted as ``center lon, center lat`` and a distance in km, respectively. Profiles will be returned if they fall within the circle defined by this pair of parameters.
 - ``id``: formatted as ``id``. Return only the profile matching this unique ID.
 - ``platform``: formatted as ``platform``. Profiles will be returned if they come from the platform identified.
 - ``presRange``: formatted as ``minPres,maxPres``. Only levels with ``measurements.pres``  that fall within the range bracketed by ``minPres`` and ``maxPres`` will be returned.
 - ``dac``: formatted as a single string, like ``CCHDO``. Only profiles from the specified DAC will be returned.
 - ``data``: formatted as ``meas_1,meas_2,...``. Specifies the measurements and/or QC variables to be returned; valid choices are listed in the vocabulary at :ref:`argo_vocab`. In addition to these, specifying ``data=all`` will return all available data.
 - ``compression``: if set to any value, a minified ``data`` array will be returned: instead of a dictionary for each level, ``data`` will be a list of lists, where each inner list contains the values requested for a level, in the same order as the ``data_keys`` object on the corresponding returned profile.
 - ``woceline``: formatted as ``woce_line``. Profiles from the indicated GO-SHIP woce line will be returned.
 - ``datavars``: formatted as ``var_1,var_2,...``. Profiles will be returned if they have ALL the named variables in their ``data_keys`` array.

.. admonition:: Required Parameters and Response Sizes

   In order to constrain the amount of data returned in a single request, your query must return less than 1000 profiles. If it's too broad, you'll recieve an HTTP/400 error and should consider cutting scope to a specific region, date range, or other filter. Bear in mind that you can always make more requests to cover more cases!

.. admonition:: Data or Metadata?

   If your query string does not include ``data``, the request will return profile metadata only. If your query string includes either of those and a matching profile has no levels with the appropriate measurements after filtering, it will be dropped from the returned results.

There is also one subroute under ``/profiles``:

 - ``/profiles/listID``: takes the same query string as ``/profiles``, except ``id`` is not accepted as a query parameter (since it's not useful to search for IDs by ID). Furthermore, up to 10k profile IDs may be returned by this route.

/platforms
++++++++++

The ``/platforms`` route provides some simple summary data on platforms, filtered by the following query string parameters:

 - ``platform``: a single ``platform_id`` value. Returns metadata objects for the platform specified.


There are also two sub-routes under ``/platforms``, to capture some other, related schema:

 - ``/platforms/bgcList`` returns a list of platform IDs that collect BGC data.
 - ``/platforms/mostRecent`` returns a list of platforms including some information about their most recent location and measurements. Accepts the same ``platforms`` query string parameter as `/profiles` to restrict results to a set of platforms (returns all platforms by default).

/dacs
+++++

The ``/dacs`` route provides simple summary data on data assembly centers represented in the dataset. It currently accepts no query string parameters.

Examples
--------

/profiles
+++++++++

- Metadata for profiles for the month of May 2021:

.. code:: bash

   /profiles?startDate=2021-05-01T00:00:00Z&endDate=2021-06-01T00:00:00Z

- Metadata for profiles in May 2021 within a small region off the coast of New York:

.. code:: bash

   /profiles?startDate=2021-05-01T00:00:00Z&endDate=2021-06-01T00:00:00Z&polygon=[[-71.499,38.805],[-68.071,38.719],[-69.807,41.541],[-71.499,38.805]]

- All data for profiles in May 2021 within a small region off the coat of New York:

.. code:: bash

   /profiles?startDate=2021-05-01T00:00:00Z&endDate=2021-06-01T00:00:00Z&polygon=[[-71.499,38.805],[-68.071,38.719],[-69.807,41.541],[-71.499,38.805]]&data=all

- Metadata, pressure and salinity profile data for profiles in May 2021 within a small region off the coat of New York:

.. code:: bash

   /profiles?startDate=2021-05-01T00:00:00Z&endDate=2021-06-01T00:00:00Z&polygon=[[-71.499,38.805],[-68.071,38.719],[-69.807,41.541],[-71.499,38.805]]&data=psal,pres

- Metadata, pressure and salinity profile data for profiles in May 2021 within a small region off the coat of New York to a maxium pressure of 1000 dbar:

.. code:: bash

   /profiles?startDate=2021-05-01T00:00:00Z&endDate=2021-06-01T00:00:00Z&polygon=[[-71.499,38.805],[-68.071,38.719],[-69.807,41.541],[-71.499,38.805]]&data=pres,psal&presRange=0,1000

- Get a list of IDs for profiles containing GO-SHIP dissolved oxygen key ``doxy_btl`` within a certain time range:

.. code:: bash

   /profiles/listID?startDate=2021-05-01T00:00:00Z&endDate=2021-06-01T00:00:00Z&data=doxy_btl

/platforms
++++++++++

- Metadata for platform ID 325020210.42:

.. code:: bash

   /platforms?platform=325020210.42

- Get list of all platforms with BGC data:

.. code:: bash

   /platforms/bgcList

- Get list of all platforms with recent whereabouts:

.. code:: bash

   /platforms/mostRecent

/dacs
+++++

- Currently only a single route with no query string: return a summary of data reported for each DAC represented in the database:

.. code:: bash

   /dacs

Mapping to old endpoints
------------------------

In the tables below, we present the closest equivalents between old and new API endpoints. Note that not all equivalencies are exact! See the Comments column for differences and important notes.

``/catalog`` endpoints
++++++++++++++++++++++

.. list-table:: /catalog to /profiles
   :widths: 25 25 25
   :header-rows: 1

   * - Old endpoint
     - New endpoint
     - Comment
   * - ``/catalog/platforms/<platform number>``
     - ``/profiles?platforms=<platform number>&data=all``
     -
   * - ``/catalog/bgc_platform_data/<platform number>``
     - ``/profiles?platforms=<platform number>&data=all``
     - 
   * - ``/catalog/platform_metadata/<platform number>``
     - ``/platforms?platform=<platform_number>``
     - 
   * - ``/catalog/bgc_platform_list``
     - ``/platforms/bgcList``
     - New API returns a simple list of platform numbers, rather than a list of objects containing platform number as their single key.
   * - ``/catalog/platform_profile_metadata/<platform number>``
     - ``/profiles?platforms=<platform number>``
     -
   * - ``/catalog/platforms``
     - ``/platforms/mostRecent``
     - 
   * - ``/catalog/profiles/<profile id>``
     - ``/profiles?ids=<profile ID>&data=all``
     - 
   * - ``/catalog/mprofiles?ids=["<profile ID 1>","<profile ID 2>,..."]``
     - ``/profiles?ids=<profile ID 1>,<profile ID 2>,...&data=all``
     - New endpoint includes complete metadata record, but does not compute ``containsBGC`` or the level ``count`` (which can be trivially inferred from the length of the ``measurements`` list).
   * - ``/catalog/dacs/<dac>``
     - 
     - Not implemented or clearly specified in old API; can add to the new ``/dacs`` group once specified.
   * - ``/catalog/dacs``
     - ``/dacs``
     - 

``/selection`` endpoints
++++++++++++++++++++++++

.. list-table:: /selection to /profiles
   :widths: 25 25 25
   :header-rows: 1

   * - Old endpoint
     - New endpoint
     - Comment
   * - ``/selection?ids=["<profile ID 1>","<profile ID 2>,..."]``
     - ``/profiles?ids=<profile ID 1>,<profile ID 2>,...&data=all``
     - New endpoint includes complete metadata record, but does not compute ``containsBGC`` or the level ``count`` (which can be trivially inferred from the length of the ``measurements`` list).
   * - ``/selection/profiles?startDate=<date>&endDate=<date>&shape=[[[lon1,lat1],[lon2,lat2],...,[lon1,lat1]]]``
     - ``/profiles?startDate=<date>&endDate=<date>&polygon=[[lon1,lat1],[lon2,lat2],...,[lon1,lat1]]&data=all``
     - 
   * - ``/selection/box/profiles?startDate=<date>&endDate=<date>&llCorner=[lon1,lat1]&urCorner=[lon2,lat2]``
     - ``/profiles?startDate=<date>&endDate=<date>&box=[[lon1,lat1],[lon2,lat2]]&data=all``
     - 
   * - ``/selection/profiles/<month>/<year>``
     - ``/profiles?startDate=<First of the month>&endDate=<First of the next month>``
     -
   * - ``/selection/globalMapProfiles/<start date>/<end date>``
     - [Maybe deprecate? See comments.]
     - Original intention unclear; just subsets some profile metadata within a time window. If so, no need for this endpoint in addition to ``/profiles``.
   * - ``/selection/lastThreeDays``
     - [Deprecated]
     - Will not be implemented; functionality is reproduced by specifiying the desired dates in ``/selection/globalMapProfiles/<start date>/<end date>``.
   * - ``/selecton/bgc_data_selection?startDate=<date>&endDate=<date>&shape=[[[lon1,lat1],[lon2,lat2],...,[lon1,lat1]]]&meas_1=<bgc1>&meas_2=<bgc2>``
     - ``/profiles?startDate=<date>&endDate=<date>&polygon=[[lon1,lat1],[lon2,lat2],...,[lon1,lat1]]&data=<bgc1>,<bgc2>``
     - New endpoint includes complete metadata record.
   * - ``/selection/overview``
     - ``/profiles/overview``
     - 

Index Requirements
------------------

These endpoints require the following indexes be maintained over any collection of profiles:

 - ``date`` by decending order: ``/platforms`` extracts metadata from the most recent record for a given platform, and therefore requires date sorting; this breaks on the production database of 2M+ profiles, presumably beacuse it lacks the appropriate index.
 - ``geoLocation`` by ``2dsphere``: all requests for points within a region require this index.

The following indexes are strong nice-to-haves since they are valid search filters:

 - ``_id`` by ascending (exists by default, no extra overhead)
 - ``platform_number`` by ascending
 - ``containsBGC`` by ascending

For quick reference, I created these indexes over the goship profiles in the mongo shell with:

.. code:: bash

   db.profiles.createIndex( { date: -1 } )
   db.profiles.createIndex( { geoLocation: "2dsphere" } )
   db.profiles.createIndex( { platform_number: 1 } )
   db.profiles.createIndex( { containsBGC: 1 } )

Outstanding Issues
------------------

This is far from a finished product! Feedback is encouraged, much more development is fothcoming. Below are some major categories of concerns identified so far.

Key Standardization
+++++++++++++++++++

Argo and goship data have similar but not identical names for some keys. Ideally, we would have a hierarchical schema for profile data:

 - *Common Mandatory Parameters* are parameters that every profile from every source must have. Examples are ``lat`` and ``lon``.
 - *Common Optional Parameters* are parameters that may or may not be included in a profile, but should have consistent naming and meaning across sources. An example is ``data``.
 - *Origin-specific Parameters* are parameters unique to a data origin, like Argo or go-ship.

Some critical examples of keys that are not consistently named or present between the Argo and go-ship data on-hand are ``bgcMeasKeys``, ``containsBGC`` and ``isDeep``; these are univeraly applicable ideas which we may likely need to index on, and so should be common to all profile schema.

Sorting
+++++++

The new API endpoints do not consider sort order in arrays they return, unless otherwise noted above; sorting can be added to any endpoint, but only when the overhead of index maintenance is justified on a case-by-case basis.

*Last reviewed --*