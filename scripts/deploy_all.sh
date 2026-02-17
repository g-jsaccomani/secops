#!/usr/bin/env bash
# ==============================================================================
# Google Cloud SecOps - Deploy All Tiers Foundation (Standard, Premium, Enterprise)
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

echo -e "${BOLD}${CYAN}"
echo "=============================================================================="
echo "   GOOGLE CLOUD SECOPS - BATCH DEPLOYMENT OF ALL 3 TIERS"
echo "   1. SCC Standard Foundation"
echo "   2. SCC Premium Foundation"
echo "   3. SCC Enterprise & Chronicle Convergence Foundation"
echo "=============================================================================="
echo -e "${NC}"

"${ROOT_DIR}/scripts/validate_env.sh"

TIERS=("scc-standard" "scc-premium" "scc-enterprise")

for TIER in "${TIERS[@]}"; do
  echo -e "\n${BOLD}${BLUE}------------------------------------------------------------------------------${NC}"
  echo -e "${BOLD}${BLUE}   DEPLOYING TIER: ${TIER}${NC}"
  echo -e "${BOLD}${BLUE}------------------------------------------------------------------------------${NC}"
  
  TIER_DIR="${ROOT_DIR}/tiers/${TIER}"
  if [ -f "${TIER_DIR}/deploy.sh" ]; then
    (cd "${TIER_DIR}" && ./deploy.sh)
  else
    echo -e "${RED}[ERROR] deploy.sh not found in ${TIER_DIR}${NC}"
    exit 1
  fi
done

echo -e "\n${BOLD}${GREEN}==============================================================================${NC}"
echo -e "${BOLD}${GREEN}   🎉 ALL 3 SECOPS TIERS SUCCESSFULLY DEPLOYED!${NC}"
echo -e "${BOLD}${GREEN}==============================================================================${NC}"
