#!/bin/bash

# Delete OPA Policies (ConstraintTemplates and Constraints)
# This does NOT delete Gatekeeper (which is managed by Helm)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_DIR="${SCRIPT_DIR}/k8s-policy-manifest"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Deleting OPA Policies"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Delete Constraints first (they depend on ConstraintTemplates)
echo "Deleting Constraints..."
kubectl delete -k "${MANIFEST_DIR}/" --ignore-not-found=true 2>&1 | grep -E "(constraint|deleted)" || true
echo ""

# Wait a moment for Constraints to be deleted
sleep 3

# Delete ConstraintTemplates
echo "Deleting ConstraintTemplates..."
kubectl delete -k "${MANIFEST_DIR}/" --ignore-not-found=true 2>&1 | grep -E "(constrainttemplate|deleted)" || true
echo ""

# Verify deletion
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Verification"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

REMAINING_CONSTRAINTS=$(kubectl get constraints --all-namespaces --no-headers 2>/dev/null | wc -l | tr -d ' ')
REMAINING_TEMPLATES=$(kubectl get constrainttemplates --no-headers 2>/dev/null | wc -l | tr -d ' ')

if [ "$REMAINING_CONSTRAINTS" -eq 0 ] && [ "$REMAINING_TEMPLATES" -eq 0 ]; then
    echo "✅ All OPA policies deleted successfully!"
else
    echo "⚠️  Some resources may still exist:"
    [ "$REMAINING_CONSTRAINTS" -gt 0 ] && echo "   - $REMAINING_CONSTRAINTS Constraints remaining"
    [ "$REMAINING_TEMPLATES" -gt 0 ] && echo "   - $REMAINING_TEMPLATES ConstraintTemplates remaining"
    echo ""
    echo "To force delete, run:"
    echo "  kubectl delete constraints --all --all-namespaces"
    echo "  kubectl delete constrainttemplates --all"
fi

echo ""
echo "Note: Gatekeeper is NOT deleted (it's managed by Helm in infrastructure repo)"

