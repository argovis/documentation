.. _data_sources:

Data Sources
============

Argovis federates Earth system data from many sources; in this doc, we record each of these sources, and point to a indication of how to recreate each.

Argo
----

A full sync of ifremer's Argo database is maintained by Argovis on its Kubernetes cluster. This mirror is updated nightly, and changes are migrated into Argovis' mongodb instance, ``profiles`` collection, by the cronjob captured at https://github.com/argovis/ifremer-sync/blob/main/ifremer-cron.yaml, and the scripts that cronjob calls, with containerized environment defined by https://github.com/argovis/ifremer-sync/blob/main/Dockerfile.

GO-SHIP
-------

GO-SHIP data is translated from the original netCDF to JSON documents by the excellent work of our CCHDO colleagues; our very slightly modified version of this script is kicked off by https://github.com/BillMills/argovis_convert_netcdf_to_json/blob/2022Q2/run.sh, managed by the version of the code found on that branch and repo, and run in the environment defined by https://github.com/BillMills/argovis_convert_netcdf_to_json/blob/2022Q2/Dockerfile.

Once translated to JSON, GO-SHIP profiles are loaded into mongo, ``profiles`` collection, as managed by https://github.com/BillMills/argovis_convert_netcdf_to_json/blob/2022Q2/loaddata.yaml, with container defined by https://github.com/BillMills/argovis_convert_netcdf_to_json/blob/2022Q2/Dockerfile-loadDB.


Tropical Cyclones
-----------------

wip, https://github.com/argovis/tc-sync

Gridded Data
------------

*Last reviewed --*