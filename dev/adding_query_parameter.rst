.. _adding_query_parameter:

Adding a query parameter to an API route
========================================

Sometimes, users will want to be able to search and filter by some parameter that is in the database, but not currently associated with an API query string parameter. Follow this guide with examples to do so.

Is it feasible?
---------------

Every searchable parameter in any API requires the underlying database to index the parameter being filtered on, for performance reasons. Check your production database: how big are comparable indexes on the collections you want to add an index to? How much free memory do you have to accommodate this? Bear in mind that every index sitting in memory chokes your server's ability to maintain a large working set, so proceed cautiously and do not implement unless there is significant, multi-stakeholder demand.

Updating API code
-----------------

Most of the work will be in correctly updating the API spec and business logic in `argovis_api <https://github.com/argovis/argovis_api>`_, as outlined below.

Update API templates
++++++++++++++++++++

 - Make sure you have the latest for the ``templates`` branch of the API repo, and make a dev branch off of this.
 - Edit ``spec.yaml`` (and only this file) to add your new query string parameter to the appropriate route.
 - Consider also allowing a vocab search on any parameter with categorical values at this time.
 - Build and stage pull request into upstream ``templates`` branch.
 - Example (note only the changes to ``spec.yaml`` here were made by a human, the rest comes from the build process): `template update <https://github.com/argovis/argovis_api/pull/203>`_

Update API business logic
+++++++++++++++++++++++++

 - Make sure you have the latest for the ``server`` branch of the API repo, and make a dev branch off of this.
 - Merge in what's new from the ``templates`` work you did above. Resolve and commit merge conflicts.
 - Implement any new logic required, and add tests.
 - Once tests passing, merge this and the templates PR upstream.
 - Example: `server update <https://github.com/argovis/argovis_api/pull/202>`_

Database prep
-------------

 - Add index manually to existing collections for any new parameter being filtered on.
 - Add index definition to scripts in the `schema definition repo <https://github.com/argovis/db-schema>`_
 - Example: `new argo indexes <https://github.com/argovis/db-schema/pull/28>`_

Launch
------

 - Make an API release on GitHub (`example <https://github.com/argovis/argovis_api/releases/tag/2.0.0-rc40>`_)
 - Build new container image from ``server`` branch and push to Docker Hub
 - Deploy updated API image in production
 - Try your new filter manually to confirm success.

*Last reviewed 2022-12-06*