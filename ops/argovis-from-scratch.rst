.. avfs:

Runbook: Argovis from scratch
=============================

In this runbook, we give the steps to redeploy Argovis from scratch, rebuild the Argo collection, and set up nightly updates of the same. A devops engineer having a basic familiartiy with Kubernetes should be able to deploy Argovis from scratch on appropriate infrastructure. Deployment should be possible in <1h, and rebuild of the Argo collection should proceed over the course of several days, mostly unmonitored.

Deployment targets
------------------

Argovis is designed to deploy to CU's Openshift cluster, but any Kubernetes cluster will in principle work. Start by asking ops for a fresh Openshift namespace with the following resource limits and reservations:

- limits.cpu: 8
- limits.memory: 32 Gi
- requests.cpu: 4
- requests.memory: 16 Gi
- requests.storage: 3 Ti

Argovis has also been informally but successfully deployed to Docker Swarm on ATOC servers and AWS; while this is not a supported deployment target, an experienced container engineer should be able to translate the following to Swarm if needed.

Pre-flight setup
----------------

After getting a namespace with the appropriate resource allocations, begin by allocating some appropriate persistent volume claims, preferably something with a driver that supports ``VolumeSnapshot``; at the time of writing, ``thin-csi`` is a good choice at CU. Create PVCs with something like:

.. code:: yaml

   apiVersion: v1
   kind: PersistentVolumeClaim
   metadata: { name: <see_list_below> }
   spec:
     storageClassName: thin-csi
     accessModes: [ReadWriteOnce]
     resources: { requests: { storage: <see_list_below> } }


Storage you'll need for this runbook:

- ``argo-mongo-b-csi``: 600 Gi. Mongo's backing for ``/data/db``.
- ``argovis-bulk``: 900 Gi. Where raw Argo nc data is rsync'ed to.
- ``logs``: 5 Gi. Some lightweight logs from the nightly updates you'll set up below.
- ``prometheus-tdsb``: 50 Gi. Prometheus time series database for API metrics.

Make sure the names match the Helm charts and cronjobs you'll deploy below.

Finally, provision a Sendgrid API token in a secret named ``sendgrid-api-token`` which will be provisioned as the environment var ``SENDGRID_API_KEY`` in the API key management container; 
this is used to email users when they register an API token. See Sendgrid's docs for details.

Application deployment
---------------------

Argovis is orchestrated via Helm chart recorded in `https://github.com/argovis/argovis_deployment <https://github.com/argovis/argovis_deployment>`_.
Deployments and internal networking should deploy from that repo with ``helm install argovis ./argovis``; 
changes in future are made with ``helm upgrade argovis ./argovis``.
If the helm deployment is successful, you should see happily running pods:

- a single mongo pod for our standalone database (official Docker image, should be available on Dockerhub)
- a single redis pod for managing token bucket consumption (redis as slightly configed per `https://github.com/argovis/argovis_redis <https://github.com/argovis/argovis_redis>`_).
- two API containers (or however many you choose to deploy) for the public facing API. Custom API built from `https://github.com/argovis/argovis_api <https://github.com/argovis/argovis_api>`_.
- one frontend serving the Argovis web application. Built from `https://github.com/argovis/react/ <https://github.com/argovis/react/>`_.
- a key management frontend serving a small web app for registering API keys. Built from `https://github.com/argovis/apikey-manager <https://github.com/argovis/apikey-manager>`_
- a prometheus pod for monitoring the API. Built from `https://github.com/argovis/prometheus <https://github.com/argovis/prometheus>`_.
- a prometheus black box exporter pod primarily for monitoring uptime. Official image.

Networking ingress
------------------

At this point, all Argovis pods should be alive and talking to each other, but unreachable from the public internet.
The API, frontend and API key management tool need routes configured for public ingress.
You will need to coordinate with OIT to get appropriate DNS entries and TLS certificates for the public facing components; email their help desk for the latest guidance. 
Once you have those, you can configure the routes in Openshift with something like:

.. code:: yaml

   kind: Route
   apiVersion: route.openshift.io/v1
   metadata:
   name: argovis-api-2026-09
   namespace: atoc-argovis-dev
   labels:
       containers.colorado.edu/access: public
   annotations:
       haproxy.router.openshift.io/timeout: 5m
   spec:
   host: argovis-api.colorado.edu
   to:
       kind: Service
       name: api
       weight: 100
   port:
       targetPort: 8080
   tls:
       termination: edge
       certificate: |
       <your PEM cert here>
       key: |
       <your private key here>
       caCertificate: |
       <your root-first CA cert here>
       insecureEdgeTerminationPolicy: Redirect
   wildcardPolicy: None
   status:
   ingress:
       - host: argovis-api.colorado.edu
       routerName: public
       conditions:
           - type: Admitted
           status: 'True'
       wildcardPolicy: None
       routerCanonicalHostname: router-public.pub.containers02.colorado.edu


Note you'll need to provide the cert, private key and CA cert, as well as the appropriate host name for your deployment, all of which OIT will help you figure out. 
Repeat for the frontend and API key management tool, changing the ``host`` and ``name`` fields appropriately.

Rebuilding the Argo collection
------------------------------

Argovis indexes every Argo profile, and updates its database nightly via a Kube cronjob.
See `https://github.com/argovis/ifremer-sync <https://github.com/argovis/ifremer-sync>`_ for docs on how to build the Argo mongo collections from scratch,
and set up the nightly cron job to keep them updated.

*Last reviewed 2026-11-10*