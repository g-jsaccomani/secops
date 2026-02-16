#!/usr/bin/env bash
# ==============================================================================
# Google Cloud SecOps - Environment Pre-flight Validation
# ==============================================================================
# Author: Joabson Saccomani (@jsaccomani)
# Description: Checks prerequisites, gcloud authentication, permissions, and tools.
# ==============================================================================

set -euo pipefail
export PATH="/Users/jsaccomani/.local/bin:${PATH}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}${CYAN}"
echo "=============================================================================="
echo "   GOOGLE CLOUD SECOPS - PRE-FLIGHT ENVIRONMENT VALIDATION"
echo "=============================================================================="
echo -e "${NC}"

# Check CLI tools
echo -n "Checking gcloud CLI... "
if command -v gcloud >/dev/null 2>&1; then
  echo -e "${GREEN}INSTALLED ($(gcloud version --format='value(GoogleCloudSDK)' 2>/dev/null | head -n 1))${NC}"
else
  echo -e "${RED}MISSING${NC}"
  echo "Please install Google Cloud SDK: https://cloud.google.com/sdk/docs/install"
  exit 1
fi

echo -n "Checking terraform... "
if command -v terraform >/dev/null 2>&1; then
  echo -e "${GREEN}INSTALLED ($(terraform version -json 2>/dev/null | grep -o '"terraform_version":"[^"]*' | cut -d'"' -f4 || terraform version | head -n 1))${NC}"
else
  echo -e "${RED}MISSING${NC}"
  echo "Please install Terraform >= 1.5.0: https://developer.hashicorp.com/terraform/downloads"
  exit 1
fi

# Check Authentication
echo -n "Checking gcloud authentication... "
ACTIVE_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null || true)
if [ -n "${ACTIVE_ACCOUNT}" ]; then
  echo -e "${GREEN}AUTHENTICATED as ${BOLD}${ACTIVE_ACCOUNT}${NC}"
else
  echo -e "${RED}NOT AUTHENTICATED${NC}"
  echo "Run: gcloud auth login && gcloud auth application-default login"
  exit 1
fi

# Check Organizations
echo -n "Checking Accessible Organizations... "
ORGS=$(gcloud organizations list --format="value(name,displayName)" 2>/dev/null || true)
if [ -n "${ORGS}" ]; then
  echo -e "${GREEN}FOUND${NC}"
  echo "${ORGS}" | while read -r line; do echo "   - $line"; done
else
  echo -e "${YELLOW}None directly listable (may require Folder ID)${NC}"
fi

# Check Billing Accounts
echo -n "Checking Accessible Billing Accounts... "
BILLING=$(gcloud billing accounts list --format="value(name,displayName)" 2>/dev/null || true)
if [ -n "${BILLING}" ]; then
  echo -e "${GREEN}FOUND${NC}"
  echo "${BILLING}" | while read -r line; do echo "   - $line"; done
else
  echo -e "${YELLOW}None directly listable${NC}"
fi

echo -e "\n${BOLD}${GREEN}==============================================================================${NC}"
echo -e "${BOLD}${GREEN}   ✅ PRE-FLIGHT VALIDATION COMPLETE${NC}"
echo -e "${BOLD}${GREEN}==============================================================================${NC}"
