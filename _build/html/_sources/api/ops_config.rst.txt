.. _api_ops:

API deployment configuration
============================

There are a few possible deployment configurations for Argovis' API, which we will discuss along with resourcing in this document.

Core versus satellite deployments
---------------------------------

Two environment variables govern what mode our API is running in, and should always be set; valid values are enumerated here:

 - ``ARGOCORE``:

   - ``here``: API should look in the local MongoDB to validate user keys.
   - ``<URL>``: API should call ``<URL>/token`` to validate user keys, where ``<URL>`` is the root of the Argovis Core deployment.

 - ``ARGONODE``:

   - ``core``: this API should serve the Argovis Core datasets and routes.
   - ``miami``: this API should serve the Global Drifter Program dataset and routes.

Resourcing and scale
--------------------

As a stateless container, our API horizontally scales easily. As load increases and resources become available, begin by increasing the number of replicas of the API pod or container; about 1 GB of RAM and a few hundred milliCPU each has in general been sufficient.

*Last reviewed 23-03-08*