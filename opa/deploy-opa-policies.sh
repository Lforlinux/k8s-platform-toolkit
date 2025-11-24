#!/bin/bash

# Deploy OPA Policies (ConstraintTemplates and Constraints)
# Prerequisite: Gatekeeper must be installed (via Helm in infrastructure repo)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_DIR="${SCRIPT_DIR}/k8s-policy-manifest"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Deploying OPA Policies"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if Gatekeeper is installed
echo "Checking if Gatekeeper is installed..."
if ! kubectl get crd constrainttemplates.templates.gatekeeper.sh &>/dev/null; then
    echo "❌ Error: Gatekeeper is not installed!"
    echo "   Please install Gatekeeper first (via Helm in infrastructure repo)"
    exit 1
fi
echo "✅ Gatekeeper is installed"
echo ""

# Check if gatekeeper-system namespace exists
echo "Checking if gatekeeper-system namespace exists..."
if ! kubectl get namespace gatekeeper-system &>/dev/null; then
    echo "⚠️  Warning: gatekeeper-system namespace not found"
    echo "   Gatekeeper should create this namespace. Continuing anyway..."
    echo ""
fi

# Deploy ConstraintTemplates first
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Step 1: Deploying ConstraintTemplates"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
kubectl apply -k "${MANIFEST_DIR}/"
echo ""

# Wait for Gatekeeper to process ConstraintTemplates and create CRDs
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Step 2: Waiting for ConstraintTemplate CRDs to be created"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Waiting for Gatekeeper to process ConstraintTemplates..."
sleep 10

# List of CRDs that need to be ready
CRDS=(
    "k8srequirednonroots.constraints.gatekeeper.sh"
    "k8srequiredresources.constraints.gatekeeper.sh"
    "k8sdisallowlatesttags.constraints.gatekeeper.sh"
    "k8srequiredreadonlyfs.constraints.gatekeeper.sh"
    "k8sdisallowprivilegeds.constraints.gatekeeper.sh"
    "k8srequiredlabels.constraints.gatekeeper.sh"
)

ALL_READY=true
for CRD in "${CRDS[@]}"; do
    echo -n "Waiting for CRD: $CRD ... "
    MAX_ATTEMPTS=30
    ATTEMPT=0
    CRD_READY=false
    
    while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
        if kubectl get crd "$CRD" &>/dev/null; then
            if kubectl wait --for=condition=established "crd/$CRD" --timeout=5s &>/dev/null; then
                echo "✅ Ready"
                CRD_READY=true
                break
            fi
        fi
        ATTEMPT=$((ATTEMPT + 1))
        sleep 2
    done
    
    if [ "$CRD_READY" = "false" ]; then
        echo "❌ Not ready after $MAX_ATTEMPTS attempts"
        ALL_READY=false
    fi
done

if [ "$ALL_READY" = "false" ]; then
    echo ""
    echo "⚠️  Warning: Some CRDs are not ready yet"
    echo "   Constraints may fail to apply. Retrying in 10 seconds..."
    sleep 10
fi

# Apply again to ensure Constraints are applied (CRDs should be ready now)
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Step 3: Deploying Constraints (retry if needed)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
kubectl apply -k "${MANIFEST_DIR}/"
echo ""

# Verify deployment
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Verification"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "ConstraintTemplates:"
kubectl get constrainttemplates -o custom-columns=NAME:.metadata.name,AGE:.metadata.creationTimestamp
echo ""
echo "Constraints:"
kubectl get constraints -o custom-columns=NAME:.metadata.name,KIND:.kind,AGE:.metadata.creationTimestamp 2>/dev/null || echo "No constraints found (may still be creating)"
echo ""

echo "✅ OPA Policies deployment completed!"
echo ""
echo "To verify policies are working, run:"
echo "  ./opa/audit-policies.sh all online-boutique"

