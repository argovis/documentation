.. _drifters-aws:

Deploy Global Drifter Program database on AWS
=============================================

Argovis serves Global Drifter Program data through a satellite deployment of our database and API, currently on AWS. In this document, we'll go through the steps to recreate this service from its AMI.

1. Find the appropriate AMI in the Argovis AWS account under the EC2 service; at the time of writing, that would be ``ami-03c4fccd4dedad624`` / ``argovis-drifters-230309`` in us-east-1, though look and see if there's one with a more current date. Launch a new instance from this AMI.

2. In the instance creation page, most defaults are fine, except:

 - Give it a sensible name, like ``argovis-drifters``
 - Choose an appropriate instance type; ``r5.large`` is a good balance between resources and economy.
 - Under networking, make sure the ``argovis`` VPC and subnet are selected, and enable auto-assigning a public IPV4. If you're setting this up in a new region, you'll need to make a VPC, subnet and routing table first; defaults for those are also fine, with the caveat that you might need to shop around for an availability zone for the subnet that supports the instance type you chose.

 Otherwise, accept the defaults and launch the instance.

3. Once the instance is running, SSH in and set up the appropriate containers. You may consider adjusting image tags to the most current releases, and memory limits to something suitable for the instance type you chose; the numbers below were chosen for ``r5.large``:

   .. code:: bash
   
      docker service create --network argovis-db --name database --limit-memory 14GB --mount type=volume,source=mongoback,destination=/data/db  mongo:5.0.9
      docker service create --network argovis-db --name redis --limit-memory 100MB argovis/redis:7.0.3-220713
      docker container run --network argovis-db --name api -p 8080:8080 --memory 1.5GB -e ARGOCORE='https://argovis-api.colorado.edu' -e ARGONODE='miami' -d --restart always argovis/api:2.6.1


4. Back on AWS, make a custom TCP rule that allows inbound traffic on port 8080 (or whatever port you exposed the API on) in your new instance's security group.

5. At this point, the drifter satellite should be live; try hitting ``<public IP>/drifters?id=101143_3`` to confirm. If this is replacing a previous instance of the drifter satellite, you may need to update reverse proxies (such as `https://github.com/argovis/proxy <https://github.com/argovis/proxy>`_) to route traffic to your new deployment.

*Last reviewed 2023-03-09*