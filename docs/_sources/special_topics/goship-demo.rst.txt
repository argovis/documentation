Goship Demo Rebuild
===================

Instructions to rebuild the temp goship demo on Digital Ocean.

Instance Setup
--------------

1. Create a basic-tier droplet with 4 GB RAM, should be the $24/mo option.

2. Connect to the instance and install docker and docker-compose:

   .. code:: bash

      ~ $ curl -fsSL https://get.docker.com -o get-docker.sh
      ~ $ sh get-docker.sh
      ~ $ sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
      ~ $ sudo chmod +x /usr/local/bin/docker-compose

3. Make the appropriate directory structure, and put the code in place:

   .. code:: bash

      ~ $ mkdir -p ~/argovis/data/goship
      ~ $ cd ~/argovis
      ~ $ git clone -b dev https://github.com/argovis/argovisNg
      ~ $ cd argovisNg

4. Replace ``docker-compose.yml`` with the following:

   .. code:: yaml

      version: '3'
      services:
        argo-express:
          image: argovis/argo-express:dev
          restart: always
          ports: 
          - '3000:3000' # specify port forwarding
          links:
          - database
        goship-demo:
          image: argovis/argo-express:goship-demo
          restart: always
          ports:
          - '3001:3001' # specify port forwarding
        database:
          image: mongo:4.2.3  # specify image to build container from
          restart: always
          ports:
            - '127.0.0.1:27017:27017' # include localhost ip to restrict access to localhost
          volumes:
            - /root/argovis/data:/data/db:Z # development

Database Restore
----------------

5. Copy the goship mongo backup (consisting of ``profiles.bson`` and ``profiles.metadata.json``) into position at ``~/argovis/data/goship``.

6. Start the app:

   .. code:: bash

      ~ $ cd ~/argovis/argovisNg
      argovisNg $ docker-compose up -d

7. List containers and identify the container ID of the database container, ``a5bd1055a06d`` in the example below:

   .. code:: bash

      argovisNg $ docker container ls 

      CONTAINER ID   IMAGE                                ...
      d7f0f8ab7803   argovis/argo-express:dev             ...
      a5bd1055a06d   mongo:4.2.3                          ...
      fd61f54bd821   argovis/argo-express:goship-demo     ...

8. Reload the goship db, making sure to sub in the container ID you just found above:

   .. code:: bash

      argovisNg $ docker container exec <database container ID> mongorestore --batchSize=64 --db=goship --collection=profiles /data/db/goship/profiles.bson

9. Force-free memory by cycling the app:

   .. code :: bash

      argovisNg $ docker-compose down
      argovisNg $ docker-compose up -d

10. Check for a sensible response at ``<public IP>:3001/catalog/profiles/6657884888673.952_111/page``

*Last reviewed --*