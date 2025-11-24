#!/bin/bash

# Deploy k6 Performance Testing Infrastructure
# This script deploys all necessary resources for k6 performance testing
# Run from repository root: ./performance-testing/deploy-performance-testing.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🚀 Deploying k6 Performance Testing Infrastructure..."

# Apply namespace
echo "📦 Creating namespace..."
kubectl apply -f namespace.yaml

# Apply ConfigMap with test scripts
echo "📝 Creating ConfigMap with test scripts..."
kubectl apply -f configmap.yaml

# Apply CronJob for scheduled tests
echo "⏰ Creating scheduled test CronJob..."
kubectl apply -f cronjob-scheduled-test.yaml

echo "✅ k6 Performance Testing infrastructure deployed successfully!"
echo ""
echo "📋 Available resources:"
kubectl get all -n performance-testing
echo ""
echo "🧪 To run a smoke test manually:"
echo "   kubectl apply -f job-smoke-test.yaml"
echo "   kubectl logs -f job/k6-smoke-test -n performance-testing"
echo ""
echo "🧪 To run a load test:"
echo "   kubectl apply -f job-load-test.yaml"
echo "   kubectl logs -f job/k6-load-test -n performance-testing"
echo ""
echo "📊 To view scheduled test jobs:"
echo "   kubectl get cronjobs -n performance-testing"
echo "   kubectl get jobs -n performance-testing"
echo ""
echo "📊 To view test results:"
echo "   kubectl logs -n performance-testing -l app=k6-performance-test"
echo ""
echo "🌐 To deploy the Results Dashboard UI (with ALB access):"
echo "   cd results-ui && ./deploy-results-ui.sh"

