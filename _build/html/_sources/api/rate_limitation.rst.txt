.. _api_rate_limit:

API rate limitation
===================

In order to prevent rapid, large requests from overwhelming and crashing Argovis' servers, API requests are *rate limited* by a simple token bucket algorithm:

 - Every user has a bucket of tokens of finite capacity
 - Every API request costs some amount of tokens
 - If a user makes a request while they have a negative token balance, the request will be rejected (HTTP 429)
 - Each user's token bucket automatically refills to capacity at a constant rate over time.

In this document, we will discuss how this is implemented in Argovis.

User identification
-------------------

In order to distinguish users, Argovis accepts a user API key via the ``x-argokey`` request header. Users can request a personal key by registering with their name and email via our key generation service (code: `https://github.com/argovis/apikey-manager <https://github.com/argovis/apikey-manager>`_, deployment: `https://github.com/argovis/argovis_deployment/blob/main/argovis/templates/keymanager-deployment.yaml <https://github.com/argovis/argovis_deployment/blob/main/argovis/templates/keymanager-deployment.yaml>`_). This service provides basic email-authenticated CRUD operations against the ``argo.user`` collection in MongoDB.

Note that this key management service uses Sendgrid as an email backend to communicate with users; as such, it looks for a valid Sendgrid API token in the environment variable ``SENDGRID_API_KEY``. This environment variable should in turn be provided by a properly encrypted secret management service available in both Kubernetes and Swarm.

In addition to user-generated keys, the string ``guest`` is a valid API key. Any API request that doesn't have an ``x-argovis`` header is treated as if it had ``x-argovis: guest``. As a result, unauthenticated requests can be made, but globally share a single token bucket allocation.

Balance management
------------------

In order to mitigate continuous reads and writes to MongoDB, active balance management is done in memory with a simple Redis deployment (code: `https://github.com/argovis/argovis_redis <https://github.com/argovis/argovis_redis>`_, deployment: `https://github.com/argovis/argovis_deployment/blob/main/argovis/templates/redis-deployment.yaml <https://github.com/argovis/argovis_deployment/blob/main/argovis/templates/redis-deployment.yaml>`_). Redis should be up and running before launching API containers.

Request pricing and bucket configuration
----------------------------------------

See `our token bucket implementation <https://github.com/argovis/argovis_api/blob/server/nodejs-server/middleware/ratelimiter/tokenbucket.js>`_ for global bucket sizing, refill rates, and price scale setting. At high level, we penalize requests with large temporospatial extent, and discount requests that are for metadata only.

For route-specific details, see the ``cost`` function in `https://github.com/argovis/argovis_api/blob/server/nodejs-server/helpers/helpers.js <https://github.com/argovis/argovis_api/blob/server/nodejs-server/helpers/helpers.js>`_. This function returns the price of a given request as a function of its route and query string, and is the correct place to make token price adjustments on a case-by-case basis.

Satellite deployments
---------------------

The ``user`` collection is maintained exclusively in the Argovis Core MongoDB, and not in satellite deployments such as our deployment for the Global Drifter Program. In order to allow satellite deployments to validate API tokens, instead of looking them up in MongoDB, they can make a request against the ``/token`` API endpoint of the Argovis Core deployment to check if an API token is valid, and from there maintain a balance for that user in its local Redis. As such, users actually have independent balances for independent Argovis deployments, while still being able to use a single key across them all.

*Last reviewed 23-03-08*