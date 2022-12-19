.. _from_AMI:

Restore Argovis from an AMI on AWS
==================================

In the event of an EC2 instance failure or migration, Argovis can be restored from a backup AMI by the following procedure.

Launch EC2 Instance
-------------------

 - From the AWS console, navigate to EC2 -> AMIs, find the AMI you want to base your deployment on (backup AMI or a recent vanilla Ubuntu LTS AMI), and launch.
 - Fill out the config form for the instance. Some key points:

   - Make sure to choose an appropriate instance type; at time of writing, an i3en.xlarge is suitable.
   - In the networking section, make sure to choose a VPC and subnet in an availabiity zone that supports the instance type you chose above. Also, make sure automatic assignment of public IPV4 is enabled.
   - If launching from a backup AMI, keep the default disk size, or bigger; if launching from an off-the-shelf Ubuntu AMI, make sure to provision enough disk (at least 2 TB SSD).

 - Launch and wait for the instance to start up.
 - If launching from a generic AMI, copy over disk backups from S3.
 - Open instance's security group to all traffic from the IP of your proxy host (atoc02 at time of writing).

Recreate Argovis
----------------

Once the server is up and its filesystem is in place, it's time to re-stand-up Argovis:

 - Have a look at `https://github.com/argovis/argovis_deployment/blob/main/swarm-deploy.sh <https://github.com/argovis/argovis_deployment/blob/main/swarm-deploy.sh>`_. This scrips stands up the correct Docker Swarm assets for an Argovis deployment.
 - SSH to your EC2 instance, copy over that script, and make any config adjustments needed (mounts, image tags, environment variables).
 - Run the script to launch all assets.
 - Make sure the crontab has an entry like ``0 7 * * * bash /home/ubuntu/src/ifremer-sync/ifremer-cron.sh`` (path might be different, wherever the nightly IFREMER sync script lives)
 - Kick off an immediate resync with the same script mentioned in the crontab.

Proxy Config
------------

Remember to reconfigure any proxies or load balancers to your new deployment. For CU's deployment, see `https://github.com/argovis/proxy <https://github.com/argovis/proxy>`_.

Acceptance Testing
------------------

At this point, everything should be back up; visit the frontend, key generator, API docs and hit an API endpoint directly for a quick sanity check. In principle, once the IFREMER resync completes, all data save any API keys generated since the last user table backup should be recovered.

*Last reviewed 22-12-19*

