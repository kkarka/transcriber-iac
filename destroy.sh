#!/bin/bash
set -euo pipefail

echo "🚨 SAFE DESTROY STARTED"

# -----------------------------------
# Config
# -----------------------------------
ENV_DIR="./infrastructure/environment/dev"
NAMESPACE="transcriber"

# -----------------------------------
# Confirmation (safety)
# -----------------------------------
read -p "⚠️ This will DESTROY ALL infra. Type 'yes' to continue: " confirm
if [[ "$confirm" != "yes" ]]; then
  echo "❌ Aborted"
  exit 1
fi

# -----------------------------------
# Step 1: Disable ArgoCD (prevents recreation)
# -----------------------------------
echo "🛑 Deleting ArgoCD (if exists)..."
kubectl delete namespace argocd --ignore-not-found=true || true

# -----------------------------------
# Step 2: Delete application namespace (cleanest)
# -----------------------------------
echo "🧹 Deleting namespace: $NAMESPACE"
kubectl delete namespace $NAMESPACE --ignore-not-found=true || true

echo "⏳ Waiting for namespace deletion..."
for i in {1..30}; do
  if kubectl get ns $NAMESPACE >/dev/null 2>&1; then
    echo "⏳ Still deleting ($i)..."
    sleep 5
  else
    echo "✅ Namespace deleted"
    break
  fi
done

# -----------------------------------
# Step 3: Force delete stuck resources (if any)
# -----------------------------------
echo "🔧 Cleaning stuck resources (if any)..."

# Remove finalizers (common ALB/PVC issue)
kubectl get namespace $NAMESPACE -o json 2>/dev/null | \
  jq '.spec.finalizers=[]' | \
  kubectl replace --raw "/api/v1/namespaces/$NAMESPACE/finalize" -f - 2>/dev/null || true

# -----------------------------------
# Step 4: Empty S3 bucket
# -----------------------------------
echo "🪣 Emptying S3 bucket..."

BUCKET_NAME=$(terraform -chdir=$ENV_DIR output -raw bucket_name 2>/dev/null || echo "")

if [[ -z "$BUCKET_NAME" ]]; then
  echo "⚠️ Could not detect bucket name. Enter manually:"
  read BUCKET_NAME
fi

echo "Bucket: $BUCKET_NAME"

# Delete normal objects
aws s3 rm s3://$BUCKET_NAME --recursive || true

# Delete versioned objects (if enabled)
aws s3api delete-objects \
  --bucket $BUCKET_NAME \
  --delete "$(aws s3api list-object-versions \
  --bucket $BUCKET_NAME \
  --output=json \
  --query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}')" 2>/dev/null || true

# -----------------------------------
# Step 5: Terraform destroy (with retries)
# -----------------------------------
echo "💣 Running terraform destroy..."

ATTEMPTS=0
MAX_ATTEMPTS=3

until [ $ATTEMPTS -ge $MAX_ATTEMPTS ]
do
  terraform -chdir=$ENV_DIR destroy -auto-approve && break
  ATTEMPTS=$((ATTEMPTS+1))
  echo "⚠️ Destroy failed... retrying ($ATTEMPTS/$MAX_ATTEMPTS)"
  sleep 10
done

# -----------------------------------
# Step 6: Final AWS cleanup check (optional)
# -----------------------------------
echo "🔍 Checking leftover AWS resources..."

echo "ALBs:"
aws elbv2 describe-load-balancers --query "LoadBalancers[*].DNSName" --output table || true

echo "EBS Volumes:"
aws ec2 describe-volumes --query "Volumes[*].VolumeId" --output table || true

echo "RDS Instances:"
aws rds describe-db-instances --query "DBInstances[*].DBInstanceIdentifier" --output table || true

echo "🎉 DESTROY COMPLETE"