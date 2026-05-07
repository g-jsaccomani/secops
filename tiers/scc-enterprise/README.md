# Google Cloud SecOps - SCC Enterprise Tier Foundation

This module provisions the **Security Command Center (SCC) Enterprise Tier & Google SecOps (Chronicle SIEM & SOAR) Foundation**, establishing a unified cross-cloud security operations baseline, automated telemetry ingestion pipelines, BigQuery Security Lake, and real-time SOAR playbook trigger infrastructure.

---

## Architecture Overview

```mermaid
graph TD
    Parent["Parent Resource (Org or Folder)"] --> Folder["Folder: fldr-secops-enterprise-{env}"]
    Folder --> Project["Project: prj-secops-ent-{env}-{rand}"]
    Project --> APIs["APIs: securitycenter, chronicle, secops, bigquery, pubsub, dlp"]
    Project --> SA["Service Account: sa-secops-ent-{env}"]
    Project --> BQLake["BigQuery: ds_secops_enterprise_lake_{env}"]
    Project --> IngestTopic["Pub/Sub Ingestion: top-secops-ent-ingestion-{env}"]
    IngestTopic --> IngestSub["Subscription: sub-secops-ent-ingestion-{env}"]
    Project --> SoarTopic["Pub/Sub SOAR Triggers: top-secops-ent-soar-triggers-{env}"]
    SoarTopic --> SoarSub["Subscription: sub-secops-ent-soar-triggers-{env}"]
    Project --> IngestBucket["GCS Ingestion Bucket: bkt-secops-ent-ingestion-{rand}"]
```

---

## Provisioned Resources

| Resource | Type | Purpose |
| :--- | :--- | :--- |
| **SecOps Enterprise Folder** | `google_folder` | Dedicated organizational folder for Enterprise SecOps governance |
| **SecOps Enterprise Project** | `google_project` | Project container for Chronicle SIEM & SOAR unified operations |
| **Unified SecOps APIs** | `google_project_service` | Enables Security Center, Chronicle, SecOps, BigQuery, DLP, Pub/Sub |
| **Orchestration SA** | `google_service_account` | High-privilege service account for SOAR automation and feed ingestion |
| **Enterprise Security Lake** | `google_bigquery_dataset` | Enterprise Data Lake for multi-cloud telemetry, compliance, and custom detection |
| **Ingestion Pipeline** | `google_pubsub_topic` | High-throughput telemetry ingestion topic and subscription |
| **SOAR Trigger Pipeline** | `google_pubsub_topic` | Dedicated low-latency trigger pipeline for automated incident response playbooks |
| **Ingestion Bucket** | `google_storage_bucket` | Encrypted GCS bucket for log feeds, evidence, and raw artifacts |

---

## Quick Start

### 1. Configuration
Copy the template and adjust your organization/billing variables:
```bash
cp terraform.tfvars.example terraform.tfvars
```

### 2. Deploy
Run the automated deployment script:
```bash
chmod +x deploy.sh
./deploy.sh
```

### 3. Teardown
To safely remove all created resources:
```bash
chmod +x destroy.sh
./destroy.sh
```

<!-- Checkpoint: 2026-05-07 - docs(ruleset): document MITRE ATT&CK mapping for Chronicle detection rules -->
