# K8s Platform Toolkit - GitOps Repository

This repository serves as a comprehensive platform toolkit for deploying and managing applications on Kubernetes clusters (both internal and external). It provides a complete set of applications for monitoring, testing, chaos engineering, and microservices demonstration, all managed through GitOps principles using ArgoCD.

## 🔗 Relationship with Infrastructure Repository

This repository (**k8s-platform-toolkit**) is a **feeder service** for the [**k8s-infrastructure-as-code**](https://github.com/Lforlinux/k8s-infrastructure-as-code) repository. 

**Architecture Overview:**
- **k8s-infrastructure-as-code**: Contains the complete Kubernetes infrastructure (EKS cluster, networking, security groups, IAM, etc.) and deploys ArgoCD
- **k8s-platform-toolkit** (this repo): Supplies the app-of-apps repository location and stores all application source code and manifests

When the infrastructure repository deploys ArgoCD, it automatically references this repository through the app-of-apps pattern, which then deploys all platform applications defined here.

## 🎯 Repository Purpose

The **k8s-platform-toolkit** repository is designed to provide a standardized set of platform applications that can be deployed to any Kubernetes cluster. It serves as:

- **Platform Services Repository**: Centralized location for all platform-level applications
- **GitOps Source of Truth**: Single source for application configurations and deployments
- **App-of-Apps Source**: Provides the repository location and application definitions for the infrastructure repository's ArgoCD deployment
- **Application Code Storage**: Contains all application source code, manifests, and configurations
- **Multi-Cluster Support**: Can deploy to internal or external Kubernetes clusters
- **Observability & Testing Suite**: Complete monitoring, testing, and chaos engineering tools

## 📁 Repository Structure

```
├── application/          # Demo microservices applications
│   ├── k8s-demo/        # Platform dashboard application
│   └── online-boutique/ # Google's microservices demo
├── argocd/              # ArgoCD configuration and application definitions
│   ├── apps/            # Individual ArgoCD application manifests
│   └── install/         # ArgoCD installation manifests
├── availability-test/   # SRE availability testing application
├── chaos/               # Chaos engineering experiments
├── dashboards/          # Grafana dashboard configurations
├── docs/                # Additional documentation
├── monitoring/          # Monitoring stack (Prometheus, Grafana, Loki)
├── opa/                 # OPA Gatekeeper policies for security enforcement
└── sanity-test/         # Health check testing application
```

## 🚀 Quick Start

### 1. Deploy ArgoCD
```bash
cd argocd/install
./deploy-argocd.sh
```

### 2. Deploy App-of-Apps Pattern
```bash
kubectl apply -f argocd/app-of-apps.yaml
```

### 3. Access ArgoCD UI
- Get the LoadBalancer URL: `kubectl get svc -n argocd argocd-server`
- Username: `admin`
- Password: `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`

## 📦 Applications Overview

This repository contains the following applications, each serving a specific purpose in the Kubernetes platform:

<details>
<summary><strong>1. Online Boutique 🛒</strong></summary>

**Purpose**: Microservices demonstration application  
**Namespace**: `online-boutique`  
**Source**: `application/online-boutique/`  
**ArgoCD App**: `online-boutique-app.yaml`

A complete e-commerce microservices demo application from Google, featuring:
- 11 microservices (frontend, cart, checkout, payment, shipping, etc.)
- Redis for cart storage
- gRPC and REST API communication
- Real-world microservices architecture patterns

**Use Cases**:
- Learning microservices architecture
- Testing service mesh and observability tools
- Demonstrating distributed system patterns
- Load testing and performance benchmarking

</details>

<details>
<summary><strong>2. Monitoring Stack 📊</strong></summary>

**Purpose**: Comprehensive observability and metrics collection  
**Namespace**: `monitoring`  
**Source**: `monitoring/`  
**ArgoCD App**: `monitoring-app-local.yaml`

Complete monitoring solution including:

#### **Prometheus**
- Metrics collection and storage
- Service discovery for Kubernetes resources
- Alerting rules configuration
- Scrapes metrics from pods, nodes, and services

#### **Grafana**
- Visualization dashboards
- Pre-configured dashboards for Kubernetes and microservices
- Data source integration (Prometheus, Loki)
- Custom dashboard templates

#### **kube-state-metrics**
- Kubernetes object metrics
- Deployment, pod, and service state tracking
- Resource utilization metrics

#### **node-exporter**
- Node-level system metrics
- CPU, memory, disk, and network statistics
- Hardware and OS-level monitoring

**Use Cases**:
- Cluster health monitoring
- Application performance metrics
- Resource utilization tracking
- Capacity planning and optimization

</details>

<details>
<summary><strong>3. Loki & Promtail 📝</strong></summary>

**Purpose**: Centralized log aggregation and analysis  
**Namespace**: `monitoring`  
**Source**: `monitoring/loki/`  
**ArgoCD Apps**: `loki-app.yaml`, `promtail-app.yaml`

#### **Loki**
- Log aggregation server
- Prometheus-inspired log storage
- Efficient log indexing and querying
- Grafana integration for log visualization

#### **Promtail**
- Log collector agent (DaemonSet)
- Automatically collects logs from all pods
- Ships logs to Loki for aggregation
- Kubernetes metadata enrichment

**Use Cases**:
- Centralized log management
- Troubleshooting application issues
- Log-based alerting
- Compliance and audit logging

</details>

<details>
<summary><strong>4. Sanity Test ✅</strong></summary>

**Purpose**: Automated health check testing for microservices  
**Namespace**: `sanity-test`  
**Source**: `sanity-test/`  
**ArgoCD App**: `sanity-test-app.yaml`

Automated health check application that:
- Tests all microservices in the `online-boutique` namespace
- Runs periodic health checks (every 60 seconds)
- Provides real-time dashboard with test results
- Shows individual service status and response times
- Maintains test history (last 50 runs)

**Features**:
- Web UI dashboard for test results
- REST API for programmatic access
- Manual test trigger capability
- Response time metrics
- Error tracking and reporting

**Use Cases**:
- Pre-deployment validation
- Continuous health monitoring
- Service availability verification
- Integration testing automation

</details>

<details>
<summary><strong>5. Availability Test 🔄</strong></summary>

**Purpose**: SRE-style availability and reliability testing  
**Namespace**: `availability-test`  
**Source**: `availability-test/`  
**ArgoCD App**: `availability-test-app.yaml`

Advanced availability testing application that:
- Simulates real user workflows (add to cart, remove from cart)
- Runs automated tests every 5 minutes
- Calculates uptime percentage and SRE metrics
- Provides Jenkins-like dashboard with green/red status
- Tracks consecutive failures for alerting

**Features**:
- Real user simulation (not just health checks)
- SRE monitoring metrics (uptime %, MTTR, etc.)
- ALB integration for external access
- Manual test execution
- Historical test results

**Use Cases**:
- SRE monitoring and alerting
- Service reliability validation
- User experience testing
- SLA compliance tracking
- Production readiness verification

</details>

<details>
<summary><strong>6. Chaos Engineering 🔥</strong></summary>

**Purpose**: Resilience testing and fault injection  
**Namespace**: `default` (configurable)  
**Source**: `chaos/experiments/`  
**ArgoCD App**: `chaos-app.yaml` (commented, manual sync)

Chaos engineering experiments using Chaos Toolkit:

#### **Available Experiments**:
1. **Stop Random Pod** - Tests pod restart resilience
2. **Modify Deployment Resources** - Tests behavior under resource constraints
3. **Network Chaos** - Tests network latency and packet loss scenarios
4. **Pod Chaos** - Tests various pod failure scenarios

**Features**:
- GitOps-based chaos experiment definitions
- Kubernetes-native chaos execution
- Safe experiment boundaries
- Automated rollback capabilities

**Use Cases**:
- Resilience testing
- Disaster recovery validation
- Failure mode analysis
- Chaos day exercises
- Production readiness assessment

</details>

<details>
<summary><strong>7. K8s Demo Dashboard 🎛️</strong></summary>

**Purpose**: Centralized platform dashboard  
**Namespace**: `k8s-demo`  
**Source**: `application/k8s-demo/`  
**ArgoCD App**: (deployed separately)

Platform dashboard application that provides:
- Single pane of glass for all platform services
- Links to all external services (Grafana, Prometheus, ArgoCD, etc.)
- Service status overview
- Quick access to monitoring and testing tools

**Use Cases**:
- Platform operations dashboard
- Quick service access
- Status overview
- Developer portal

</details>

## 🔄 GitOps Workflow

This repository follows GitOps principles:

1. **Source of Truth**: All application configurations are stored in Git
2. **ArgoCD Sync**: ArgoCD automatically detects and syncs changes
3. **Declarative**: All deployments are defined declaratively in YAML
4. **Version Controlled**: Full history of all changes
5. **Multi-Environment**: Can deploy to different clusters/environments

### Workflow Steps:
```bash
# 1. Make changes to application manifests
vim application/online-boutique/online-boutique-manifest.yaml

# 2. Commit and push changes
git add .
git commit -m "Update microservice configuration"
git push origin main

# 3. ArgoCD automatically detects changes
# 4. Applications sync automatically (if auto-sync enabled)
# 5. Monitor deployment in ArgoCD UI
```

## 🎯 Application Deployment Strategy

### App-of-Apps Pattern
The repository uses ArgoCD's App-of-Apps pattern:
- **Root Application**: `app-of-apps.yaml` manages all child applications
- **Child Applications**: Each app in `argocd/apps/` is managed independently
- **Sync Waves**: Applications deploy in order using sync waves
- **Auto-Sync**: Most applications have automated sync enabled

### Sync Waves
Applications deploy in the following order:
1. **Wave 1**: Sanity Test, Availability Test (testing infrastructure)
2. **Wave 2-4**: Monitoring stack components
3. **Wave 5**: Promtail (depends on Loki)
4. **Wave 99**: Chaos experiments (manual sync only)

## 📊 Monitoring & Observability

### Metrics Collection
- **Prometheus**: Scrapes metrics from all services
- **Grafana**: Visualizes metrics with pre-built dashboards
- **kube-state-metrics**: Kubernetes object metrics
- **node-exporter**: Node-level system metrics

### Log Aggregation
- **Loki**: Centralized log storage
- **Promtail**: Log collection from all pods
- **Grafana**: Log querying and visualization

### Testing & Validation
- **Sanity Test**: Health check validation
- **Availability Test**: SRE-style reliability testing
- **Chaos Engineering**: Resilience and fault tolerance testing

## 🛠️ Tools & Technologies

- **Kubernetes**: Container orchestration platform
- **ArgoCD**: GitOps continuous delivery tool
- **Prometheus**: Metrics collection and alerting
- **Grafana**: Metrics and log visualization
- **Loki**: Log aggregation system
- **Promtail**: Log collection agent
- **Chaos Toolkit**: Chaos engineering framework
- **AWS Load Balancer**: External access to services

## 🔧 Prerequisites

- Kubernetes cluster (EKS, GKE, AKS, or any Kubernetes 1.20+)
- `kubectl` configured with cluster access
- ArgoCD installed (or use provided installation scripts)
- Git repository access (for ArgoCD to pull manifests)
- AWS CLI (optional, for ALB setup)

## 📚 Documentation

- [ArgoCD Setup Guide](argocd/README-ArgoCD.md)
- [ArgoCD Architecture Best Practices](docs/ARGOCD-ARCHITECTURE-BEST-PRACTICES.md) - Management cluster patterns and recommendations
- [GitOps Setup Instructions](GITOPS-SETUP.md)
- [Enhanced Monitoring Guide](docs/README-Enhanced-Monitoring.md)
- [Loki Setup Guide](monitoring/loki/README.md)
- [Chaos Engineering Guide](chaos/README-Chaos-Engineering.md)
- [Sanity Test Documentation](sanity-test/README.md)
- [Availability Test Documentation](availability-test/README.md)

## 🌐 Repository Information

- **Repository**: `https://github.com/Lforlinux/k8s-platform-toolkit.git`
- **Purpose**: Platform toolkit for Kubernetes clusters (feeder service for infrastructure repository)
- **Infrastructure Repository**: [k8s-infrastructure-as-code](https://github.com/Lforlinux/k8s-infrastructure-as-code) - Contains complete Kubernetes infrastructure
- **Deployment**: GitOps via ArgoCD (deployed by infrastructure repository)
- **Target**: Internal and external Kubernetes clusters
- **Role**: Supplies app-of-apps repository location and all application source code

## 📝 License

This project is for educational and demonstration purposes.

## 🤝 Contributing

This repository serves as a platform toolkit. When adding new applications:
1. Create application manifests in appropriate directories
2. Add ArgoCD application definition in `argocd/apps/`
3. Update this README with application details
4. Follow GitOps best practices

---

**Built for Kubernetes Platform Operations** 🚀
