## Introduction
This repo can be used to install IBM Cloud Pak 4 Integration capabilities and sample applications

## Instructions

You should have an existing OpenShift cluster available. 

### Fork this repo and adapt it for your environment

First, fork this repo. Now update the following files that refer to your repo url: 

* [bootstrap.yaml](./argocd/bootstrap.yaml) 
* [common.yaml](argocd/common.yaml)
* [all-operators](argocd/operators/all-operators.yaml)
* [all-operands.yaml](argocd/operands/all-operands.yaml) Here, also update with your environment, IBM Classic infrastructure (ibm-classic), IBM VPC infrastructure (ibm-vpc) and Azure (azure) are valid values

### Install the OpenShift GitOps operator

From OperatorHub, find the OpenShift GitOps operator and install it with the recommended defaults. For details, see https://docs.openshift.com/container-platform/4.12/cicd/gitops/installing-openshift-gitops.html

### (Optional) Add a webhook to the OpenShift GitOps server

Add a webhook to https://your-gitops-server.com/api/webhook for the push event. For details, see https://argo-cd.readthedocs.io/en/stable/operator-manual/webhook/

### Add the bootstrap ArgoCD application to install operators

In the OpenShift Console, click the "plus" icon and paste the contents of [bootstrap.yaml](./argocd/bootstrap.yaml) to create the bootstrap ArgoCD application. This application will find the [kustomization.yaml](./argocd/kustomization.yaml) file which points to the [common.yaml](./argocd/common.yaml)  application and an ArgoCD ApplicationSet [all-operators.yaml](./argocd/operators/all-operators.yaml)

The "common" application creates a namespace (cp4i by default) and a catalogsource for the IBM operators. 

The all-operators.yaml ApplicationSet generates ArgoCD applications for all operators based on a simple naming convention, pointing into the components subdirectory where Subscriptions for each operator can be found.

After applying the bootstrap file, the operators will be installed. By default, these are installed in the openshift-operators namespace. You can check the status in the OpenShift Console under Operators / Installed Operators.

### Add the IBM entitlement key to access the container registry

Create an image pull secret in the 'cp4i' namespace with the name ibm-entitlement-key, address cp.icr.io, username cp and you entitlement key as password.

### Install operands / capabilities

Now, uncomment the line referring to 'operands/all-operands.yaml' in [kustomization.yaml](./argocd/kustomization.yaml)

The all-operands.yaml ApplicationSet generates ArgoCD applications for Platform Navigator, API Connect, MQ (a sample queue manager), Event Streams (a non-secure, non-persistent instance) OpenShift Logging and OpenShift Monitoring by default. 

If you have enabled the webhook earlier, ArgoCD will refresh and trigger install of the capabilities. If you didn't, open ArgoCD and refresh the bootstrap application in the UI. This happens automatically after 3 minutes. 

The install takes somewhere between 30-60 minutes depending on the cluster resources. 

### Create index patterns for OpenShift Logging

Click the Logging menu item in the OpenShift Console. In the Kibana interface, create two index patterns: 'app' and 'infra' that map to '@timestamp'

### Enable sample applications

Two sample applications are available: 

* A Quarkus Java app implementing a REST endpoint which can be exposed in API Connect
* An App Connect Enterprise application with two message flows

The sample applications are used to illustrate how automating build and deploy can be done and as such are very simplistic. Each sample app has two repos, one that contains the actual code and one that contains the GitOps config for it. If you just want to try out the applications, fork only the GitOps repos.

For the Java application, fork the repo [ibm-offices-gitops](https://github.com/Nordic-MVP-GitOps-Repos/ibm-offices-gitops). Then, in this repo (not the ibm-offices-gitops one), update the file [argocd/apps/ibm-offices.yaml](argocd/apps/ibm-offices.yaml) to point to your forked repository. Finally, update the file [argocd/kustomization.yaml](argocd/kustomization.yaml) and uncomment the line pointing to [argocd/apps/ibm-offices.yaml](argocd/apps/ibm-offices.yaml). You have now added the sample application.

The sample application gets built using a pipeline, which also publishes the API to API Connect. You will need to setup API Connect provider organisations for this to work, but you can run the pipeline and it will just build the code and push the image to the internal registry.

The pipeline interacts with API Connect using the APIC CLI in a Tekton task. To access the images for the APIC CLI, you need to follow the same steps to create the ibm-entitlement-key secret previously, but this time in the 'ibmoffices' namespace

For the ACE application, fork the repo [ace-hello-world-gitops](https://github.com/Nordic-MVP-GitOps-Repos/ace-hello-world-gitops), update the file [argocd/apps/ace-hello-world.yaml](argocd/apps/ace-hello-world.yaml) with your forked repo URL. Again, update kustomization.yaml to uncomment the line pointing to 'apps/ace-hello-world.yaml'. This enables the ACE application and creates a namespace 'ace-hello-world'. For the S2I build process to work, you need to create the ibm-entitlement-key secret in this namespace also. The ACE application is built using a pipeline. Start the pipeline and the application will get built and pushed to the internal registry.

### (Optional) Register DNS CNAME to enable generating certificates with LetsEncrypt

Instead of self-signed certificates we can use LetsEncrypt certificates generated using cert-manager. Common names can be a maximum of 64 characters, which is shorter than what many cloud providers openshift offerings use. To overcome that, we need to add a CNAME to our DNS. First, find your ingress subdomain:

`oc get ingresses.config/cluster -o jsonpath={.spec.domain}`
Depending on you cloud provider, this will give you something like 'mycluster-fra02-c3c-16x32-bcaeaf77ec409da3581f519c2c3bf303-0000.eu-de.containers.appdomain.cloud' for IBM ROKS or 
'apps.qnnof0ro.eastus.aroapp.io' for Azure ARO

With your DNS provider, register a new CNAME that you'll use for this installation. This will be of the form: 

your-cp4i.example.com --> mycluster-fra02-c3c-16x32-bcaeaf77ec409da3581f519c2c3bf303-0000.eu-de.containers.appdomain.cloud

When you generate certificates, the common name will be your-cp4i.example.com and you'll use <something>.mycluster-fra02-c3c-16x32-bcaeaf77ec409da3581f519c2c3bf303-0000.eu-de.containers.appdomain.cloud as DNS names.

### (Optional) Enable the LetsEncrypt issuer

In the file [components/platformnavigator/base/kustomization.yaml](components/platformnavigator/base/kustomization.yaml) uncomment the line referring to 'letsencrypt-clusterissuer.yaml'

If on OpenShift 4.10, you need to configure security context, see https://cert-manager.io/docs/release-notes/release-notes-1.10/

### (Optional) Use LetsEncrypt Certificates with MQ

Using the ingress subdomain from the previous step, update the dns name and common name in [mq-server-tls.yaml](components/mq/base/native-ha-qm-wellknowncerts/tls/mq-server-certificate.yaml). Now, update the [components/mq/base/kustomization.yaml](components/mq/base/kustomization.yaml) file and uncomment the lines referring to 'native-ha-qm-wellknowncerts'. Do the same in 'components/mq/variants/cloudprovider/<cloudprovider>/kustomization.yaml' and 'components/mq/variants/nonprod/kustomization.yaml'

### (Optional) Use LetsEncrypt Certificates with the Quarkus Java app

In the ibm-offices-gitops repo that you forked, update the file 'components/app/base/tls/letsencrypt-cert.yaml' with your CNAME and ingress values. Then, update the file 'components/app/base/kustomization.yaml' and uncomment the two lines referring to letsencrypt and comment the two lines referring to self-signed. Restart the deployment 'ibmoffice'. 

### (Optional) Use LetsEncrypt Certificates with the App Connect app

In the ace-hello-world-gitops repo that you forked, add a letsencrypt issuer and a certificate with your CNAME and ingress values in the folder 'components/app/base'. Then, update the file 'components/app/base/kustomization.yaml' and add these two files. Change the reference to 'secretName' in 'ace-helloworld-integrationserver.yaml' to what you named your new certificate

### (Optional) Use LetsEncrypt certificates and a custom hostname for Platform Navigator

https://www.ibm.com/docs/en/cloud-paks/cp-integration/2022.4?topic=certificates-using-custom-hostnames-platform-ui
