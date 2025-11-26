# Enterprise SecOps Reference Architecture & Lab Environment

A generic, sanitized blueprint for implementing and validating **Google SecOps (Chronicle SIEM & SOAR)** and **Security Command Center (SCC) Enterprise**.

---

## Structure Overview

```text
LAB/
 01_infra_iam/           # Terraform & IAM definitions for log routing & storage
 02_ingestion_udm/       # UDM mapping models & multi-source telemetry configs
 03_detections_yaral/    # Curated YARA-L 2.0 multi-event correlation rules
 04_soar_playbooks/      # Automated Incident Response (IR) Playbooks & Connectors
 05_lab_simulation/      # Synthetic telemetry generator & SCC vulnerability populator
```

---

## Getting Started

1. **Configure Environment Variables**:
   ```bash
   export ORGANIZATION_ID="YOUR_ORGANIZATION_ID"
   export PROJECT_ID="prj-secops-enterprise-lab"
   ```

2. **Ingestion & UDM Modeling**:
   Review [`02_ingestion_udm/udm_mapping_reference.md`](02_ingestion_udm/udm_mapping_reference.md) for data schema guidelines.

3. **Deploy YARA-L Correlation Rules**:
   Import detection rules from [`03_detections_yaral/`](03_detections_yaral/) into Chronicle SIEM.

4. **Automate Response with SOAR**:
   Configure playbooks from [`04_soar_playbooks/`](04_soar_playbooks/) for automatic host isolation and identity remediation.

5. **Simulate & Validate**:
   Run the simulation toolkit in [`05_lab_simulation/`](05_lab_simulation/) to test detection and response workflows.
