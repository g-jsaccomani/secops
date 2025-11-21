# Google Cloud SecOps Enterprise Lab Blueprint

[![Status](https://img.shields.io/badge/Status-Active-success.svg)](README.md)
[![Environment](https://img.shields.io/badge/Environment-enterprise--lab-orange.svg)](README.md)
[![Security Level](https://img.shields.io/badge/Security-SCC%20Enterprise-blue.svg)](README.md)

**Workload:** Enterprise Cloud Security Operations & Threat Detection Lab
**Author:** Joabson Saccomani ([@jsaccomani](https://github.com/g-jsaccomani))
**Role:** Cloud Security Consultant
*Copyright © 2026 Google LLC / Joabson Saccomani. All rights reserved.*

---

## Objetivo do Laboratório

O **SecOps Enterprise Lab** foi projetado para simular, validar e implementar o ciclo de vida completo de operações de segurança moderna no **Google Cloud SecOps** (Chronicle SIEM, Chronicle SOAR e Security Command Center Enterprise), cobrindo:

1. **Infraestrutura e Identidade Segura**: Provisionamento de pastas, projetos, service accounts e permissões granulares de SIEM/SOAR.
2. **Ingestão e Normalização UDM**: Coleta multi-cloud de telemetria via Pub/Sub com mapeamento para o modelo UDM.
3. **Engenharia de Detecção (YARA-L 2.0)**: Regras analíticas de alta fidelidade para identidade, movimentação lateral e ataques à nuvem.
4. **Automação de Resposta a Incidentes (SOAR)**: Playbooks com IA assistida (Gemini SecOps Assistant) para contenção automática.

---

## Topologia Arquitetural

```mermaid
flowchart TD
    Org[" Google Cloud Organization"] --> Fldr[" Folder: fldr-secops-enterprise"]

    subgraph SecOps Project
        Fldr --> Prj[" Project: prj-secops-enterprise-lab"]
        Prj --> SA[" Service Account: sa-secops-ent-lab@..."]
        Prj --> IngestTop[" Pub/Sub Ingestion: top-secops-ent-ingestion-lab"]
        Prj --> SOARTop[" Pub/Sub SOAR: top-secops-ent-soar-triggers-lab"]
        Prj --> BQLake[" BigQuery Lake: ds_secops_enterprise_lake_lab"]
    end

    subgraph Data Flow
        IngestTop --> IngestSub["Subscription: sub-secops-ent-ingestion-lab"]
        SOARTop --> SOARSub["Subscription: sub-secops-ent-soar-triggers-lab"]
    end
```

---

## Recursos e Parâmetros de Referência

| Recurso | ID / Identificador Padrão | Descrição |
| :--- | :--- | :--- |
| **Projeto Lab** | `prj-secops-enterprise-lab` | Projeto central isolado para as operações de SecOps |
| **Folder Pai** | `folders/123456789012` | Pasta organizacional (`fldr-secops-enterprise`) |
| **Região Principal** | `us-central1` | Localização primária dos recursos analíticos |
| **Pub/Sub Ingestion** | `top-secops-ent-ingestion-lab` | Tópico de alta taxa para ingestão de telemetria multi-cloud |
| **Pub/Sub SOAR Triggers** | `top-secops-ent-soar-triggers-lab` | Pipeline de baixa latência para disparo de playbooks de resposta |
| **BigQuery Security Lake** | `ds_secops_enterprise_lake_lab` | Dataset analítico para consultas UDM, auditoria e dashboards |
| **Service Account** | `sa-secops-ent-lab@prj-secops-enterprise-lab.iam.gserviceaccount.com` | Conta de serviço operacional com papéis de SecOps, Pub/Sub e BigQuery |
