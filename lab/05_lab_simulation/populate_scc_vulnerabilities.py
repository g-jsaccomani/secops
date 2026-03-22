#!/usr/bin/env python3
"""
Enterprise SOC Enterprise Security Lab - SCC Vulnerability & Finding Populator
Folder: fldr-functional-lab (YOUR_FOLDER_ID)
Projects:
  - prj-data-lake (ApexFin AI and Data)
  - prj-apps-prod (ApexFin Apps and APIs)
  - prj-sec-mgmt (ApexFin Security and Mgmt)

Populates Security Command Center Enterprise with realistic findings across:
  - CRITICAL, HIGH, MEDIUM, LOW severities
  - Cloud Storage, IAM, Compute Engine (STRICTLY PRIVATE / NO PUBLIC IP), KMS, BigQuery, VPC
  - CIS GCP Benchmark & MITRE ATT&CK mappings
"""

import datetime
import json
import os
import subprocess
import sys
import requests
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

ORG_ID = "YOUR_ORGANIZATION_ID"
QUOTA_PROJECT = "prj-secops-enterprise-lab"
CUSTOM_SOURCE_ID = "17414213218170864894"  # Security Health Analytics Custom
ETD_SOURCE_ID = "1734044172090245812"     # Event Threat Detection

PROJECT_AI_DATA = "prj-data-lake"
PROJECT_APPS = "prj-apps-prod"
PROJECT_SEC_MGMT = "prj-sec-mgmt"


def get_access_token():
    """Retrieves access token from environment or gcloud."""
    token = os.environ.get("ACCESS_TOKEN")
    if token:
        return token.strip()
    res = subprocess.run(["gcloud", "auth", "print-access-token"], capture_output=True, text=True, check=True)
    return res.stdout.strip()


def create_scc_finding(token, source_id, finding_id, payload):
    """Creates or updates a finding in SCC Enterprise via REST API v2."""
    post_url = f"https://securitycenter.googleapis.com/v2/organizations/{ORG_ID}/sources/{source_id}/locations/global/findings?findingId={finding_id}"
    patch_url = f"https://securitycenter.googleapis.com/v2/organizations/{ORG_ID}/sources/{source_id}/locations/global/findings/{finding_id}?updateMask=state,severity,description,eventTime,nextSteps,sourceProperties"
    headers = {
        "Authorization": f"Bearer {token}",
        "X-Goog-User-Project": QUOTA_PROJECT,
        "Content-Type": "application/json"
    }
    try:
        resp = requests.post(post_url, headers=headers, json=payload, timeout=15, verify=False)
        if resp.status_code in [200, 201]:
            data = resp.json()
            print(f"  [+] Created SCC Finding: {finding_id} ({payload.get('severity')}) -> {payload.get('category')}")
            return data
        elif resp.status_code == 409:
            # Update existing finding (remove immutable category)
            patch_payload = {k: v for k, v in payload.items() if k not in ["category", "resourceName"]}
            resp_patch = requests.patch(patch_url, headers=headers, json=patch_payload, timeout=15, verify=False)
            if resp_patch.status_code in [200, 201]:
                data = resp_patch.json()
                print(f"  [*] Updated Existing SCC Finding: {finding_id} ({payload.get('severity')}) -> {payload.get('category')}")
                return data
            else:
                print(f"  [-] Error updating finding {finding_id} (HTTP {resp_patch.status_code}): {resp_patch.text}", file=sys.stderr)
                return None
        else:
            print(f"  [-] Error creating finding {finding_id} (HTTP {resp.status_code}): {resp.text}", file=sys.stderr)
            return None
    except Exception as err:
        print(f"  [-] Exception creating finding {finding_id}: {err}", file=sys.stderr)
        return None


def main():
    print("=" * 80)
    print("🛡️  Populating Security Command Center Enterprise Findings for fldr-functional-lab")
    print(f"🏢 Organization ID: {ORG_ID} | Quota Project: {QUOTA_PROJECT}")
    print("🔒 Security Policy: Strict Private Network Only (No Public IPs)")
    print("=" * 80)

    token = get_access_token()
    now_iso = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    findings = [
        # --- PROJECT: prj-apps-prod ---
        {
            "id": "fnappkubeprivesc01",
            "source": CUSTOM_SOURCE_ID,
            "category": "CONTAINER_PRIVILEGE_ESCALATION",
            "severity": "CRITICAL",
            "finding_class": "MISCONFIGURATION",
            "resource": f"//container.googleapis.com/projects/{PROJECT_APPS}/locations/us-central1/clusters/gke-internal-apps/deployments/payment-processor",
            "description": "GKE Deployment 'payment-processor' allows container privilege escalation (allowPrivilegeEscalation=true) with SYS_ADMIN capabilities in internal VPC.",
            "next_steps": "Update deployment manifest and set securityContext.allowPrivilegeEscalation: false and drop CAP_SYS_ADMIN capabilities."
        },
        {
            "id": "fnappiamprimitive01",
            "source": CUSTOM_SOURCE_ID,
            "category": "PRIMITIVE_ROLES_USED",
            "severity": "CRITICAL",
            "finding_class": "MISCONFIGURATION",
            "resource": f"//cloudresourcemanager.googleapis.com/projects/{PROJECT_APPS}",
            "description": "Service Account 'sa-backend-deployer' has been granted primitive role 'roles/editor' at the project level, violating least privilege.",
            "next_steps": "Replace 'roles/editor' with fine-grained predefined IAM roles such as 'roles/compute.instanceAdmin.v1' and 'roles/storage.objectAdmin'."
        },
        {
            "id": "fnapposlogindisabled01",
            "source": CUSTOM_SOURCE_ID,
            "category": "OS_LOGIN_DISABLED",
            "severity": "HIGH",
            "finding_class": "MISCONFIGURATION",
            "resource": f"//compute.googleapis.com/projects/{PROJECT_APPS}/zones/us-central1-a/instances/vm-backend-core",
            "description": "Compute Engine instance 'vm-backend-core' (Private IP: 10.10.10.15, No Public IP) has OS Login disabled, allowing unmanaged SSH keys.",
            "next_steps": "Enable OS Login metadata: gcloud compute instances add-metadata vm-backend-core --metadata enable-oslogin=TRUE --project=" + PROJECT_APPS
        },
        {
            "id": "fnappvpcflownotenabled01",
            "source": CUSTOM_SOURCE_ID,
            "category": "VPC_FLOW_LOGS_DISABLED",
            "severity": "HIGH",
            "finding_class": "MISCONFIGURATION",
            "resource": f"//compute.googleapis.com/projects/{PROJECT_APPS}/regions/us-central1/subnetworks/subnet-apps-internal",
            "description": "Internal subnet 'subnet-apps-internal' (10.10.10.0/24) does not have VPC Flow Logs enabled, hindering network visibility and forensic tracing.",
            "next_steps": "Enable VPC Flow Logs on subnet-apps-internal with sampleRate=0.5 and aggregationInterval=INTERVAL_5_SEC."
        },
        {
            "id": "fnappshieldedvmdisabled01",
            "source": CUSTOM_SOURCE_ID,
            "category": "SHIELDED_VM_DISABLED",
            "severity": "MEDIUM",
            "finding_class": "MISCONFIGURATION",
            "resource": f"//compute.googleapis.com/projects/{PROJECT_APPS}/zones/us-central1-b/instances/vm-cache-redis",
            "description": "Compute Engine internal instance 'vm-cache-redis' (Private IP: 10.10.10.22) does not have Secure Boot and vTPM Shielded VM features enabled.",
            "next_steps": "Update instance shielded VM configuration: gcloud compute instances update vm-cache-redis --shielded-secure-boot --shielded-vtpm"
        },
        {
            "id": "fnappdefaultserviceacct01",
            "source": CUSTOM_SOURCE_ID,
            "category": "DEFAULT_SERVICE_ACCOUNT_USED",
            "severity": "MEDIUM",
            "finding_class": "MISCONFIGURATION",
            "resource": f"//compute.googleapis.com/projects/{PROJECT_APPS}/zones/us-central1-a/instances/vm-batch-worker",
            "description": "Internal instance 'vm-batch-worker' uses the default Compute Engine service account with cloud-platform scope.",
            "next_steps": "Create a dedicated custom service account with minimal IAM roles and attach it to the instance."
        },

        # --- PROJECT: prj-data-lake ---
        {
            "id": "fndatabqpermissive01",
            "source": CUSTOM_SOURCE_ID,
            "category": "BIGQUERY_DATASET_PERMISSIVE_ACCESS",
            "severity": "CRITICAL",
            "finding_class": "MISCONFIGURATION",
            "resource": f"//bigquery.googleapis.com/projects/{PROJECT_AI_DATA}/datasets/ds_financial_telemetry",
            "description": "BigQuery dataset 'ds_financial_telemetry' contains sensitive financial data and grants 'roles/bigquery.dataEditor' to all authenticated internal users.",
            "next_steps": "Audit dataset IAM permissions and restrict access strictly to authorized data engineering groups."
        },
        {
            "id": "fndatagcsunversioned01",
            "source": CUSTOM_SOURCE_ID,
            "category": "OBJECT_VERSIONING_DISABLED",
            "severity": "HIGH",
            "finding_class": "MISCONFIGURATION",
            "resource": f"//storage.googleapis.com/bkt-fnlab-datalake-unversioned-{PROJECT_AI_DATA}",
            "description": "Cloud Storage bucket 'bkt-fnlab-datalake-unversioned' does not have Object Versioning enabled, risking permanent data loss or tampering.",
            "next_steps": "Enable versioning on bucket: gcloud storage buckets update gs://bkt-fnlab-datalake-unversioned --versioning"
        },
        {
            "id": "fndatagcsunformaccess01",
            "source": CUSTOM_SOURCE_ID,
            "category": "BUCKET_POLICY_ONLY_DISABLED",
            "severity": "HIGH",
            "finding_class": "MISCONFIGURATION",
            "resource": f"//storage.googleapis.com/bkt-fnlab-raw-ml-models-{PROJECT_AI_DATA}",
            "description": "Cloud Storage bucket 'bkt-fnlab-raw-ml-models' has Uniform Bucket-Level Access disabled, allowing ACLs on individual objects.",
            "next_steps": "Enforce uniform bucket-level access: gcloud storage buckets update gs://bkt-fnlab-raw-ml-models --uniform-bucket-level-access"
        },
        {
            "id": "fndatanotebookrootaccess01",
            "source": CUSTOM_SOURCE_ID,
            "category": "VERTEX_NOTEBOOK_ROOT_ACCESS",
            "severity": "HIGH",
            "finding_class": "MISCONFIGURATION",
            "resource": f"//notebooks.googleapis.com/projects/{PROJECT_AI_DATA}/locations/us-central1-a/instances/nb-fraud-detection-model",
            "description": "Vertex AI Workbench instance 'nb-fraud-detection-model' runs with root access enabled without private service connect restrictions.",
            "next_steps": "Disable root access on the notebook and enforce VPC Service Controls perimeters."
        },
        {
            "id": "fndatabqtableexpiration01",
            "source": CUSTOM_SOURCE_ID,
            "category": "TABLE_EXPIRATION_DISABLED",
            "severity": "MEDIUM",
            "finding_class": "MISCONFIGURATION",
            "resource": f"//bigquery.googleapis.com/projects/{PROJECT_AI_DATA}/datasets/ds_temporary_scratchpad",
            "description": "BigQuery scratchpad dataset 'ds_temporary_scratchpad' does not enforce default partition/table expiration, causing unbounded retention.",
            "next_steps": "Set default table expiration on dataset: bq update --default_table_expiration 2592000 ds_temporary_scratchpad"
        },
        {
            "id": "fndatastoragelogging01",
            "source": CUSTOM_SOURCE_ID,
            "category": "STORAGE_LOGGING_DISABLED",
            "severity": "LOW",
            "finding_class": "MISCONFIGURATION",
            "resource": f"//storage.googleapis.com/bkt-fnlab-analytics-reports-{PROJECT_AI_DATA}",
            "description": "Cloud Storage bucket 'bkt-fnlab-analytics-reports' does not have access and storage telemetry logging configured.",
            "next_steps": "Configure log delivery bucket: gcloud storage buckets update gs://bkt-fnlab-analytics-reports --log-bucket=gs://bkt-audit-logs"
        },

        # --- PROJECT: prj-sec-mgmt ---
        {
            "id": "fnsecunrotatedkmskey01",
            "source": CUSTOM_SOURCE_ID,
            "category": "KMS_KEY_ROTATION_NOT_SCHEDULED",
            "severity": "CRITICAL",
            "finding_class": "MISCONFIGURATION",
            "resource": f"//cloudkms.googleapis.com/projects/{PROJECT_SEC_MGMT}/locations/us-central1/keyRings/kr-security-mgmt/cryptoKeys/key-root-database-encryption",
            "description": "Cloud KMS CryptoKey 'key-root-database-encryption' does not have an automated rotation period configured (CIS GCP Benchmark 1.10).",
            "next_steps": "Set automatic 90-day key rotation: gcloud kms keys set-rotation-schedule key-root-database-encryption --rotation-period=90d --next-rotation-time=2026-11-15T00:00:00Z"
        },
        {
            "id": "fnsecunmanagedsakey01",
            "source": CUSTOM_SOURCE_ID,
            "category": "USER_MANAGED_SERVICE_ACCOUNT_KEY",
            "severity": "HIGH",
            "finding_class": "MISCONFIGURATION",
            "resource": f"//iam.googleapis.com/projects/{PROJECT_SEC_MGMT}/serviceAccounts/sa-siem-forwarder@{PROJECT_SEC_MGMT}.iam.gserviceaccount.com",
            "description": "Service Account 'sa-siem-forwarder' has 3 user-managed private keys older than 180 days without Workload Identity Federation.",
            "next_steps": "Delete user-managed keys and migrate workloads to Workload Identity Federation or Short-lived OAuth tokens."
        },
        {
            "id": "fnseclogalertmetrics01",
            "source": CUSTOM_SOURCE_ID,
            "category": "LOG_METRIC_FILTER_MISSING",
            "severity": "HIGH",
            "finding_class": "MISCONFIGURATION",
            "resource": f"//logging.googleapis.com/projects/{PROJECT_SEC_MGMT}",
            "description": "Cloud Logging is missing log metric filters and alerting policies for IAM Policy changes and VPC Route changes (CIS GCP 2.4 / 2.5).",
            "next_steps": "Deploy Terraform module '04_compliance_posture' to provision required log metrics and Cloud Monitoring alert policies."
        },
        {
            "id": "fnseckmscryptokeypublic01",
            "source": CUSTOM_SOURCE_ID,
            "category": "KMS_PUBLIC_KEY_ACCESS",
            "severity": "MEDIUM",
            "finding_class": "MISCONFIGURATION",
            "resource": f"//cloudkms.googleapis.com/projects/{PROJECT_SEC_MGMT}/locations/us-central1/keyRings/kr-security-mgmt/cryptoKeys/key-backup-vault",
            "description": "Cloud KMS CryptoKey 'key-backup-vault' has broad IAM role 'roles/cloudkms.cryptoKeyEncrypter' granted across the organization domain.",
            "next_steps": "Restrict KMS encrypter permissions strictly to the automated backup service account."
        },
        {
            "id": "fnsecseriallogging01",
            "source": CUSTOM_SOURCE_ID,
            "category": "SERIAL_PORT_LOGGING_DISABLED",
            "severity": "LOW",
            "finding_class": "MISCONFIGURATION",
            "resource": f"//compute.googleapis.com/projects/{PROJECT_SEC_MGMT}/zones/us-central1-c/instances/vm-bastion-internal",
            "description": "Internal bastion VM 'vm-bastion-internal' (Private IP: 10.20.10.5, No Public IP) does not have serial port console logging enabled.",
            "next_steps": "Enable serial port logging metadata: gcloud compute instances add-metadata vm-bastion-internal --metadata serial-port-logging-enable=true"
        },

        # --- EVENT THREAT DETECTION / ATTACK SCENARIOS (fldr-functional-lab) ---
        {
            "id": "fnetdanomalousiam01",
            "source": CUSTOM_SOURCE_ID,
            "category": "ANOMALOUS_IAM_GRANT",
            "severity": "CRITICAL",
            "finding_class": "THREAT",
            "resource": f"//cloudresourcemanager.googleapis.com/projects/{PROJECT_APPS}",
            "description": "Event Threat Detection identified an anomalous SetIamPolicy action assigning 'roles/owner' to external contractor identity 'ext.rodrigo@contractors-corp.io'.",
            "next_steps": "Trigger SOAR Playbook 'PBA-001-COMPROMISED-ACCOUNT', revoke granted IAM role, and enforce MFA."
        },
        {
            "id": "fnetdpersistencesakey01",
            "source": CUSTOM_SOURCE_ID,
            "category": "PERSISTENCE_SERVICE_ACCOUNT_KEY_CREATION",
            "severity": "HIGH",
            "finding_class": "THREAT",
            "resource": f"//iam.googleapis.com/projects/{PROJECT_SEC_MGMT}/serviceAccounts/sa-siem-forwarder@{PROJECT_SEC_MGMT}.iam.gserviceaccount.com",
            "description": "Suspicious rapid creation of multiple service account keys outside standard deployment windows detected by ETD.",
            "next_steps": "Review Cloud Audit Logs for caller IP, invalidate newly created service account keys, and review principal authentication."
        },
        {
            "id": "fnetdbqexfiltration01",
            "source": CUSTOM_SOURCE_ID,
            "category": "DATA_EXFILTRATION_BIGQUERY_EXPORT",
            "severity": "HIGH",
            "finding_class": "THREAT",
            "resource": f"//bigquery.googleapis.com/projects/{PROJECT_AI_DATA}/datasets/ds_financial_telemetry",
            "description": "High-volume BigQuery table export detected to an external storage bucket outside the organizational perimeter.",
            "next_steps": "Quarantine the affected principal, enable VPC Service Controls perimeter egress blocks, and verify exported records."
        },
        {
            "id": "fnetdnetworkc2outbound01",
            "source": CUSTOM_SOURCE_ID,
            "category": "OUTBOUND_NETWORK_C2_CONNECTION",
            "severity": "CRITICAL",
            "finding_class": "THREAT",
            "resource": f"//compute.googleapis.com/projects/{PROJECT_APPS}/zones/us-central1-a/instances/vm-backend-core",
            "description": "VPC Flow telemetry and Threat Intel matched outbound TLS connection to known CobaltStrike C2 IP (185.220.101.5:443) from internal instance.",
            "next_steps": "Execute automated SOAR isolation playbook 'PBA-002-HOST-ISOLATION' to apply network quarantine tags."
        }
    ]

    success_count = 0
    for f in findings:
        payload = {
            "state": "ACTIVE",
            "category": f["category"],
            "resourceName": f["resource"],
            "severity": f["severity"],
            "findingClass": f["finding_class"],
            "description": f["description"],
            "eventTime": now_iso,
            "nextSteps": f["next_steps"],
            "sourceProperties": {
                "environment": "generic-secops-lab",
                "folder": "fldr-functional-lab (YOUR_FOLDER_ID)",
                "network_exposure": "STRICTLY_INTERNAL_NO_PUBLIC_IP",
                "compliance_frameworks": "CIS GCP 2.0, NIST CSF, ISO 27001"
            }
        }
        res = create_scc_finding(token, f["source"], f["id"], payload)
        if res:
            success_count += 1

    print("\n" + "=" * 80)
    print(f"✅ Successfully registered {success_count}/{len(findings)} findings in Security Command Center Enterprise!")
    print(f"📊 Breakdown:")
    print(f"   - CRITICAL: {sum(1 for f in findings if f['severity'] == 'CRITICAL')}")
    print(f"   - HIGH:     {sum(1 for f in findings if f['severity'] == 'HIGH')}")
    print(f"   - MEDIUM:   {sum(1 for f in findings if f['severity'] == 'MEDIUM')}")
    print(f"   - LOW:      {sum(1 for f in findings if f['severity'] == 'LOW')}")
    print("=" * 80)


if __name__ == "__main__":
    main()

# Audit checkpoint [2026-02-26]: feat(udm-mapping): add UDM parser mapping for custom firewall syslog format

# Audit checkpoint [2026-03-22]: feat(udm-mapping): add UDM parser mapping for custom firewall syslog format
