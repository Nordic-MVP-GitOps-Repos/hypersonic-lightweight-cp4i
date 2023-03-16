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

The all-operands.yaml ApplicationSet generates ArgoCD applications for Platform Navigator, API Connect, MQ (a sample queue manager), OpenShift Logging and OpenShift Monitoring by default. 

If you have enabled the webhook earlier, ArgoCD will refresh and trigger install of the capabilities. If you didn't, open ArgoCD and refresh the bootstrap application in the UI. This happens automatically after 3 minutes. 

The install takes somewhere between 30-60 minutes depending on the cluster resources. 

### Create index patterns for OpenShift Logging

Click the Logging menu item in the OpenShift Console. In the Kibana interface, create two index patterns: 'app' and 'infra' that map to '@timestamp'

### Enable sample applications

Two sample applications are available: 

* A Quarkus Java app implementing a REST endpoint which can be exposed in API Connect
* A App Connect Enterprise application with two message flows

The sample applications are used to illustrate how automating build and deploy can be done and as such are very simplistic. Each sample app has two repos, one that contains the actual code and one that contains the GitOps config for it. If you just want to try out the applications, fork only the GitOps repos.

For the Java application, fork the repo [ibm-offices-gitops](https://github.com/Nordic-MVP-GitOps-Repos/ibm-offices-gitops). Then, in this repo (not the ibm-offices-gitops one), update the file [apps/ibm-offices.yaml](apps/ibm-offices.yaml) to point to your forked repository. Finally, update the file [argocd/kustomization.yaml](argocd/kustomization.yaml) and uncomment the line pointing to [apps/ibm-offices.yaml](apps/ibm-offices.yaml). You have now added the sample application.

The sample application gets built using a pipeline, which also publishes the API to API Connect. You will need to setup API Connect provider organisations for this to work, but you can run the pipeline and it will just build the code and push the image to the internal registry.

The pipeline interacts with API Connect using the APIC CLI in a Tekton task. To access the images for the APIC CLI, you need to follow the same steps to create the ibm-entitlement-key secret previously, but this time in the 'ibmoffices' namespace

### (Optional) Register DNS CNAME to enable generating certificates with LetsEncrypt

Instead of self-signed certificates we can use LetsEncrypt certificates generated using cert-manager. Common names can be a maximum of 64 characters, which is shorter than what many cloud providers openshift offerings use. To overcome that, we need to add a CNAME to our DNS. First, find your ingress subdomain:

`oc get ingresses.config/cluster -o jsonpath={.spec.domain}`
Depending on you cloud provuder, this will give you something like 'mycluster-fra02-c3c-16x32-bcaeaf77ec409da3581f519c2c3bf303-0000.eu-de.containers.appdomain.cloud'

With your DNS provider, register a new CNAME that you'll use for this installation. This will be of the form: 

your-cp4i.example.com --> mycluster-fra02-c3c-16x32-bcaeaf77ec409da3581f519c2c3bf303-0000.eu-de.containers.appdomain.cloud

When you generate certificates, the common name will be your-cp4i.example.com and you'll use mycluster-fra02-c3c-16x32-bcaeaf77ec409da3581f519c2c3bf303-0000.eu-de.containers.appdomain.cloud as DNS names.

If you'd rather use self-signed certificates, this also works. TBW: files to update.

### Enable MQ sample queue manager

Using the ingress subdomain from the previous step, update the dns name and common name in [mq-server-tls.yaml](components/mq/base/tls/mq-server-tls.yaml). Now, update the [all-operands.yaml](argocd/operands/all-operands.yaml) file and uncomment the three lines referring to MQ.

### Change certificates and hostname for Platform Navigator

