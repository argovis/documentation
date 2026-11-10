.. _adding_new_data:

Adding a new dataset
====================

In order to add a new data product to Argovis, there are several planning and preparatory steps outlined in this document.

Schema development
------------------

Our first step is to plan an appropriate schema for the new data and metadata collections that will be populated by this new dataset. This schema *must* obey the standards outlined in :ref:`schema`, or otherwise must be marked experimental in the API (see :ref:`adding_new_routes`, later in the development cycle).

Some considerations at this stage:

 - Plan at least one consulting meeting with a subject matter expert on the dataset to discuss how this data is used. Explore topics like: 

   - what sort of questions do you commonly ask of this dataset?
   - what sort of problems or challenges have you had in the past with this dataset?
   - what sort of things would you like to search this dataset for?
   - how do you anticipate this dataset changing or growing in the future? 

   All these questions may give you ideas on how to organize the data in a way that is useful and familiar to its users, and future proof it for updates.
 - Where schema rules allow it, change variable names from upstream documents as little as possible to promote familiarity with people already using the upstream data.
 - Try to identify a physically meaningful way to divide information between data and metadata documents. For example, Argo metadata documents correspond to information about the float, while data documents each correspond to a single cycle. In general, metadata documents should factor out data that doesn't change often between temporospatial points, while data documents should capture information unique to a single temporospatial point.
 - At the database level, prioritize efficiency: choose arrays of floats rather than bloated dictionaries, for example. Helper functions can be provided to users downstream to help them interpret these documents, but at this level we want documents that are easy to store and fast to transmit.

Once a plan has been developed and reviewed by a data subject matter expert, add a schema definition script to `https://github.com/argovis/db-schema <https://github.com/argovis/db-schema>`_. Some considerations for this script:

 - Data and metadata collections are typically named ``x`` and ``xMeta``, respectively, where ``x`` is a short but meaningful label for the dataset, like ``argo`` or ``cchdo``. In the case of highly regular classes of data which have very few metadata records, like extended objects and timeseries, metadata documents may be lumped together in collections like ``timeseriesMeta`` and ``extendedMeta``.
 - You should have learned in consultation with subject matter experts how they plan on searching this data, which informs the indexes you'll want to specify in this step. Note that the indexes defined for the data collection in `https://github.com/argovis/db-schema/blob/main/tc.py <https://github.com/argovis/db-schema/blob/main/tc.py>`_ are mandatory for all data collections, but more can be added as needed on a case-by-case basis.

Once complete, run your script and ensure that you have appropriate empty collections with schema and indexes defined in MongoDB.

Database population
-------------------

At this point, it's time to start populating your new collections. `https://github.com/argovis/tc-sync <https://github.com/argovis/tc-sync>`_ provides a complete but relatively simple example of what you need to produce:

 - `https://github.com/argovis/tc-sync/blob/main/tcload.py <https://github.com/argovis/tc-sync/blob/main/tcload.py>`_ translates upstream data into JSON data and metadata documents, and pushes those to MongoDB. The schema enforcement rules you defined above should guarantee that no malformed documents are pushed to the collection, helping you debug this script.
 - `https://github.com/argovis/tc-sync/blob/main/summary-computation.py <https://github.com/argovis/tc-sync/blob/main/summary-computation.py>`_ prepares summary documents for inclusion in the ``summaries`` collection. At a minimum, this should update the ``summaries.ratelimiter`` document to add a key ``summaries.ratelimiter.metadata[data collection name]`` that has keys ``startDate`` and ``endDate`` reflecting the earliest and latest data timestamps in the collection, as well as ``metagroups``, an array of planned API query string parameters that target limited groups of documents and thus should be spared the usual temporospatial limits; also ensure this document is updated when the collection is updated. Furthermore, the summary collection is an opportunity to pre-compute summary statistics and descriptions, lightening load and speeding up performance for users.
 - `https://github.com/argovis/tc-sync/blob/main/roundtrip.py <https://github.com/argovis/tc-sync/blob/main/roundtrip.py>`_ is a proofreading script, intended to be run after collection population is complete, to double check that the data in MongoDB correctly matches upstream data products. Please note that **it is not sufficient to run the same translation algorithm as originally populated the collections**. The proofreading script should convert and compare between data formats using at least a slightly different procedure, to ensure that we get the same answer in two meaningfully different cases. 

Documentation
-------------

At this point, you have enough information to update the docs at :ref:`db_getting_started` and :ref:`schema`.

*Last reviewed 25-01-17*