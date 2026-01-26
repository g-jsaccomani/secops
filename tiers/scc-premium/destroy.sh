#!/usr/bin/env bash
# ==============================================================================
# Google Cloud SecOps - SCC Premium Tier Teardown Script
# ==============================================================================
# Author: Joabson Saccomani (@jsaccomani)
# Description: Destroys the resources created for SCC Premium Tier Foundation.
# ==============================================================================

set -euo pipefail
export PATH="/Users/jsaccomani/.local/bin:${PATH}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

echo -e "${BOLD}${RED}"
echo "=============================================================================="
echo "   ⚠️  DESTRUCTION NOTICE: SCC PREMIUM TIER FOUNDATION"
echo "=============================================================================="
echo -e "${NC}"

echo -e "${YELLOW}This operation will destroy the project, folder, BigQuery datasets, and Pub/Sub pipelines created by this module.${NC}"
read -p "Are you absolutely sure you want to proceed with teardown? Type 'destroy': " -r CONFIRM

if [ "${CONFIRM}" != "destroy" ]; then
  echo -e "${GREEN}Destruction aborted.${NC}"
  exit 0
fi

echo -e "\n${BLUE}[INFO]${NC} Destroying Terraform managed infrastructure..."
terraform destroy -auto-approve

echo -e "\n${GREEN}[SUCCESS] SCC Premium resources successfully destroyed.${NC}"
