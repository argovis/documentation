.. _perftest:

Performance Testing
===================

In order to ensure Argovis scales to as many users as possible, and to give those users as good an experience as possible, Argovis undergoes performance testing to identify bottlenecks and measure viable load. This tutorial gives a high level overview of the tools and techniques available; refer to linked repos and docs for deeper dives.

Load Testing
------------

Load testing scripts and resources are maintained in `this repo <https://github.com/argovis/artillery>`_, and serve as our primary performance metric. As noted there, a key metric to track is median response time over time - this should be as stable as possible even for the heaviest endpoints, or else sustained load could degrade and crash the app. See the README in that repo for detailed config and run instructions.

Database Response Testing
-------------------------

In order to determine if mongodb is primarily responsible for slow responses from the API, we can use its built in profiler per the following. See `the mongo docs <https://docs.mongodb.com/manual/tutorial/manage-the-database-profiler/>`_ for more info.

1. Connect to a ``mongo`` shell in your running mongo container, using ``oc exec``, ``docker container exec``, or ``kubectl exec`` as appropriate for your environment.

2. Turn on mongo's profiler. 100 ms is a reasonable cutoff for our purposes; actions slower than this will be logged:

   .. code:: bash

      > use argo
      > db.setProfilingLevel(1, { slowms: 100 })

3. Run some API requests, by hitting it manually or by running the Artillery scripts linked above.

4. Back in the mongo shell, check for events that took longer than 1000 ms (adjust to taste):

   .. code:: bash

      > db.system.profile.find( { millis : { $gt : 1000 } } ).pretty()

   From here, you'll have a list of the most expensive operations mongo is processing. See the ``millis`` key in the response documents for the length of time mongo spent on the operation; if this is a large or majority contribution to the response time of the API, consider scaling mongo or restricting the size of API calls allowed.

5. When done, make sure to turn off profiling in order to avoid impacting performance:

   .. code:: bash

      > db.setProfilingLevel(0)

*Last reviewed --*