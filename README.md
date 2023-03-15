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

In the OpenShift Console, click the "plus" icon and paste the contents of [bootstrap.yaml](./argocd/bootstrap.yaml) to create the bootstrap ArgoCD application. This application will find the [kustomization.yaml](./argocd/kustomization.yaml) file which points to the [common.yaml](./argocd/common.yaml)  application and an ArgoCD ApplicationSets [all-operators.yaml](./argocd/operators/all-operators.yaml)

The "common" application creates a namespace (cp4i by default) and a catalogsource for the IBM operators. 

The all-operators.yaml ApplicationSet generates ArgoCD applications for all operators based on a simple naming convention, pointing into the components subdirectory where Subscriptions for each operator can be found.

After applying the bootstrap file, the operators will be installed. By default, these are installed in the openshift-operators namespace. You can check the status in the OpenShift Console under Operators / Installed Operators.

### Add the IBM entitlement key to access the container registry

Create an image pull secret in the 'cp4i' namespace with the name ibm-entitlement-key, address cp.icr.io, username cp and you entitlement key as password.

### Install operands / capabilities

Now, uncomment the line referring to 'operands/all-operands.yaml' in [kustomization.yaml](./argocd/kustomization.yaml)

The all-operands.yaml ApplicationSet generates ArgoCD applications for Platforn Navigator, API Connect, OpenShift Logging and OpenShift Monitoring by default. This is a good starting point, since some of the other capabilities require DNS setup to correctly generate certificates. In later steps you can add these capabilities. 

If you have enabled the webhook earlier, ArgoCD will refresh and trigger install of the capabilities. If you didn't, open ArgoCD and refresh the bootstrap application in the UI. This happens automatically after 3 minutes. 

The install takes somewhere between 30-60 minutes depending on the cluster resources. 

### 
