.. _db_ops:

Database Resourcing & Deployment
================================

Enumerated below are some basic considerations for deploying and operating MongoDB for Argovis.

Deployment topology
-------------------

 - As noted above, each instance of Argovis (Core and all satellite deployments) each run their own instance of stand-alone MongoDB, currently 5.09.
 - As all Argovis software is always containerized, ensure appropriate networking tools are in place when deploying MongoDB so that other containers can reach it; this means an attachable overlay network in Swarm, or an appropriate clusterIP object in Kubernetes. Other components will attempt to resolve MongoDB at the in-cluster DNS name ``database``.
 - MongoDB by default writes all data to ``/data/db`` inside its container. Make sure sufficient storage is mounted there, and that it is backed up regularly.
 - In Kubernetes, impose a memory and cpu request if quota is available, to discourage rescheduling of MongoDB.

Resourcing
----------

Ideally, MongoDB should be provisioned with enough RAM to hold the entire working set and all indexes for all collections in memory. Since as with most scientific datasets there is no way to define a subset of general interest or priority, this means enough RAM to hold *everything*, indexes as well as complete collections. Since this is often unrealistic, an adequate compromise is to provision enough RAM for your indexes, and enough fast disk for everything else; these disks *must* be SSD and *must* be either physically mounted in the same server as the container host or connected to it by very fast intra-datacenter networking. HDDs over NFS will not be adequate.

One dedicated current-gen CPU per MongoDB instance should be plenty.

Disaster Recovery
-----------------

In the event of a catastrophic failure of MongoDB, you may need to restore from an image of the storage mounted to ``/data/db`` inside your MongoDB container. Note that this is the only place Argovis persists critical information on disk; all other components are stateless and can be safely destroyed and recreated as needed. Ideally, MongoDB should be cleanly stopped before creating this backup, but this is in practice difficult to coordinate with storage teams. In the event that the database must be restored from a hot storage backup, consider a couple of increasingly dire mitigations:

 - If we're lucky, simply copying or re-mounting the complete set of database image files from the backup location to ``/data/db`` might work.
 - If mongo continues to refuse to start, try starting it with the ``--repair`` flag, as presented `here <https://www.mongodb.com/docs/manual/tutorial/recover-data-following-unexpected-shutdown/>`_.
 - If mongo repair fails, try removing the journal and ``mongo.lock`` files from ``/data/db`` (while of course being careful to keep a backup of them), and starting with ``--repair`` again; this is an extreme measure that should be avoided, but has saved our database in the past.

*Last reviewed 2023-03-06*