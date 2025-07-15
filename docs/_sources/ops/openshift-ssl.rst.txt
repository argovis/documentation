.. _ssl:

Openshift SSL Certificate Management
====================================

Argovis' public facing routes served from Openshift (the API and key manager at the time of writing) require SSL certificates for their HTTPS encryption. These certificates need to be renewed annually, around April.

SSL Cert Renewal
----------------

 - When it's time to renew certs, you'll receive an email from OIT / Sectigo. Use the included links to log in to Sectigo and request renewals through their dashboard.

   - Some instructions at this step are a bit ambiguous; you need to make separate requests for each common name, ``argovis-api.colorado.edu`` and ``argovis-keygen.colorado.edu``. Do not put them in the same request.
   - You can also be a bit more proactive about this: `log into sectigo <https://hard.cert-manager.com/customer/cuboulder/ssl/login>`_ any time before certs expire, request renewals for the frontend, core API, drifter API and keygen certs, and open an OIT ticket confirming these have no personal or confidential info associated with them and can they please approve the renewal request.

 - Within a day or two, you will get an enrollment successful email for each common name with links to a bunch of certs. save them all for posterity.
 - To use these certs, you need to make new routes in Openshift. Navigate netowrking -> routes, and copy the yaml for apikey-manager-<last year>. Updates:

   - Name to ``apikey-manager-YYYY`` for this year.
   - PEM format cert: should download in the previous step with a name like argovis-keygen_colorado_edu_cert.cer, have a single BEGIN / END CERTIFICATE block
   - Private key: should never change, copy from last year's yaml
   - CA cert chain: the root-first one you downloaded above, named like argovis-keygen_colorado_edu_interm.cer.
 
 - Once the YAML is set up, delete the old route and use this YAML to create the new one. Confirm you can still reach the keymanager in the browser without security warnings.
 - Repeat the route setup for all other publicly accessible services.

*Last reviewed 2025-04-11*
