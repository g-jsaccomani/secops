#!/usr/bin/env bash
# ==============================================================================
# Google Cloud SecOps - Destroy All Tiers Foundation (Standard, Premium, Enterprise)
# ==============================================================================
# Author: Joabson Saccomani (@jsaccomani)
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

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo -e "${BOLD}${RED}"
echo "=============================================================================="
echo "   ⚠️  BATCH TEARDOWN: ALL 3 SECOPS TIERS"
echo "=============================================================================="
echo -e "${NC}"

echo -e "${YELLOW}This will sequentially teardown SCC Standard, SCC Premium, and SCC Enterprise modules.${NC}"
read -p "Type 'destroy-all' to confirm full teardown: " -r CONFIRM

if [ "${CONFIRM}" != "destroy-all" ]; then
  echo -e "${GREEN}Teardown aborted.${NC}"
  exit 0
fi

TIERS=("scc-enterprise" "scc-premium" "scc-standard")

for TIER in "${TIERS[@]}"; do
  echo -e "\n${BOLD}${BLUE}------------------------------------------------------------------------------${NC}"
  echo -e "${BOLD}${BLUE}   TEARING DOWN TIER: ${TIER}${NC}"
  echo -e "${BOLD}${BLUE}------------------------------------------------------------------------------${NC}"
  
  TIER_DIR="${ROOT_DIR}/tiers/${TIER}"
  if [ -f "${TIER_DIR}/destroy.sh" ]; then
    (cd "${TIER_DIR}" && echo "destroy" | ./destroy.sh)
  fi
done

echo -e "\n${BOLD}${GREEN}==============================================================================${NC}"
echo -e "${BOLD}${GREEN}   ✅ ALL SECOPS TIERS SUCCESSFULLY DESTROYED${NC}"
echo -e "${BOLD}${GREEN}==============================================================================${NC}"
