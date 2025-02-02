.. _prometheus:

Prometheus metrics for Argovis
==============================

Argovis' API is instrumented with several Prometheus metrics to help monitor its performance. These metrics are exposed on the `/metrics` endpoint of the API, and can be scraped by a Prometheus server for monitoring.

Raw metrics
-----------

The following Prometheus counters track the lifecycle of an incoming request:

 - incoming_requests: A counter of the number of requests the API has received at the top of the token bucket.
 - requests_denied: Number of incoming HTTP requests rejected due to malformed input (400), ginormous tempotospatial extent (413), or throttling (429)
 - requests_error: crash encountered in lookup or transmission (500 series)
 - successful_requests: made it to the end of the pipeline, ready to be returned

We also have one histogram, `api_request_duration_seconds`, that tracks the duration of requests in seconds.

Deployment notes
----------------

 - All the kubernetes infrastructure needed for this is described in the helm charts and will deploy with the rest of the stack.
 - Note it is important to use the role and roleBindings provided so Prometheus can automatically track all API pods, as opposed to getting random pod responses from the service routing to them.
 - The blackbox deployment is solely responsible for tracking API uptime.

Useful PromQL queries
---------------------

Prometheus uses its own simple query language fo visualizing things at its frontend, which you can find at https://argovis-prom-atoc-argovis-dev.apps.containers02.colorado.edu/ behind the CU VPN. Here are some common interesting queries:

- `sum(incoming_requests{endpoint!='/ping'}) by (endpoint)`: [`link <https://argovis-prom-atoc-argovis-dev.apps.containers02.colorado.edu/graph?g0.expr=sum(incoming_requests%7Bendpoint!%3D%27%2Fping%27%7D)%20by%20(endpoint)&g0.tab=0&g0.display_mode=lines&g0.show_exemplars=0&g0.range_input=1h>`_] show the cumulative number of requests to each endpoint
  
  - sum is needed to sum over backend API containers
  - we exclude ping because those run every few seconds as a health check
  - note these counters will reset when pods roll over.

- `probe_success{job='api-uptime', instance='https://argovis-api.colorado.edu/ping'}`: [`link <https://argovis-prom-atoc-argovis-dev.apps.containers02.colorado.edu/graph?g0.expr=probe_success{job%3D'api-uptime'%2C instance%3D'https%3A%2F%2Fargovis-api.colorado.edu%2Fping'}&g0.tab=0&g0.display_mode=lines&g0.show_exemplars=0&g0.range_input=4w>`_] see uptime for API
- `histogram_quantile(0.50, sum(rate(api_request_duration_seconds_bucket{endpoint="/argo"}[6h])) by (le))`: [`link <https://argovis-prom-atoc-argovis-dev.apps.containers02.colorado.edu/graph?g0.expr=histogram_quantile(0.50%2C%20sum(rate(api_request_duration_seconds_bucket%7Bendpoint%3D%22%2Fargo%22%7D%5B6h%5D))%20by%20(le))&g0.tab=0&g0.display_mode=lines&g0.show_exemplars=0&g0.range_input=4w>`_] see median request time for the /argo endpoint over the last six hours.

*Last reviewed 2025-02-02*