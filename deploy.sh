#!/bin/bash
# Deploy script

echo "Deploying DNS infrastructure..."
echo ""

# Copy config if needed
if [ ! -f terraform.tfvars ]; then
    cp terraform.tfvars.example terraform.tfvars
    echo "Created terraform.tfvars - edit it if you want to change anything"
    echo ""
fi

# Deploy
terraform init
terraform apply

echo ""
echo "Done! Get your DNS endpoint with:"
echo "  terraform output dns_nlb_endpoint"

