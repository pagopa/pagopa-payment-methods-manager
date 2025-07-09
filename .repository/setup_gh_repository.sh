#!/bin/bash
############################################################
# Terraform script for managing infrastructure on Azure
# md5: 065397c756f4c6a1ba29f44d1e00ef74
############################################################
# Global variables
# Version format x.y accepted

source "./env/backend.ini"
terraform init -reconfigure -backend-config="./env/backend.tfvars"
terraform apply