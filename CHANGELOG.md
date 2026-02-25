# Changelog - secops

All notable changes and security updates recorded below.

### [2026-02-20] docs(ruleset): document MITRE ATT&CK mapping for Chronicle detection rules
- Mapped 35 custom YARA-L detection rules to MITRE ATT&CK tactics and techniques.

### [2026-02-22] lab(yara-l): create YARA-L rule for suspicious service account key creation
- Authored Chronicle YARA-L detection rule matching gcp.audit.adminService.createServiceAccountKey events.

### [2026-02-25] poc(soar-playbook): build automated containment playbook for compromised user account
- Created Chronicle SOAR playbook automating user credential revocation and session invalidation.

