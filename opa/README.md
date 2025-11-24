# Open Policy Agent (OPA) Policies for k8s-platform-toolkit

This directory contains OPA Gatekeeper policies for enforcing security and governance rules in the Kubernetes cluster.

## Quick Start - Deploy Policies

**Prerequisite**: Gatekeeper must be installed (via Helm in `k8s-infrastructure-as-code` repo)

**Deploy Policies:**
```bash
# Deploy all OPA policies (ConstraintTemplates + Constraints)
./opa/deploy-opa-policies.sh
```

**Delete Policies:**
```bash
# Delete all OPA policies
./opa/delete-opa-policies.sh
```

**Note**: These scripts only manage policies, NOT Gatekeeper (which is managed by Helm).

**Manual Deployment (Alternative):**
```bash
# Deploy policies manually
kubectl apply -k opa/k8s-policy-manifest/

# If constraints fail (CRDs not ready), wait and retry
sleep 10 && kubectl apply -k opa/k8s-policy-manifest/

# Delete policies manually
kubectl delete -k opa/k8s-policy-manifest/
```

**Note**: The Kustomize setup includes:
- All ConstraintTemplates (policy definitions)
- All Constraints (policy enforcement)

**Gatekeeper**: Managed separately via Helm in `k8s-infrastructure-as-code` repo

**Deployment via Kustomize**:
**Note**: 
- Gatekeeper and `gatekeeper-system` namespace are deployed separately via Helm in the `k8s-infrastructure-as-code` repo
- Policies are deployed directly via `kubectl apply -k` (not via ArgoCD)

**Deploy All Policies**:
```bash
# Deploy ConstraintTemplates and Constraints
kubectl apply -k opa/k8s-policy-manifest/

# If constraints fail (CRDs not ready), wait and apply again
sleep 10 && kubectl apply -k opa/k8s-policy-manifest/
```

**Deployment Order**:
1. Gatekeeper installed via Helm (in `k8s-infrastructure-as-code` repo) → CRDs available
2. ConstraintTemplates applied → Gatekeeper creates Constraint CRDs
3. Constraints applied → Uses the CRDs (may need to retry if CRDs not ready yet)

## Policies

### 1. Require Non-Root Users (`k8srequirednonroot`)

**Purpose**: Ensures all containers in the `online-boutique` namespace run as non-root users for security compliance.

**Files**:
- `constrainttemplate-require-nonroot.yaml` - Defines the policy logic
- `constraint-online-boutique-nonroot.yaml` - Applies the policy to online-boutique namespace

**What it enforces**:
- All containers must have `securityContext.runAsNonRoot: true` OR `securityContext.runAsUser` set to a non-zero value
- Prevents containers from running as root (UID 0)
- Applies to pods in the `online-boutique` namespace

**Deployment**:

### Using Kustomize (Recommended) ⭐

**Everything is managed via Kustomize - Gatekeeper + All Policies:**

```bash
# From repository root - Deploy everything (Gatekeeper + Policies)
kubectl apply -k opa/

# Wait for Gatekeeper to be ready
kubectl wait --for=condition=ready pod -l control-plane=controller-manager -n gatekeeper-system --timeout=120s

# Wait for CRDs to be established (ConstraintTemplates create CRDs)
sleep 10

# If constraints failed on first apply (CRDs not ready), apply again
kubectl apply -k opa/
```

**Or from opa directory:**
```bash
cd opa
kubectl apply -k .
```

**Delete everything:**
```bash
# Delete all policies, Gatekeeper, AND namespace
kubectl delete -k opa/

# This completely removes:
# - All Constraints
# - All ConstraintTemplates  
# - All Gatekeeper components (controller, CRDs, RBAC, etc.)
# - The gatekeeper-system namespace
```

**What gets deployed:**
1. OPA Gatekeeper (namespace, CRDs, controller, RBAC)
2. All ConstraintTemplates (policy definitions)
3. All Constraints (policy enforcement in dryrun mode)

**Alternative: Deploy policies only (if Gatekeeper already installed)**
```bash
# Deploy only policies from k8s-policy-manifest directory
cd opa
kubectl apply -k k8s-policy-manifest/
```

**Note**: All deployment is now managed via Kustomize. Use `kubectl apply -k opa/` for everything.

### Manual Deployment
```bash
# 1. Apply the ConstraintTemplate (defines the policy)
kubectl apply -f k8s-policy-manifest/constrainttemplate-require-nonroot.yaml

# 2. Wait a few seconds for the CRD to be created
sleep 5

# 3. Apply the Constraint (enforces the policy)
kubectl apply -f k8s-policy-manifest/constraint-online-boutique-nonroot-demo.yaml
```

**Testing**:
```bash
# Try to create a pod that runs as root (should be blocked)
kubectl run test-root-pod --image=nginx --restart=Never -n online-boutique --overrides='
{
  "spec": {
    "containers": [{
      "name": "test",
      "securityContext": {
        "runAsUser": 0
      }
    }]
  }
}'

# This should fail with a policy violation error
```

**Verify Policy is Working**:
```bash
# Check constraint status
kubectl get K8sRequiredNonRoot online-boutique-must-run-nonroot

# Check for violations
kubectl describe K8sRequiredNonRoot online-boutique-must-run-nonroot
```

## How It Works

1. **ConstraintTemplate**: Defines the policy logic in Rego language
2. **Constraint**: Applies the policy to specific resources (pods in online-boutique namespace)
3. **Gatekeeper**: Intercepts API requests and validates them against policies before allowing creation

## Policy Flow

```
User → kubectl apply pod.yaml → Kubernetes API Server
                                    ↓
                            [OPA Gatekeeper]
                            (Validates against policies)
                                    ↓
                            ✅ Allow or ❌ Deny
```

## Available Policies

This repository includes 6 implemented policies:

1. ✅ **Require Non-Root Users** - Forces all containers to run as non-root users
2. ✅ **Require Resource Limits** - Forces CPU/memory limits on all containers
3. ✅ **Disallow Latest Tags** - Blocks images with `:latest` tag
4. ✅ **Require Read-Only Root Filesystem** - Forces containers to use read-only root filesystem
5. ✅ **Disallow Privileged Containers** - Blocks containers with `privileged: true`
6. ✅ **Require Labels** - Forces pods to have required labels (app, team, environment)

### Additional Policy Ideas

For a comprehensive list of 30+ OPA policies you can enforce, see the sections below:

- 🔒 **Security Policies**: Non-root users, read-only filesystem, no privileged containers, drop capabilities
- 🖼️ **Image Security**: Disallow latest tags, require specific registries, require image digests
- 📊 **Resource Management**: Require limits, requests, quotas, pod disruption budgets
- 🏷️ **Label & Metadata**: Require labels, annotations, disallow specific labels
- 🌐 **Network Policies**: Network isolation, no host network, no host PID/IPC
- 🔐 **Service Account**: Disallow default service accounts, require specific service accounts
- 📦 **Deployment**: Require replicas, health checks, rolling update strategy
- 🗄️ **Storage**: Disallow host path volumes, require specific storage classes
- 🔄 **Update Strategy**: Require rolling updates, deployment strategy
- 📋 **Compliance**: Pod security standards, resource quotas, limit ranges

## Enforcement Modes

OPA Gatekeeper supports three enforcement modes:

### 1. **Enforce** (Production Mode) - Default
- **Behavior**: BLOCKS violations
- **Use Case**: Production environments
- **Result**: Pods are rejected if they violate policies

### 2. **Dryrun** (Demo/Audit Mode) ⭐ Recommended for Demo
- **Behavior**: REPORTS violations but ALLOWS deployments
- **Use Case**: Demo, test, development environments
- **Result**: Pods are created, violations are logged and visible in constraint status

### 3. **Warn** (Soft Enforcement)
- **Behavior**: WARNINGS in events but ALLOWS deployments
- **Use Case**: Gradual rollout, migration period
- **Result**: Pods are created with warnings in Kubernetes events

### Switching Enforcement Modes

```bash
# Switch to demo mode (non-blocking)
cd opa/deployment
./switch-enforcement-mode.sh dryrun

# Switch back to enforce mode (blocking)
./switch-enforcement-mode.sh enforce

# Switch to warn mode (soft enforcement)
./switch-enforcement-mode.sh warn
```

**Usage**:
```bash
cd opa/deployment
./switch-enforcement-mode.sh <mode> [constraint-name]
# Modes: enforce, dryrun, warn
# Example: ./switch-enforcement-mode.sh dryrun online-boutique-must-run-nonroot
```

### What Happens in Each Mode

**Enforce Mode (Production)**:
```
Developer: kubectl apply pod-with-root.yaml
OPA: ❌ DENIED - "Container must run as non-root"
Result: Pod is NOT created
```

**Dryrun Mode (Demo)** ⭐:
```
Developer: kubectl apply pod-with-root.yaml
OPA: ⚠️  VIOLATION DETECTED (but allowing)
Result: Pod IS created, violation logged
Check: kubectl describe K8sRequiredNonRoot ...
```

**Warn Mode (Soft)**:
```
Developer: kubectl apply pod-with-root.yaml
OPA: ⚠️  WARNING - "Container should run as non-root"
Result: Pod IS created, warning in events
Check: kubectl get events
```

## Real-World Use Cases

### What Just Happened?

You deployed an OPA policy that **automatically enforces security rules** for all pods in the `online-boutique` namespace.

### Why This Matters:

#### 1. **Security Protection**
```
❌ BAD: Container runs as root → Can access everything → Security risk
✅ GOOD: Container runs as non-root → Limited permissions → More secure
```

**Real Example:**
- If a container is compromised and runs as root, attacker has full access
- If container runs as non-root, attacker has limited access

#### 2. **Prevents Accidental Mistakes**
```
Developer: "I'll just run this as root to test..."
OPA: "❌ DENIED - Policy violation"
```

**Real Example:**
- Developer accidentally creates pod without security context
- OPA automatically blocks it before it reaches production
- No manual review needed

#### 3. **Compliance & Auditing**
```
Auditor: "Do all your containers run as non-root?"
You: "Yes, OPA enforces it automatically"
```

**Real Example:**
- SOC 2, PCI-DSS, HIPAA compliance requirements
- OPA provides automatic enforcement
- Audit trail of all policy violations

### Real-World Scenarios

**Scenario 1: Developer Makes a Mistake**

**Without OPA:**
```
Developer: kubectl apply -f bad-pod.yaml
Result: Pod runs as root → Security vulnerability → Production issue
```

**With OPA:**
```
Developer: kubectl apply -f bad-pod.yaml
OPA: ❌ DENIED - "Container must run as non-root user"
Result: Error caught immediately → Developer fixes it → No production issue
```

**Scenario 2: ArgoCD Syncs Bad Configuration**

**Without OPA:**
```
Git: Someone commits pod without security context
ArgoCD: Syncs to cluster
Result: Pod runs as root → Security risk
```

**With OPA:**
```
Git: Someone commits pod without security context
ArgoCD: Tries to sync
OPA: ❌ DENIED - "Policy violation"
Result: Bad config never reaches cluster → GitOps safety
```

**Scenario 3: New Team Member**

**Without OPA:**
```
New Developer: Creates pod without knowing security requirements
Result: Pod runs as root → Security team finds it later → Manual fix
```

**With OPA:**
```
New Developer: Creates pod without security context
OPA: ❌ DENIED - Clear error message
Result: Developer learns immediately → Fixes it → No security issue
```

### Benefits You're Getting Right Now

1. **Automatic Security**: No manual checks needed
2. **Immediate Feedback**: Errors caught before deployment
3. **Consistent Enforcement**: Same rules for everyone
4. **GitOps Safety**: Bad configs from Git are blocked
5. **Compliance**: Automatic audit trail

## Troubleshooting

### Policy not working?
```bash
# Check Gatekeeper is running
kubectl get pods -n gatekeeper-system

# Check constraint template is installed
kubectl get constrainttemplate

# Check constraint status
kubectl get K8sRequiredNonRoot

# View Gatekeeper logs
kubectl logs -n gatekeeper-system -l control-plane=controller-manager
```

### Policy blocking valid pods? (Demo Mode)

For demo/test environments, switch to **dryrun mode** (reports violations but doesn't block):

```bash
# Switch to demo mode (non-blocking)
cd opa/deployment
./switch-enforcement-mode.sh dryrun

# Switch back to enforce mode (blocking)
./switch-enforcement-mode.sh enforce
```

### Temporarily disable constraint
```bash
# Delete the constraint
kubectl delete -f k8s-policy-manifest/constraint-online-boutique-nonroot.yaml
```

## Audit & Reporting

Instead of blocking pods, you can also audit existing resources to see compliance status using the unified audit script:

### Unified Audit Script

```bash
# Show help
./audit-policies.sh -h

# Audit all policies in online-boutique (default)
./audit-policies.sh all

# Audit specific policy
./audit-policies.sh resource-limits [namespace]
./audit-policies.sh latest-tags [namespace]
./audit-policies.sh readonly-fs [namespace]
./audit-policies.sh privileged [namespace]
./audit-policies.sh labels [namespace]

# Audit all policies in all namespaces
./audit-policies.sh all-namespace
```

**Available policies:**
- `resource-limits` - Check for CPU/memory limits
- `latest-tags` - Check for :latest image tags
- `readonly-fs` - Check for read-only root filesystem
- `privileged` - Check for privileged containers
- `labels` - Check for required labels (app, team, environment)
- `all` - Run all policies (single namespace)
- `all-namespace` - Run all policies (all namespaces)

**Features:**
- ✅ Scans all pods in the namespace(s)
- ✅ Reports which pods are compliant/non-compliant
- ✅ Color-coded output (green for compliant, red for violations)
- ✅ Shows summary with counts for each policy
- ✅ Does NOT block anything - just reports

### Example Output

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Policy: Require Resource Limits (CPU/Memory)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ frontend-deployment-abc123
❌ backend-deployment-xyz789
   • Container 'backend' missing CPU limit
   • Container 'backend' missing memory limit

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Total Pods: 10
✅ Compliant: 8
❌ Non-Compliant: 2
```

### Manual kubectl Audit Commands

How to audit all OPA policies manually using kubectl commands (without scripts):

#### 1. Check All Constraints Status

```bash
# List all constraints
kubectl get K8sRequiredNonRoot,K8sRequiredResources,K8sDisallowLatestTag,K8sRequiredReadonlyFS,K8sDisallowPrivileged,K8sRequiredLabels

# Get detailed status of all constraints
kubectl get K8sRequiredNonRoot,K8sRequiredResources,K8sDisallowLatestTag,K8sRequiredReadonlyFS,K8sDisallowPrivileged,K8sRequiredLabels -o yaml
```

#### 2. View Violations for Each Policy

**Non-Root Users:**
```bash
# View violations
kubectl describe K8sRequiredNonRoot online-boutique-must-run-nonroot

# Get violation count
kubectl get K8sRequiredNonRoot online-boutique-must-run-nonroot -o jsonpath='{.status.totalViolations}'
```

**Resource Limits:**
```bash
# View violations
kubectl describe K8sRequiredResources online-boutique-require-resource-limits

# Get violation count
kubectl get K8sRequiredResources online-boutique-require-resource-limits -o jsonpath='{.status.totalViolations}'
```

**Latest Tags:**
```bash
# View violations
kubectl describe K8sDisallowLatestTag online-boutique-disallow-latest-tag

# Get violation count
kubectl get K8sDisallowLatestTag online-boutique-disallow-latest-tag -o jsonpath='{.status.totalViolations}'
```

**Read-Only Filesystem:**
```bash
# View violations
kubectl describe K8sRequiredReadonlyFS online-boutique-require-readonly-fs

# Get violation count
kubectl get K8sRequiredReadonlyFS online-boutique-require-readonly-fs -o jsonpath='{.status.totalViolations}'
```

**Privileged Containers:**
```bash
# View violations
kubectl describe K8sDisallowPrivileged online-boutique-disallow-privileged

# Get violation count
kubectl get K8sDisallowPrivileged online-boutique-disallow-privileged -o jsonpath='{.status.totalViolations}'
```

**Required Labels:**
```bash
# View violations
kubectl describe K8sRequiredLabels online-boutique-require-labels

# Get violation count
kubectl get K8sRequiredLabels online-boutique-require-labels -o jsonpath='{.status.totalViolations}'
```

#### 3. Direct Pod Inspection (Manual Checks)

**Check Non-Root Users:**
```bash
# Check all pods for runAsUser
kubectl get pods -n online-boutique -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.securityContext.runAsUser}{"\t"}{.spec.containers[*].securityContext.runAsUser}{"\n"}{end}'

# Check pods without security context
kubectl get pods -n online-boutique -o json | jq -r '.items[] | select(.spec.securityContext.runAsNonRoot != true and (.spec.containers[]?.securityContext.runAsNonRoot != true)) | .metadata.name'
```

**Check Resource Limits:**
```bash
# Check all pods for CPU/memory limits
kubectl get pods -n online-boutique -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{range .spec.containers[*]}{"  "}{.name}{": CPU="}{.resources.limits.cpu}{" Memory="}{.resources.limits.memory}{"\n"}{end}{end}'

# Find pods without CPU limits
kubectl get pods -n online-boutique -o json | jq -r '.items[] | select(.spec.containers[]?.resources.limits.cpu == null) | .metadata.name'

# Find pods without memory limits
kubectl get pods -n online-boutique -o json | jq -r '.items[] | select(.spec.containers[]?.resources.limits.memory == null) | .metadata.name'
```

**Check Latest Tags:**
```bash
# List all images used
kubectl get pods -n online-boutique -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{range .spec.containers[*]}{"  "}{.name}{": "}{.image}{"\n"}{end}{end}'

# Find pods using :latest tag
kubectl get pods -n online-boutique -o json | jq -r '.items[] | select(.spec.containers[]?.image | contains(":latest")) | "\(.metadata.name): \(.spec.containers[]?.image)"'

# Find pods with images without tags
kubectl get pods -n online-boutique -o json | jq -r '.items[] | select(.spec.containers[]?.image | test("^[^:]+$")) | "\(.metadata.name): \(.spec.containers[]?.image)"'
```

**Check Read-Only Filesystem:**
```bash
# Check readOnlyRootFilesystem setting
kubectl get pods -n online-boutique -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.securityContext.readOnlyRootFilesystem}{"\t"}{.spec.containers[*].securityContext.readOnlyRootFilesystem}{"\n"}{end}'

# Find pods without readOnlyRootFilesystem
kubectl get pods -n online-boutique -o json | jq -r '.items[] | select(.spec.securityContext.readOnlyRootFilesystem != true and (.spec.containers[]?.securityContext.readOnlyRootFilesystem != true)) | .metadata.name'
```

**Check Privileged Containers:**
```bash
# Check for privileged containers
kubectl get pods -n online-boutique -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{range .spec.containers[*]}{"  "}{.name}{": privileged="}{.securityContext.privileged}{"\n"}{end}{end}'

# Find privileged containers
kubectl get pods -n online-boutique -o json | jq -r '.items[] | select(.spec.containers[]?.securityContext.privileged == true) | "\(.metadata.name): \(.spec.containers[]?.name)"'
```

**Check Required Labels:**
```bash
# Check all labels on pods
kubectl get pods -n online-boutique -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.labels.app}{"\t"}{.metadata.labels.team}{"\t"}{.metadata.labels.environment}{"\n"}{end}'

# Find pods missing 'app' label
kubectl get pods -n online-boutique -o json | jq -r '.items[] | select(.metadata.labels.app == null) | .metadata.name'

# Find pods missing 'team' label
kubectl get pods -n online-boutique -o json | jq -r '.items[] | select(.metadata.labels.team == null) | .metadata.name'

# Find pods missing 'environment' label
kubectl get pods -n online-boutique -o json | jq -r '.items[] | select(.metadata.labels.environment == null) | .metadata.name'

# Find pods missing any required label
kubectl get pods -n online-boutique -o json | jq -r '.items[] | select(.metadata.labels.app == null or .metadata.labels.team == null or .metadata.labels.environment == null) | .metadata.name'
```

#### 4. Comprehensive One-Liner Audit

```bash
# Get violation summary for all constraints
echo "=== Policy Violations Summary ===" && \
echo "Non-Root: $(kubectl get K8sRequiredNonRoot online-boutique-must-run-nonroot -o jsonpath='{.status.totalViolations}' 2>/dev/null || echo 'N/A')" && \
echo "Resource Limits: $(kubectl get K8sRequiredResources online-boutique-require-resource-limits -o jsonpath='{.status.totalViolations}' 2>/dev/null || echo 'N/A')" && \
echo "Latest Tags: $(kubectl get K8sDisallowLatestTag online-boutique-disallow-latest-tag -o jsonpath='{.status.totalViolations}' 2>/dev/null || echo 'N/A')" && \
echo "Read-Only FS: $(kubectl get K8sRequiredReadonlyFS online-boutique-require-readonly-fs -o jsonpath='{.status.totalViolations}' 2>/dev/null || echo 'N/A')" && \
echo "Privileged: $(kubectl get K8sDisallowPrivileged online-boutique-disallow-privileged -o jsonpath='{.status.totalViolations}' 2>/dev/null || echo 'N/A')" && \
echo "Labels: $(kubectl get K8sRequiredLabels online-boutique-require-labels -o jsonpath='{.status.totalViolations}' 2>/dev/null || echo 'N/A')"
```

#### 5. Quick Reference

| Policy | Constraint Kind | Constraint Name |
|--------|----------------|-----------------|
| Non-Root Users | `K8sRequiredNonRoot` | `online-boutique-must-run-nonroot` |
| Resource Limits | `K8sRequiredResources` | `online-boutique-require-resource-limits` |
| Latest Tags | `K8sDisallowLatestTag` | `online-boutique-disallow-latest-tag` |
| Read-Only FS | `K8sRequiredReadonlyFS` | `online-boutique-require-readonly-fs` |
| Privileged | `K8sDisallowPrivileged` | `online-boutique-disallow-privileged` |
| Labels | `K8sRequiredLabels` | `online-boutique-require-labels` |

## Scripts

### Operational Scripts
- `deployment/switch-enforcement-mode.sh` - Switch policy enforcement mode (enforce/dryrun/warn)
  - Usage: `./switch-enforcement-mode.sh <mode> [constraint-name]`
  - Help: `./switch-enforcement-mode.sh --help`
  - Auto-detects constraint kind based on name

### Audit Scripts
- `audit-policies.sh` - Unified audit script for all policies (single namespace or all namespaces)
  - Usage: `./audit-policies.sh [policy] [namespace]`
  - Help: `./audit-policies.sh -h`
  - Policies: `resource-limits`, `latest-tags`, `readonly-fs`, `privileged`, `labels`, `all`, `all-namespace`

### Delete Everything with Kustomize
```bash
# Delete all policies, Gatekeeper, AND namespace
kubectl delete -k opa/

# This deletes (in reverse order):
# - All Constraints
# - All ConstraintTemplates
# - All Gatekeeper resources (controller, CRDs, RBAC, ServiceAccounts, etc.)
# - The gatekeeper-system namespace (deleted last, after all resources are removed)
# 
# Note: This is a COMPLETE cleanup - everything is removed including the namespace
# Namespace deletion may take 30-60 seconds as Kubernetes waits for finalizers
```

## Additional Policy Categories

### Security Policies

1. **Require Non-Root Users** ✅ (Already Implemented)
   - **What it does**: Forces all containers to run as non-root users
   - **Why it matters**: Prevents privilege escalation attacks
   - **Use case**: Security compliance, preventing accidental root access

2. **Require Read-Only Root Filesystem** ✅ (Already Implemented)
   - **What it does**: Forces containers to use read-only root filesystem
   - **Why it matters**: Prevents malicious code from writing to filesystem
   - **Use case**: Immutable containers, security hardening

3. **Disallow Privileged Containers** ✅ (Already Implemented)
   - **What it does**: Blocks containers with `privileged: true`
   - **Why it matters**: Privileged containers have full host access
   - **Use case**: Prevent security risks from privileged containers

4. **Require Drop All Capabilities**
   - **What it does**: Forces containers to drop all Linux capabilities
   - **Why it matters**: Reduces attack surface by removing unnecessary privileges
   - **Use case**: Least privilege principle

5. **Require Specific Security Context**
   - **What it does**: Enforces multiple security settings at once
   - **Why it matters**: Comprehensive security posture
   - **Use case**: Production workloads, compliance requirements

### Image Security Policies

6. **Disallow Latest Tags** ✅ (Already Implemented)
   - **What it does**: Blocks images with `:latest` tag
   - **Why it matters**: Latest tags are unpredictable and can break deployments
   - **Use case**: Production stability, reproducible deployments

7. **Require Specific Image Registry**
   - **What it does**: Only allows images from approved registries
   - **Why it matters**: Prevents pulling images from untrusted sources
   - **Use case**: Security, compliance, cost control

8. **Require Image Digest (Not Tags)**
   - **What it does**: Forces use of image digests instead of tags
   - **Why it matters**: Digests are immutable, tags can change
   - **Use case**: Maximum security, reproducible builds

9. **Disallow Specific Vulnerable Images**
   - **What it does**: Blocks known vulnerable images
   - **Why it matters**: Prevents deploying containers with known CVEs
   - **Use case**: Security scanning integration

### Resource Management Policies

10. **Require Resource Limits** ✅ (Already Implemented)
    - **What it does**: Forces CPU/memory limits on all containers
    - **Why it matters**: Prevents resource exhaustion, enables fair scheduling
    - **Use case**: Multi-tenant clusters, cost control

11. **Require Resource Requests**
    - **What it does**: Forces CPU/memory requests on all containers
    - **Why it matters**: Helps Kubernetes scheduler place pods correctly
    - **Use case**: Cluster efficiency, predictable performance

12. **Limit Maximum Resources**
    - **What it does**: Sets maximum allowed CPU/memory per container
    - **Why it matters**: Prevents single pod from consuming all resources
    - **Use case**: Fair resource allocation, cost control

13. **Require Pod Disruption Budget**
    - **What it does**: Forces PDB for critical workloads
    - **Why it matters**: Ensures availability during cluster maintenance
    - **Use case**: High availability applications

### Label & Metadata Policies

14. **Require Specific Labels** ✅ (Already Implemented)
    - **What it does**: Forces pods to have required labels
    - **Why it matters**: Enables proper monitoring, organization, cost tracking
    - **Use case**: Multi-tenant clusters, cost allocation

15. **Require Annotations**
    - **What it does**: Forces pods to have specific annotations
    - **Why it matters**: Metadata for tooling, compliance, documentation
    - **Use case**: Integration with monitoring, compliance tools

16. **Disallow Specific Labels**
    - **What it does**: Blocks certain label values
    - **Why it matters**: Prevents misuse of labels, enforces standards
    - **Use case**: Label governance, preventing conflicts

### Network Policies

17. **Require Network Policy**
    - **What it does**: Forces namespaces to have NetworkPolicy
    - **Why it matters**: Network isolation, security boundaries
    - **Use case**: Multi-tenant clusters, security compliance

18. **Disallow Host Network**
    - **What it does**: Blocks pods using host network
    - **Why it matters**: Prevents bypassing network policies
    - **Use case**: Network security, isolation

19. **Disallow Host PID/IPC**
    - **What it does**: Blocks pods sharing host PID/IPC namespaces
    - **Why it matters**: Prevents container escape, security isolation
    - **Use case**: Security hardening

### Service Account Policies

20. **Disallow Default Service Account**
    - **What it does**: Blocks pods using `default` service account
    - **Why it matters**: Forces explicit service account usage
    - **Use case**: Security, RBAC enforcement

21. **Require Specific Service Account**
    - **What it does**: Forces pods to use approved service accounts
    - **Why it matters**: Ensures proper RBAC, audit trail
    - **Use case**: Security compliance, access control

### Deployment Policies

22. **Require Replicas Minimum**
    - **What it does**: Forces minimum replica count
    - **Why it matters**: Ensures high availability
    - **Use case**: Production workloads, SLA requirements

23. **Require Liveness/Readiness Probes**
    - **What it does**: Forces health checks on containers
    - **Why it matters**: Enables proper pod lifecycle management
    - **Use case**: Reliability, automatic recovery

24. **Disallow Single Replica in Production**
    - **What it does**: Blocks single-replica deployments in prod
    - **Why it matters**: Prevents downtime during updates
    - **Use case**: High availability requirements

### Storage Policies

25. **Disallow Host Path Volumes**
    - **What it does**: Blocks pods mounting host filesystem
    - **Why it matters**: Security risk, breaks isolation
    - **Use case**: Security, multi-tenant clusters

26. **Require Specific Storage Class**
    - **What it does**: Forces use of approved storage classes
    - **Why it matters**: Cost control, performance requirements
    - **Use case**: Cost management, performance SLAs

27. **Limit Volume Types**
    - **What it does**: Only allows specific volume types
    - **Why it matters**: Security, compliance
    - **Use case**: Preventing insecure volume mounts

### Update & Rollout Policies

28. **Require Rolling Update Strategy**
    - **What it does**: Forces rolling updates (no recreate)
    - **Why it matters**: Zero-downtime deployments
    - **Use case**: Production availability

29. **Require Deployment Strategy**
    - **What it does**: Forces explicit update strategy
    - **Why it matters**: Predictable deployments
    - **Use case**: Deployment governance

### Blocklist Policies

30. **Disallow Specific Namespaces**
    - **What it does**: Blocks deployments to certain namespaces
    - **Why it matters**: Protects critical namespaces
    - **Use case**: Namespace governance

31. **Disallow Specific Image Names**
    - **What it does**: Blocks known problematic images
    - **Why it matters**: Security, compliance
    - **Use case**: Blocking untested or vulnerable images

### Compliance & Governance Policies

32. **Require Pod Security Standards**
    - **What it does**: Enforces Kubernetes Pod Security Standards
    - **Why it matters**: Comprehensive security baseline
    - **Use case**: Compliance, security frameworks

33. **Require Resource Quotas**
    - **What it does**: Forces namespaces to have ResourceQuota
    - **Why it matters**: Resource governance, cost control
    - **Use case**: Multi-tenant clusters

34. **Require Limit Ranges**
    - **What it does**: Forces namespaces to have LimitRange
    - **Why it matters**: Default resource limits
    - **Use case**: Resource governance

## Priority Policies (Most Common)

### Top 5 Most Important Policies:

1. **Require Non-Root Users** ✅ (Already done)
2. **Require Resource Limits** ✅ (Already done)
3. **Disallow Latest Tags** ✅ (Already done)
4. **Require Read-Only Root Filesystem** ✅ (Already done)
5. **Disallow Privileged Containers** ✅ (Already done)

## Where to Find Pre-Built Policies

### Official Gatekeeper Library:
- **Gatekeeper Library**: https://github.com/open-policy-agent/gatekeeper-library
- Contains 30+ pre-built policies
- Ready to use ConstraintTemplates

### Popular Policy Collections:
- **OPA Policy Hub**: https://hub.opapolicy.org/
- **Kyverno Policies** (can be adapted): https://kyverno.io/policies/

## Next Steps

1. **Start with Security**: Non-root, read-only filesystem, no privileged
2. **Add Resource Management**: Resource limits and requests
3. **Enforce Image Security**: No latest tags, approved registries
4. **Add Governance**: Required labels, annotations
5. **Network Security**: Network policies, no host network

## Implementation Tips

- **Start Small**: Implement 2-3 policies at a time
- **Test First**: Use `enforcementAction: dryrun` to see violations
- **Monitor**: Check constraint status regularly
- **Document**: Keep track of why each policy exists
- **Iterate**: Add more policies as needs arise

## Resources

- [OPA Documentation](https://www.openpolicyagent.org/docs/latest/)
- [Gatekeeper Documentation](https://open-policy-agent.github.io/gatekeeper/)
- [Rego Policy Language](https://www.openpolicyagent.org/docs/latest/policy-language/)
- [Gatekeeper Library](https://github.com/open-policy-agent/gatekeeper-library)
- [Kubernetes Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
