.. _api_usage:

Argovis API Usage
=================

Argovis seeks to provide a RESTful API that underwrites `FAIR data principles <https://www.go-fair.org/fair-principles/>`_ with a strongly standards compliant set of endpoints that are consistent both in their search filters, and in the object schema they return. This document will get you started on understanding and using the Argovis API.

API keys & limits
-------------------

Like all APIs, Argovis limits the rate at which users are allowed to make requests. These usage limits are enforced by the provisioning and use of *API keys*. Your API key identifies you, and entitles you to the same level of service from Argovis as all other key holders.

Getting your API key
++++++++++++++++++++

To get a free API key, visit `https://argovis-keygen.colorado.edu <https://argovis-keygen.colorado.edu>`_ and fill out the form titled *New Account Registration*. Your API key will be sent to the email you provide.

.. admonition:: Keep It Secret

   Treat your API key like a password. If someone gets ahold of your key, they can make API requests on your behalf and waste your resource allocation. If you ever think your API key has been compromised, or you lose or forget it, visit the same page you created it at and fill out the appropriate form to change, delete, or re-send your API key.

Once you have your key, provide it in the ``x-argokey`` HTTP header on all requests to the Argovis API. Your programming language of choice should have well-established tools for making requests with custom headers such as this.

How rate limitation works
+++++++++++++++++++++++++

Argovis implements a conventional *token bucket* algorithm for rate limitation, which provides you with a quota of requests that replenishes automatically over time. Qualitatively, this means two things:

 - You can make a small number of requests rapidly, for example in a typical ``for`` loop.
 - If you need to make a large number of requests, you'll need to add a small delay betweem them, to allow your quota time to replenish.

The specifics of how many rapid requests you can make, and how fast your quota replenishes, are noted in the table on the API key generation page. Note that these parameters may change over time, as they are tuned to accommodate real usage of Argovis.

.. admonition:: Error 429: Too Many Requests

   If you recieve a response to an API request with HTTP error code 429, this probably indicates you've made too many requests too quickly, and the server is declining you. Wait a minute for your quota to replenish if you're only making a few requests, or add a delay between requests if you are looping through many requests.

Using Argovis without a key
+++++++++++++++++++++++++++

Savvy users will quickly notice that Argovis' API will still respond to you if you don't provide an API key at all - sometimes. Keyless requests are tolerated, but are rate limited *globally* - you share the same resource allocation with all users worldwide who are making requests without an API key. This is intended for simple introductory use only; do not make production code that relies on keyless requests.

Constructing queries
--------------------

Argovis seeks to provide a highly expressive set of search and filter parameters, so you can ask for and download only the exact data you care about. To do so, you need to use the `API docs <https://argovis-api.colorado.edu/docs>`_ to construct your query of interest. In this section, we'll walk through building a simple query.

Step 1: API root
++++++++++++++++

The first part of all API requests is the *API root*. It's always the same: ``https://argovis-api.colorado.edu``.

Step 2: API route
+++++++++++++++++

The second part of an API request is the *route*. Argovis generally names routes according to the sort of object you're going to get returned to you. If you visit `https://argovis-api.colorado.edu/docs <https://argovis-api.colorado.edu/docs>`_, you can see all the routes available to you, grouped into a few categories. For this example, let's consider the ``/profiles`` route; this will return profile data, as the name suggests. We concatenate this with the API root: ``https://argovis-api.colorado.edu/profiles``.

Step 3: Query String Parameters
+++++++++++++++++++++++++++++++

Query string parameters are where we start filtering down data to get just what we want. Click on the ``/profiles`` route on the docs page to see the parameters available to you for this route; each one includes a description of what it's meant to represent, and an example of how to encode it. You can use as many of these as you like in a single request; these filters are ANDed together, meaning each one you add will restrict the amount of data returned further and further. They are separated from the route with a ``?``, and separated from each other with an ``&``. In practice, I build up a query like this, one parameter at a time:

 - ``/parameters?startDate=2022-01-01T00:00:00Z``: give me all the profiles after midnight, January 1, 2022.
 - ``/parameters?startDate=2022-01-01T00:00:00Z&endDate=2022-01-02T00:00:00Z``: give me all the profiles after midnight, January 1, 2022, but before midnight, January 2, 2022.
 - ``/parameters?startDate=2022-01-01T00:00:00Z&endDate=2022-01-02T00:00:00Z&center=0,0&radius=10``: give me all the profiles after midnight, January 1, 2022, but before midnight, January 2, 2022, located within 10 kilometers of longitude=0, latitude=0

Et cetera. Keep adding parameters to zero in on the data you want.

.. admonition:: Error 413: Payload Too Large

   If you make extremely broad requests, they could match many gigabytes of data, which is infeasible to return in a single download. In this case, the server will reject your request with an error code 413. If this happens to you, try slicing up your large request into several small ones: for example, ask for a 20 degree box at a time instead of the entire Pacific, or one day at a time in a loop instead of an entire year. While the size of an individual request is limited, and the rate at which we can support requests is also limited, the total number of requests you can make is not. Make as many as you need to to get the information you want.

A few nuances about our query string parameter encoding and behavior:

 - Latitudes must be on [-90,90]; longitudes must be on [-180,180].
 - Parameters that accept lists generally AND together the items found in their lists; so for example, ``/profiles?data=pres,doxy`` will filter for profiles that have *both* pressure and dissolved oxygen, not just one or the other.
 - Some parameters note they support *~ negation*. This means you can search for documents that *don't* match the listed value. If we changed tha above example to ``/profiles?data=pres,~doxy``, this would match profiles that have pressure but do *not* have dissolved oxygen.
 - Some parameters, particularly those that have a fixed vocabulary of options, like which data center to query from, have a corresponding special route to show you what all the options are. These will be noted in the API docs beside the parameter, where applicable.

*Last reviewed 22-05-18*