## Introduction
This repo can be used to install IBM Cloud Pak 4 Integration capabilities and sample applications

## Instructions

You should have an existing OpenShift cluster available. 

### Fork this repo and adapt it for your environment.

First, fork this repo. Now update the following files that refer to your repo url: 

* [bootstrap.yaml](./argocd/bootstrap.yaml) 
* [common.yaml](argocd/common.yaml)
* [all-operators](argocd/operators/all-operators.yaml)
* [all-operands.yaml](argocd/operands/all-operands.yaml) Here, also update with your environment, IBM Classic infrastructure (ibm-classic), IBM VPC infrastructure (ibm-vpc) and Azure (azure) are valid values

### Install the OpenShift GitOps operator

From OperatorHub, find the OpenShift GitOps operator and install it with the recommended defaults. For details, see https://docs.openshift.com/container-platform/4.12/cicd/gitops/installing-openshift-gitops.html

### (Optional) Add a webhook to the OpenShift GitOps server

Add a webhook to https://your-gitops-server.com/api/webhook for the push event. For details, see https://argo-cd.readthedocs.io/en/stable/operator-manual/webhook/

### Add the bootstrap ArgoCD application
In the OpenShift Console, click the "plus" icon and paste the contents of [bootstrap.yaml](./argocd/bootstrap.yaml) to create the bootstrap ArgoCD application. This application will find the [kustomization.yaml](./argocd/kustomization.yaml) file which points to the [common.yaml](./argocd/common.yaml)  application and two ArgoCD ApplicationSets:

[all-operators.yaml](./argocd/operators/all-operators.yaml)

The all-operators.yaml ApplicationSet generates ArgoCD applications for all operators based on a simple naming convention, pointing into the components subdirectory.

[all-operands.yaml](./argocd/operands/all-operands.yaml)

The all-operands.yaml ApplicationSet generates ArgoCD applications for Platforn Navigator, API Connect, OpenShift Logging and OpenShift Monitoring by default. This is a good starting point, since some of the other operands require DNS setup to correctly generate certificates. In later steps you can add operands for MQ and other capabilities.
