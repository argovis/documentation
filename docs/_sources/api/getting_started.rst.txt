.. _api_getting_started:

Getting started with Argovis API development
============================================

One of Argovis' core features is its API, designed to support detailed indexing and cross-referencing of a variety of oceanographic data. Some considerations to begin with when thinking about updating our API:

 - API code lives in `https://github.com/argovis/argovis_api <https://github.com/argovis/argovis_api>`_.
 - Our API is strictly `openAPI 3.0.3 compliant <https://spec.openapis.org/oas/v3.0.3>`_, and built as a NodeJS container.
 - Routes and query parameters are heavily standardized between collections. All non-experimental collections have the following minimal set of routes and query string filters:

   - A route to search data documents, such as ``/argo``. Data documents are at a minimum filterable by id, geolocation, timestamp and metadata key.
   - A route to seatch metadata documents, such as ``/argo/meta``. Metadata documents are at a minimum filterable by id.
   - A vocabulary route to request enumerations of categorical search parameters, such as ``/argo/vocabulary``. Vocabulary routes always have exactly one query string parameter, called ``parameter``, to specify the possible values for other query string parameters. For example, both Argo data and metadata are searchable by platform WMO number; ``/argo/vocabulary?parameter=platform`` returns a list of all possible platform identifiers.

   Respect this standardization. It helps our users interoperate across datasets by defining a core logic common to them all.

 - In addition, custom routes may optionally be defined per dataset that offer specialized results for that product, typically pulling summary documents from the ``summaries`` collection, for example ``/argo/bgc``.
 - For datasets that don't naturally fit Argovis' point-and-lattice centric schema standards, more freeform (though still OpenAPI compliant) routes can be defined if marked ``experimental`` in their API spec tags. An example of this is extended objects, like atmospheric rivers.
 - All user requests to Argovis' API are subject to rate limitation, accomplished by providing an API key in headers which is used to allocate a limited rate of requests per user by a token bucket algorithm.

Further sections in this chapter detail how these components work and how to update them.

*Last reviewed 23-03-07*