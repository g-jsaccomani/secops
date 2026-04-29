# Guia de Mapeamento UDM (Unified Data Model) - SecOps Enterprise SOC

Este documento estabelece a referência técnica para normalização de logs brutos no formato **UDM (Unified Data Model)** do Google SecOps (Chronicle SIEM).

---

## 1. Princípios de Normalização UDM

No Google SecOps, todo log normalizado obedece à estrutura de entidades fundamentais:
* **`metadata`**: Metadados do evento (tipo, timestamp, produto, vendor, log_type).
* **`principal`**: O autor/iniciador da ação (usuário, processo, IP de origem, máquina).
* **`target`**: O destino/alvo da ação (recurso modificado, IP de destino, servidor, arquivo).
* **`security_result`**: Resultado da avaliação de segurança (ação tomada, severidade, categoria, regra).
* **`network`**: Detalhes de transporte e conexão de rede (portas, protocolos, direção, bytes).
* **`about`**: Entidades adicionais de contexto (contas secundárias, certificados, threads).

---

## 2. Matriz de Mapeamento por Fonte de Logs

### A. GCP Cloud Audit Logs (`GCP_CLOUDAUDIT`)

| Campo no Log Bruto (GCP Audit) | Campo UDM Normalizado | Tipo de Dado | Descrição |
| :--- | :--- | :--- | :--- |
| `protoPayload.methodName` | `metadata.product_event_type` | string | Método da API chamado (ex: `v1.compute.instances.insert`) |
| *Calculado por regra CBN* | `metadata.event_type` | enum | `USER_UNCATEGORIZED`, `ADMIN_MUTATION`, etc. |
| `protoPayload.authenticationInfo.principalEmail` | `principal.user.userid` | string | E-mail do usuário ou Service Account que executou a ação |
| `protoPayload.callerIp` | `principal.ip` | string | IP do originador da chamada |
| `protoPayload.callerSuppliedUserAgent` | `network.http.user_agent` | string | User-Agent utilizado no client |
| `protoPayload.resourceName` | `target.resource.name` | string | URI do recurso GCP acessado/modificado |
| `protoPayload.serviceName` | `target.resource.product` | string | Serviço GCP (ex: `compute.googleapis.com`) |
| `protoPayload.status.code` | `security_result.action` | enum | `0`  `ALLOW`, `!= 0`  `BLOCK` / `ERROR` |
| `timestamp` | `metadata.event_timestamp` | timestamp | Timestamp UTC do evento |

---

### B. GCP VPC Flow Logs (`GCP_VPC_FLOW`)

| Campo no Log Bruto (VPC Flow) | Campo UDM Normalizado | Tipo de Dado | Descrição |
| :--- | :--- | :--- | :--- |
| *Constante CBN* | `metadata.event_type` | enum | `NETWORK_CONNECTION` |
| `jsonPayload.src_ip` | `principal.ip` | string | IP de origem do pacote |
| `jsonPayload.src_port` | `principal.port` | integer | Porta de origem TCP/UDP |
| `jsonPayload.dest_ip` | `target.ip` | string | IP de destino do pacote |
| `jsonPayload.dest_port` | `target.port` | integer | Porta de destino TCP/UDP |
| `jsonPayload.protocol` | `network.ip_protocol` | string | Protocolo IP (ex: `TCP`, `UDP`, `ICMP`) |
| `jsonPayload.bytes_sent` | `network.sent_bytes` | integer | Bytes transmitidos na conexão |
| `jsonPayload.packets_sent` | `network.sent_packets` | integer | Pacotes transmitidos na conexão |
| `jsonPayload.reporter` | `network.direction` | enum | `SRC`  `OUTBOUND`, `DEST`  `INBOUND` |

---

### C. Microsoft Entra ID / Azure AD (`AZURE_AD`)

| Campo no Log Bruto (Entra ID) | Campo UDM Normalizado | Tipo de Dado | Descrição |
| :--- | :--- | :--- | :--- |
| `operationName` | `metadata.product_event_type` | string | Ex: `Sign-in activity`, `Add user` |
| `identity` / `userPrincipalName` | `principal.user.userid` | string | UPN do usuário (ex: `usuario@company.internal`) |
| `userId` | `principal.user.windows_sid` | string | Object ID do Azure AD |
| `ipAddress` | `principal.ip` | string | Endereço IP do cliente |
| `location.city` / `countryOrRegion` | `principal.location.city` / `country_or_region` | string | Geolocalização do login |
| `appDisplayName` | `target.application` | string | Aplicação acessada (ex: `Office 365`, `Azure Portal`) |
| `status.errorCode` | `security_result.action` | enum | `0`  `ALLOW`, `!= 0`  `BLOCK` |
| `status.failureReason` | `security_result.summary` | string | Motivo de erro (ex: `Invalid credentials`, `MFA Failed`) |
| *Calculado por regra CBN* | `metadata.event_type` | enum | `USER_LOGIN` |

---

### D. CrowdStrike Falcon EDR (`CROWDSTRIKE_EDR`)

| Campo no Log Bruto (CrowdStrike) | Campo UDM Normalizado | Tipo de Dado | Descrição |
| :--- | :--- | :--- | :--- |
| `event.EventName` | `metadata.product_event_type` | string | Ex: `ProcessRollup2`, `DetectionSummaryEvent` |
| `event.ComputerName` | `principal.hostname` | string | Nome do endpoint / workstation |
| `event.UserName` | `principal.user.userid` | string | Usuário autenticado no host |
| `event.FileName` | `principal.process.file.name` | string | Nome do executável do processo |
| `event.CommandLine` | `principal.process.command_line` | string | Linha de comando completa |
| `event.SHA256HashData` | `principal.process.file.sha256` | string | Hash SHA-256 do binário |
| `event.LocalAddressIP4` | `principal.ip` | string | IP local da interface |
| `event.RemoteAddressIP4` | `target.ip` | string | IP de destino da conexão de rede |
| `event.RemotePort` | `target.port` | integer | Porta remota acessada |
| *Calculado por regra CBN* | `metadata.event_type` | enum | `PROCESS_LAUNCH`, `NETWORK_CONNECTION`, etc. |

---

### E. Next-Gen Firewall - Palo Alto & Fortinet (`PAN_FIREWALL` / `FORTINET_FORTIGATE`)

| Campo no Log Bruto (Firewall) | Campo UDM Normalizado | Tipo de Dado | Descrição |
| :--- | :--- | :--- | :--- |
| `action` (allow/permit/drop/deny/reset) | `security_result.action` | enum | `ALLOW`, `BLOCK`, `DROP` |
| `src` / `srcip` | `principal.ip` | string | Endereço IP de origem |
| `srcport` / `sport` | `principal.port` | integer | Porta de origem |
| `dst` / `dstip` | `target.ip` | string | Endereço IP de destino |
| `dstport` / `dport` | `target.port` | integer | Porta de destino |
| `proto` | `network.ip_protocol` | string | Protocolo L4 (TCP/UDP) |
| `app` / `application` | `network.application_protocol` | string | Aplicação identificada por App-ID |
| `sentbyte` / `bytes_sent` | `network.sent_bytes` | integer | Volume enviado |
| `rcvdbyte` / `bytes_received` | `network.received_bytes` | integer | Volume recebido |
| `threat_name` / `attack` | `security_result.threat_name` | string | Assinatura de IPS / Antivírus detectada |
| `severity` / `level` | `security_result.severity` | enum | `LOW`, `MEDIUM`, `HIGH`, `CRITICAL` |

---

## 3. Validação dos Campos Chave para YARA-L 2.0

Os campos mapeados acima alimentam diretamente as variáveis de correlação nas regras de detecção YARA-L 2.0:

```yara
rule generic_secops_suspicious_cross_platform_activity {
  meta:
    author = "Joabson Saccomani"
    description = "Correlaciona falhas no Entra ID com conexoes bloqueadas no Firewall e processos no EDR"
    severity = "HIGH"

  events:
    // 1. Falha de login no Entra ID
    $login.metadata.event_type = "USER_LOGIN"
    $login.security_result.action = "BLOCK"
    $login.principal.user.userid = $user
    $login.principal.ip = $src_ip

    // 2. Conexão bloqueada no Firewall no mesmo IP
    $fw.metadata.event_type = "NETWORK_CONNECTION"
    $fw.security_result.action = "BLOCK"
    $fw.principal.ip = $src_ip

  match:
    $user over 10m

  condition:
    #login >= 3 and $fw
}
```

<!-- Checkpoint: 2026-02-25 - poc(soar-playbook): build automated containment playbook for compromised user account -->

<!-- Checkpoint: 2026-04-29 - docs(ruleset): document MITRE ATT&CK mapping for Chronicle detection rules -->
