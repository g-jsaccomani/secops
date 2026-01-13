#!/usr/bin/env bash
# ==============================================================================
# Google Cloud SecOps - SCC Enterprise Tier Deployment Script
# ==============================================================================
# Author: Joabson Saccomani (@jsaccomani)
# Description: Provisions a dedicated Folder and Project with SCC Enterprise & Chronicle SIEM/SOAR baseline.
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

echo -e "${BOLD}${CYAN}"
echo "=============================================================================="
echo "   GOOGLE CLOUD SECOPS - DEPLOYING SCC ENTERPRISE TIER FOUNDATION"
echo "=============================================================================="
echo -e "${NC}"

# 1. Pre-flight checks
log_info "Verifying CLI tools and authentication..."
command -v gcloud >/dev/null 2>&1 || { log_error "gcloud CLI is required but not installed."; exit 1; }
command -v terraform >/dev/null 2>&1 || { log_error "terraform is required but not installed."; exit 1; }

ACTIVE_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null || true)
if [ -z "${ACTIVE_ACCOUNT}" ]; then
  log_error "No active gcloud authentication found. Run: gcloud auth login"
  exit 1
fi
log_success "Authenticated as: ${BOLD}${ACTIVE_ACCOUNT}${NC}"

# 2. Check for terraform.tfvars or environment variables
if [ ! -f "terraform.tfvars" ]; then
  if [ -f "terraform.tfvars.example" ]; then
    log_warn "terraform.tfvars not found. Creating from template..."
    cp terraform.tfvars.example terraform.tfvars
    
    DETECTED_ORG=$(gcloud organizations list --format="value(name)" 2>/dev/null | head -n 1 || true)
    DETECTED_BILLING=$(gcloud billing accounts list --format="value(name)" 2>/dev/null | head -n 1 || true)
    
    if [ -n "${DETECTED_ORG}" ]; then
      sed -i.bak "s|organizations/YOUR_ORGANIZATION_ID|${DETECTED_ORG}|g" terraform.tfvars 2>/dev/null || true
    fi
    if [ -n "${DETECTED_BILLING}" ]; then
      sed -i.bak "s|000000-000000-000000|${DETECTED_BILLING}|g" terraform.tfvars 2>/dev/null || true
    fi
    rm -f terraform.tfvars.bak
    
    log_info "Please review and edit ${BOLD}${SCRIPT_DIR}/terraform.tfvars${NC} before proceeding."
  fi
fi

# 3. Terraform Execution
log_info "Initializing Terraform..."
terraform init -upgrade

log_info "Planning deployment..."
terraform plan -out=tfplan

read -p "Do you want to proceed with deploying SCC Enterprise Foundation? (y/N): " -r CONFIRM
if [[ ! "${CONFIRM}" =~ ^[Yy]$ ]]; then
  log_warn "Deployment cancelled by user."
  rm -f tfplan
  exit 0
fi

log_info "Applying Terraform execution plan..."
terraform apply tfplan
rm -f tfplan

echo -e "\n${BOLD}${GREEN}==============================================================================${NC}"
echo -e "${BOLD}${GREEN}   ✅ SCC ENTERPRISE TIER FOUNDATION SUCCESSFULLY DEPLOYED!${NC}"
echo -e "${BOLD}${GREEN}==============================================================================${NC}"
terraform output
