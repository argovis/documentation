.. _from_scratch:

Rebuild Mongo from sctatch
==========================

In the event of a platform migration or catastrophic hardware failure, the first step to restoring Argovis in a fresh environment is to recreate and repopulate its MongoDB instance, the steps for which are enumerated in this doc.

Recreate MongoDB container
--------------------------

Argovis uses the simplest possible MongoDB architecture: a single standalone instance. Make sure your platform has available for MongoDB's exclusive use:

 - at least 1 dedicated CPU
 - at least 16 GB dedicated RAM (more is always better, much more is much better)
 - at least 2 TB of SSD (do *not* attempt to run in production without solid state drives, unless you have a couple of TB of RAM instead).

See `https://github.com/argovis/argovis_deployment <https://github.com/argovis/argovis_deployment>`_ for examples on how we stand up MongoDB in Kubernetes and Swarm; similar will work even for a single container. Of particular note is the storage provisioning and networking: 

 - **Storage:** make sure a volume or PVC is mounted at ``/data/db``, and that volume is backed by your SSDs.
 - **Networking:** other Argovis components expect to resolve the token ``database`` to MongoDB on the container network. Therefore, on Kube you'll need a ClusterIP named appropriately, on Swarm you'll need to name the mongo service ``database`` and attach it to a shared container network that accepts individual (non-swarm) container mounts, or as a standalone container you'll again need to name it ``database`` and attach it to a container network.

Recreate collections
--------------------

`https://github.com/argovis/db-schema <https://github.com/argovis/db-schema>`_ contains scripts to recreate the collections Argovis relies on, including schema enforcement and index definitions. See the readme in that repo for instructions.

Repopulate collections
----------------------

Now that MongoDB is up and running and collections are defined, we need to recreate the data for each collection of interest, per the following.

Argo
++++

Scripts to repopulate the ``argo`` and ``argoMeta`` collections are found at `https://github.com/argovis/ifremer-sync <https://github.com/argovis/ifremer-sync>`_; follow the readme there to recreate these collections. Note the full process take several *weeks* of compute time.


CCHDO
+++++

Global Drifter Program
++++++++++++++++++++++

See [https://github.com/argovis/drifter-sync](https://github.com/argovis/drifter-sync)'s readme for instructions.

Gridded Products
++++++++++++++++

Tropical Cyclones
+++++++++++++++++

See [https://github.com/argovis/tc-sync](https://github.com/argovis/tc-sync)'s readme for instructions.


*Last reviewed 22-10-04*