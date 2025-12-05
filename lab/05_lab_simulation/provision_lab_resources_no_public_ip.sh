#!/usr/bin/env bash
# ==============================================================================
# Provision Real Lab Resources with Misconfigurations in fldr-functional-lab
# STRICTLY NO PUBLIC IP / PRIVATE INTERNAL ONLY
# ==============================================================================
set -e

PROJECT_APPS="prj-apps-prod"
PROJECT_DATA="prj-data-lake"
PROJECT_MGMT="prj-sec-mgmt"
REGION="us-central1"
ZONE="us-central1-a"

echo "=============================================================================="
echo "🚀 Provisioning Real GCP Lab Misconfigured Resources in fldr-functional-lab"
echo "🔒 Policy: Strictly Private (No External/Public IPs)"
echo "=============================================================================="

# ------------------------------------------------------------------------------
# 1. PROJECT: prj-apps-prod (VPC, Private Subnet, Private VM, IAM Service Account)
# ------------------------------------------------------------------------------
echo -e "\n[+] Setting up resources in $PROJECT_APPS..."

# Create Service Account & Primitive Role
gcloud iam service-accounts create sa-backend-deployer \
  --display-name="Backend Application Deployer" \
  --project="$PROJECT_APPS" 2>/dev/null || true

gcloud projects add-iam-policy-binding "$PROJECT_APPS" \
  --member="serviceAccount:sa-backend-deployer@$PROJECT_APPS.iam.gserviceaccount.com" \
  --role="roles/editor" --condition=None 2>/dev/null || true

# Create User-Managed Service Account Key
gcloud iam service-accounts keys create /tmp/sa-backend-deployer-key.json \
  --iam-account="sa-backend-deployer@$PROJECT_APPS.iam.gserviceaccount.com" \
  --project="$PROJECT_APPS" 2>/dev/null || true
rm -f /tmp/sa-backend-deployer-key.json

# Create Custom VPC without auto-subnets
gcloud compute networks create vpc-fnlab-apps-internal \
  --subnet-mode=custom \
  --project="$PROJECT_APPS" 2>/dev/null || true

# Create Internal Subnet without VPC Flow Logs
gcloud compute networks subnets create subnet-apps-internal \
  --network=vpc-fnlab-apps-internal \
  --range=10.10.10.0/24 \
  --region="$REGION" \
  --no-enable-flow-logs \
  --project="$PROJECT_APPS" 2>/dev/null || true

# Create Strictly Private Compute Instance (NO PUBLIC IP, OS Login False, Shielded VM False)
gcloud compute instances create vm-backend-core \
  --zone="$ZONE" \
  --machine-type=e2-micro \
  --network=vpc-fnlab-apps-internal \
  --subnet=subnet-apps-internal \
  --no-address \
  --metadata=enable-oslogin=FALSE \
  --no-shielded-secure-boot \
  --no-shielded-vtpm \
  --no-shielded-integrity-monitoring \
  --can-ip-forward \
  --tags=backend-internal \
  --project="$PROJECT_APPS" 2>/dev/null || true

# ------------------------------------------------------------------------------
# 2. PROJECT: prj-data-lake (GCS Buckets, BigQuery Datasets)
# ------------------------------------------------------------------------------
echo -e "\n[+] Setting up resources in $PROJECT_DATA..."

# GCS Buckets with UBLA disabled and Unversioned
gcloud storage buckets create "gs://bkt-fnlab-datalake-unversioned-$PROJECT_DATA" \
  --location="$REGION" \
  --no-uniform-bucket-level-access \
  --project="$PROJECT_DATA" 2>/dev/null || true

gcloud storage buckets create "gs://bkt-fnlab-raw-ml-models-$PROJECT_DATA" \
  --location="$REGION" \
  --no-uniform-bucket-level-access \
  --project="$PROJECT_DATA" 2>/dev/null || true

# BigQuery Datasets without default table expiration
bq mk --dataset --project_id="$PROJECT_DATA" --location="$REGION" "$PROJECT_DATA:ds_financial_telemetry" 2>/dev/null || true
bq mk --dataset --project_id="$PROJECT_DATA" --location="$REGION" "$PROJECT_DATA:ds_temporary_scratchpad" 2>/dev/null || true

# ------------------------------------------------------------------------------
# 3. PROJECT: prj-sec-mgmt (Cloud KMS KeyRing & Unrotated CryptoKey)
# ------------------------------------------------------------------------------
echo -e "\n[+] Setting up resources in $PROJECT_MGMT..."

# Cloud KMS KeyRing & CryptoKey without 90-day automatic rotation schedule
gcloud kms keyrings create kr-security-mgmt \
  --location="$REGION" \
  --project="$PROJECT_MGMT" 2>/dev/null || true

gcloud kms keys create key-root-database-encryption \
  --keyring=kr-security-mgmt \
  --location="$REGION" \
  --purpose=encryption \
  --project="$PROJECT_MGMT" 2>/dev/null || true

# Service Account with user-managed keys
gcloud iam service-accounts create sa-siem-forwarder \
  --display-name="SIEM Ingestion Forwarder" \
  --project="$PROJECT_MGMT" 2>/dev/null || true

gcloud iam service-accounts keys create /tmp/sa-siem-forwarder-key.json \
  --iam-account="sa-siem-forwarder@$PROJECT_MGMT.iam.gserviceaccount.com" \
  --project="$PROJECT_MGMT" 2>/dev/null || true
rm -f /tmp/sa-siem-forwarder-key.json

echo -e "\n=============================================================================="
echo "✅ Lab Infrastructure Provisioning Completed Successfully (All Private)!"
echo "=============================================================================="
