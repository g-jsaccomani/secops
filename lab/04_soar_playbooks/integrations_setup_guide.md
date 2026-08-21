# Guia de Configuração de Integrações no Content Hub - Google SecOps SOAR

Este documento descreve os passos e parâmetros para habilitar e autenticar os conectores de integração essenciais no **Chronicle SOAR Content Hub** para o ambiente Enterprise SOC.

---

## 1. Visão Geral do Content Hub

No Google SecOps SOAR, as integrações conectam playbooks a ferramentas de terceiros (EDR, Firewall, Threat Intel, IdP, Cloud IAM) para executar ações automatizadas e enriquecimento de dados.

---

## 2. Especificação dos Conectores Principais

### A. Conector VirusTotal v3 & Mandiant GTI

* **Nome no Content Hub:** `VirusTotal v3`
* **Finalidade:** Consulta de reputação de domínios, URLs, IPs e hashes em tempo real.
* **Tipo de Autenticação:** `API Key`

**Parâmetros de Configuração:**
| Parâmetro | Valor no Lab Enterprise SOC | Descrição |
| :--- | :--- | :--- |
| `API Key` | `Secret Manager: secops-virustotal-api-key` | Chave de API corporativa VirusTotal Enterprise |
| `Rate Limit per Min` | `240` | Limite de chamadas por minuto |
| `Enable Mandiant Fusion` | `true` | Habilita enriquecimento com Mandiant Threat Intelligence |
| `Verify SSL` | `true` | Validação estrita de certificados |

**Ações Habilitadas no Playbook:**
* `Get URL Report`
* `Get File Hash Report`
* `Get IP Reputation`

---

### B. Conector Google Cloud IAM & Resource Manager

* **Nome no Content Hub:** `Google Cloud Platform IAM`
* **Finalidade:** Remediação de permissões no GCP, revogação de chaves de Service Account e quarentena de instâncias Compute Engine.
* **Tipo de Autenticação:** `Service Account Key JSON` / `Workload Identity`

**Parâmetros de Configuração:**
| Parâmetro | Valor no Lab Enterprise SOC | Descrição |
| :--- | :--- | :--- |
| `Project ID` | `prj-secops-enterprise-lab` | Projeto SecOps Enterprise |
| `Service Account` | `sa-secops-ent-generic-secops-lab@prj-secops-enterprise-lab.iam.gserviceaccount.com` | Conta de serviço provisionada com papéis IAM |
| `Default Location` | `us-central1` | Região padrão para operações |

**Ações Habilitadas no Playbook:**
* `Disable Service Account Key`
* `Remove IAM Policy Binding`
* `Stop Compute Engine Instance`
* `Snapshot Persistent Disk (Forensics)`

---

### C. Conector Microsoft Entra ID (Azure Active Directory)

* **Nome no Content Hub:** `Microsoft Entra ID (Azure AD Graph/MS Graph)`
* **Finalidade:** Revogação de sessões ativas, redefinição de senhas forçada e bloqueio de usuários comprometidos.
* **Tipo de Autenticação:** `OAuth 2.0 Client Credentials`

**Parâmetros de Configuração:**
| Parâmetro | Valor no Lab Enterprise SOC | Descrição |
| :--- | :--- | :--- |
| `Tenant ID` | `Secret Manager: secops-entra-tenant-id` | ID do Tenant Azure AD da Enterprise SOC |
| `Client ID (App ID)` | `Secret Manager: secops-entra-client-id` | Application ID do App Registration |
| `Client Secret` | `Secret Manager: secops-entra-client-secret` | Chave secreta de autenticação do App |
| `API Scopes` | `https://graph.microsoft.com/.default` | Permissões MS Graph (`User.ReadWrite.All`, `Directory.ReadWrite.All`) |

**Ações Habilitadas no Playbook:**
* `Revoke User Sessions (Invalidate Refresh Tokens)`
* `Reset User Password`
* `Disable User Account`
* `Add User to Quarantined Group`

---

### D. Conector CrowdStrike Falcon EDR

* **Nome no Content Hub:** `CrowdStrike Falcon`
* **Finalidade:** Isolamento de rede do endpoint (Network Containment), coleta de evidências forenses (RTR) e bloqueio de hashes.
* **Tipo de Autenticação:** `OAuth 2.0 API Key & Secret`

**Parâmetros de Configuração:**
| Parâmetro | Valor no Lab Enterprise SOC | Descrição |
| :--- | :--- | :--- |
| `Client ID` | `Secret Manager: secops-crowdstrike-client-id` | Falcon API Client ID |
| `Client Secret` | `Secret Manager: secops-crowdstrike-secret` | Falcon API Secret |
| `Cloud Region` | `US-1` / `EU-1` (conforme tenant) | Base URL da nuvem CrowdStrike |
| `RTR Scripts Enabled` | `true` | Permite execução de scripts de resposta em tempo real |

**Ações Habilitadas no Playbook:**
* `Contain Host (Network Isolation)`
* `Lift Host Containment`
* `Upload Custom IOC Hash`
* `Execute Real-Time Response (RTR) Command`

---

### E. Conector Firewalls Next-Gen (Palo Alto PAN-OS & Fortinet FortiGate)

* **Nome no Content Hub:** `Palo Alto Networks PAN-OS` / `Fortinet FortiGate`
* **Finalidade:** Atualização em tempo real de Dynamic Address Groups (DAG) e Dynamic Blocklists de URLs/IPs.
* **Tipo de Autenticação:** `API Key / Admin Token`

**Parâmetros de Configuração:**
| Parâmetro | Valor no Lab Enterprise SOC | Descrição |
| :--- | :--- | :--- |
| `Management IP/FQDN` | `firewall.generic_secops.internal` | Endereço do appliance ou Panorama/FortiManager |
| `API Key / Token` | `Secret Manager: secops-firewall-token` | Token de autenticação administrativo com escopo restrito |
| `Verify SSL` | `true` | Requer certificado TLS válido |

**Ações Habilitadas no Playbook:**
* `Add IP to Dynamic Address Group`
* `Remove IP from Dynamic Address Group`
* `Add URL to Custom URL Category Blocklist`
* `Commit Configuration Changes`

---

## 3. Boas Práticas de Segurança e Gestão de Segredos

1. **Google Cloud Secret Manager:** Nunca insira senhas ou chaves em texto claro. Mantenha todas as credenciais no Secret Manager do projeto `prj-secops-enterprise-lab`.
2. **Princípio do Privilégio Mínimo:** Conceda aos conectores apenas as permissões estritamente necessárias para as ações de remediação definidas.
3. **Auditoria de Execução:** Todas as chamadas de conectores geram eventos auditáveis enviados automaticamente ao BigQuery Lake `ds_secops_enterprise_lake_generic_secops_lab`.
