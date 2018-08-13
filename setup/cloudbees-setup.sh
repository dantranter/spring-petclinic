#!/bin/sh

set -e

# This script will create the appropriate secrets needed for the Jenkins Kubernetes plugin.
# https://github.com/jenkinsci/kubernetes-plugin

. configuration

# Create service account. This service account will be used to push images to GCR and deploy the application
gcloud iam service-accounts create cloudbees-svc-acct \
  --display-name "CloudBees Service Account"

SERVICE_ACCOUNT="cloudbees-svc-acct@$CLOUDBEES_PROJECT_ID.iam.gserviceaccount.com"

gcloud projects add-iam-policy-binding $DEPLOY_PROJECT_ID \
  --member serviceAccount:$SERVICE_ACCOUNT --role roles/storage.objectCreator

gcloud iam service-accounts keys create /tmp/cloudbees-svc-acct.json \
  --iam-account ${SERVICE_ACCOUNT}

if [ ! -f /tmp/$ATTESTOR_ID.key ]; then
  gpg --export-secret-key -a $ATTESTOR_NAME > /tmp/$ATTESTOR_ID.key
fi

# Set context for kubectl to the cluster and project where the Jenkins Pipeline will run 
gcloud container clusters get-credentials $CLOUDBEES_CLUSTER \
  --project $CLOUDBEES_PROJECT_ID --no-user-output-enabled

# Add Kubernetes secrets that contain the service account id and private signing key that can be used from Jenkins Pipeline
kubectl create secret generic cloudbees-svc-acct-secret --from-file=/tmp/cloudbees-svc-acct.json -n $CLOUDBEES_NAMESPACE
kubectl create secret generic attestor-secret --from-file=/tmp/$ATTESTOR_ID.key

