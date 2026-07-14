# Gemini in SecOps - Playbook Assistant Prompt Engineering Guide

Este guia contém templates de prompts de engenharia desenvolvidos especificamente para o **Gemini in SecOps (Playbook Assistant)** no Google SecOps SOAR.

---

## 1. Visão Geral do Gemini Playbook Assistant

O **Gemini in SecOps** integrado ao SOAR permite que analistas e engenheiros de detecção:
1. **Gerem novos playbooks** a partir de descrições em linguagem natural.
2. **Iterem e modifiquem** playbooks existentes (adicionar validações, steps manuais ou integrações).
3. **Simulem e depurem** o fluxo de execução com mock data antes de publicar em produção.
4. **Gerem resumos executivos** e relatórios pós-incidente em segundos.

---

## 2. Catálogo de Prompts Prontos por Caso de Uso

### Caso 1: Geração de Playbook de Phishing Automatizado

```text
Atue como um Engenheiro Sênior de Automação SOAR para a Enterprise SOC.
Crie um playbook de triagem e remediação automatizada para alertas de phishing de e-mail com a seguinte estrutura lógica:
1. Extraia remetente, URLs, domínios e hashes de anexos dos metadados do alerta.
2. Consulte a reputação dos artefatos na integração do VirusTotal v3 e Mandiant GTI.
3. Se 3 ou mais motores marcarem a URL ou Hash como malicioso:
   a) Remova o e-mail de todas as caixas postais corporativas (Google Workspace / Exchange).
   b) Adicione a URL ao Dynamic Blocklist do Firewall Palo Alto.
   c) Bloqueie o hash no CrowdStrike Falcon EDR.
   d) Envie um card no Google Chat notificando o usuário que o e-mail suspeito foi neutralizado.
4. Se o resultado for inconclusivo (1-2 detecções), atribua uma tarefa manual com timeout de 30 minutos para um analista do SOC L2.
5. Se for benigno, feche o caso automaticamente como False Positive.
6. Ao final, use o Gemini para redigir o resumo executivo do incidente em português e feche o caso.
```

---

### Caso 2: Geração de Playbook de Contenção de Host & Isolamento de Identidade

```text
Crie um playbook de contenção crítica para alertas de alta severidade (ex: Execução de Malware, Escalação de Privilégios no GCP ou Ransomware):
1. Identifique o hostname, IP interno e a identidade do usuário (UPN / Service Account).
2. Execute o isolamento de rede do endpoint usando o conector do CrowdStrike Falcon EDR (Network Containment).
3. Como redundância, insira o IP interno no Dynamic Address Group (DAG) de quarentena do Firewall Fortinet/Palo Alto.
4. Conecte no Microsoft Entra ID para invalidar todos os tokens de sessão ativos (Revoke Sign-in Sessions) e forçar a redefinição de senha.
5. Dispare um script forense de Real-Time Response (RTR) para coletar a árvore de processos e conexões ativas, salvando as evidências no bucket GCS "bkt-secops-ent-ingestion-prj-secops-enterprise-lab".
6. Poste um alerta urgente no canal do CSIRT com botões de aprovação para des-quarentenar a máquina.
```

---

### Caso 3: Iteração & Refinamento de Playbook Existente

```text
Analise o playbook atual de "Host Containment" e aplique as seguintes melhorias de resiliência:
1. Adicione um bloco de tratamento de erro (Error Handling / Fallback) caso o conector do CrowdStrike falhe por timeout na API.
2. Adicione uma verificação de 'VIP / Critical Assets' antes de isolar o host: se o host pertencer ao cluster de Produção ou for um Domain Controller, exija aprovação explícita do Gerente de Segurança via Slack/Teams antes de isolar a rede.
3. Inclua a tag "Enterprise SOC-Incident-Response" e atualize o SLA de resposta para 15 minutos.
```

---

### Caso 4: Simulação de Execução & Testes com Mock Data

```text
Simule a execução deste playbook de remediação de phishing utilizando o seguinte payload JSON de teste:
{
  "alert_name": "Suspicious Invoice Email",
  "sender": "finance-update@spoofed-domain-generic_secops.xyz",
  "recipient": "marcelo.silva@company.internal",
  "extracted_urls": ["http://malicious-credential-harvest-site.com/login.php"],
  "extracted_hashes": ["e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"],
  "virustotal_malicious_count": 14
}
Demonstre passo a passo quais ramos condicionais foram ativados, os parâmetros passados a cada integração e o relatório executivo gerado ao final.
```

---

### Caso 5: Geração de Relatório Pós-Incidente (Post-Mortem)

```text
Atue como o Assistente de IA de SecOps. Com base nas ações executadas neste caso de contenção de host, redija um Relatório Executivo de Resposta a Incidentes (Post-Mortem) contendo:
- Resumo Não-Técnico para Diretoria / C-Level.
- Linha do Tempo detalhada em UTC.
- Artefatos e Indicadores de Comprometimento (IoCs) identificados.
- Medidas de contenção e erradicação aplicadas.
- Recomendações de Lições Aprendidas para mitigar recorrências.
```

<!-- Checkpoint: 2026-03-20 - poc(soar-playbook): build automated containment playbook for compromised user account -->

<!-- Checkpoint: 2026-04-20 - poc(soar-playbook): build automated containment playbook for compromised user account -->

<!-- Checkpoint: 2026-07-14 - docs(ruleset): document MITRE ATT&CK mapping for Chronicle detection rules -->
