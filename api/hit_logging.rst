.. _api_hit_logging:

API hit logging
===============

In order to keep track of Argovis API usage, we anonymously log API requests in mongodb. Only route, query string, and timestamp of the request is recorded; Argovis never logs any personally identifying information of any kind.

Recreating hit log collections
------------------------------

Hit logging is recorded as a MongoDB timeseries, the collection for which is manually created and indexed as per the following in every MongoDB deployment:

   .. code:: bash

      db.createCollection(     
      	"apihits",
      		{
      			timeseries: {
      				timeField: "timestamp",
      				metaField: "metadata",           
      				granularity: "hours"        
      			}  
      		})
      db.apihits.createIndex({"metadata": 1})

The ``metadata`` key in this collection contains the route, while the ``query`` key contains an object describing the query string parameters.

Visualizing API hits
--------------------

Code to produce an extremely bare bones visualization of this data lives at `https://github.com/argovis/apihits <https://github.com/argovis/apihits>`_.

*Last reviewed 23-04-26*