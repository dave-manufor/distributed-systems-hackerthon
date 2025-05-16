# Widgetario - Kubernetes Hackathon Project

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen)](https://img.shields.io/badge/build-passing-brightgreen) [![License](https://img.shields.io/badge/License-TBD-blue)](https://img.shields.io/badge/License-TBD-blue) ## Project Overview

This project, "Widgetario," is a multi-component application deployed on Kubernetes, complete with CI/CD, monitoring, and logging infrastructure. It demonstrates a comprehensive approach to building, deploying, and managing distributed systems using Kubernetes. This repository serves as an entry for the Kubernetes CourseLabs hackathon, aiming to showcase best practices in Kubernetes deployments, automation, and observability. The core application appears to be "Widgetario," consisting of a web frontend, products API, stock API, and a products database.

## Table of Contents

- [Project Overview](#project-overview)
- [Table of Contents](#table-of-contents)
- [Architecture & Directory Structure](#architecture--directory-structure)
- [Prerequisites](#prerequisites)
- [Installation & Setup](#installation--setup)
  - [1. Initial Environment Setup](#1-initial-environment-setup)
  - [2. Deploy CI/CD Infrastructure (Jenkins & Gogs)](#2-deploy-ci-cd-infrastructure-jenkins--gogs)
  - [3. Configure Jenkins](#3-configure-jenkins)
  - [4. Configure Gogs](#4-configure-gogs)
  - [5. Deploy Supporting Infrastructure](#5-deploy-supporting-infrastructure)
    - [NGINX Ingress Controller](#nginx-ingress-controller)
    - [Logging Stack (EFK)](#logging-stack-efk)
    - [Monitoring Stack (Prometheus & Grafana)](#monitoring-stack-prometheus--grafana)
- [Usage](#usage)
  - [Running the CI/CD Pipeline](#running-the-ci-cd-pipeline)
  - [Accessing the Application](#accessing-the-application)
  - [Manual Deployment with Helm](#manual-deployment-with-helm)
  - [Verifying Deployments](#verifying-deployments)
- [Configuration](#configuration)
  - [Helm Chart Values](#helm-chart-values)
  - [CI/CD Environment Variables](#ci-cd-environment-variables)
- [CI/CD](#ci-cd)
  - [Pipeline Overview](#pipeline-overview)
  - [Jenkinsfile Stages](#jenkinsfile-stages)
  - [Workflow Files](#workflow-files)
- [Troubleshooting & FAQs](#troubleshooting--faqs)
  - [Checking Pod Status](#checking-pod-status)
  - [Checking Pod Logs](#checking-pod-logs)
  - [Checking Helm Releases](#checking-helm-releases)
  - [Accessing Dashboards](#accessing-dashboards)
- [Contributing](#contributing)
- [License & Authors](#license--authors)
- [Appendix](#appendix)

## Architecture & Directory Structure

dave-manufor-distributed-systems-hackerthon.git/
├── Jenkinsfile                       # Jenkins declarative pipeline for CI/CD
├── ci-cd/                            # CI/CD setup (Jenkins, Gogs)
│   ├── README.md                     # Setup guide for CI/CD components
│   ├── deploy-cicd.ps1               # PowerShell script to deploy Jenkins & Gogs
│   ├── gogs-deployment.yaml          # Kubernetes deployment for Gogs
│   └── jenkins-deployment.yaml       # Kubernetes deployment for Jenkins
├── ingress-controller/               # NGINX Ingress Controller manifests
│   ├── ic-configmap.json
│   ├── ic-deployment.json
│   ├── ic-ingress-class.json
│   ├── ic-namespace.json
│   ├── ic-service-account.json
│   ├── ic-service.json
│   └── ic-rbac/
│       ├── ic-rbac-cluster-role-binding.json
│       └── ic-rbac-cluster-role.json
├── logging/                          # Logging stack (Elasticsearch, Fluentd, Kibana)
│   ├── elasticsearch_statefulset.yaml
│   ├── elasticsearch_svc.yaml
│   ├── fluentd.yaml
│   ├── kibana.yaml
│   └── kube-logging.yaml             # Namespace for logging components
├── monitoring/                       # Monitoring stack (Prometheus, Grafana)
│   ├── grafana/                      # Grafana manifests
│   │   ├── datasource-config.json
│   │   ├── deployment.json
│   │   ├── ingress.json
│   │   └── service.json
│   └── prometheus/                   # Prometheus manifests
│       ├── cluster-role-binding.json
│       ├── cluster-role.json
│       ├── configmap.json
│       ├── deployment.json
│       ├── monitoring.json           # Namespace for monitoring components
│       ├── service-account.json
│       └── service.json
├── widgetario/                       # Application source code and Dockerfiles (Assumed - not provided) & Kubernetes manifests
│   ├── products-api/                 # Products API microservice
│   │   ├── products-api-deployment.json
│   │   ├── products-api-ingress.json
│   │   ├── products-api-secret.json
│   │   └── products-api-service.json
│   ├── products-db/                  # Products database
│   │   ├── product-db-secret.json
│   │   ├── products-db-deployment.json # Should ideally be a StatefulSet
│   │   └── products-db-service.json
│   ├── stock-api/                    # Stock API microservice
│   │   ├── stock-api-deployment.json
│   │   ├── stock-api-secret.json
│   │   └── stock-api-service.json
│   └── web/                          # Web frontend
│       ├── web-config.json
│       ├── web-deployment.json
│       ├── web-ingress.json
│       ├── web-secret-api.json
│       └── web-service.json
└── widgetario-helm/                  # Helm chart for the Widgetario application
├── Chart.yaml
├── smoke-test.json               # Values for smoke testing via Jenkins
├── smoke-test.yaml               # (Duplicate/Alternative format of smoke-test.json)
├── values.json                   # (Alternative format for Helm values)
├── values.yaml                   # Default Helm chart values
└── templates/                    # Helm chart templates
├── _helpers.tpl
├── ingress.yaml
├── NOTES.txt
├── papi-deployment.yaml      # Products API deployment template
├── pdb-statefulset.yaml      # Products DB statefulset template
├── sapi-deployment.yaml      # Stock API deployment template
├── services.yaml
└── web-deployment.yaml       # Web frontend deployment template


-   **`Jenkinsfile`**: Defines the CI/CD pipeline executed by Jenkins. It handles building Docker images for the Widgetario application, pushing them to a registry, and deploying the application using Helm.
-   **`ci-cd/`**: Contains manifests and scripts to deploy Jenkins and Gogs (a self-hosted Git service) into the Kubernetes cluster. This enables a self-contained CI/CD loop.
-   **`ingress-controller/`**: Kubernetes manifests for deploying an NGINX Ingress Controller. This will manage external access to services within the cluster.
-   **`logging/`**: Manifests for deploying an EFK (Elasticsearch, Fluentd, Kibana) stack. Fluentd collects logs, Elasticsearch stores them, and Kibana provides a UI for viewing and searching logs.
-   **`monitoring/`**: Manifests for deploying Prometheus and Grafana. Prometheus scrapes metrics from applications and Kubernetes, while Grafana provides dashboards for visualizing these metrics.
-   **`widgetario/`**: Contains the Kubernetes deployment manifests for the individual microservices of the Widgetario application (Products API, Stock API, Products DB, Web frontend). *Note: Actual application code and Dockerfiles for these components are assumed to be in subdirectories here but were not provided in the listing.*
-   **`widgetario-helm/`**: A Helm chart for packaging and deploying the entire Widgetario application suite. This allows for versioned, configurable deployments.

## Prerequisites

-   A running Kubernetes cluster (e.g., Minikube, Kind, Docker Desktop with Kubernetes, or a cloud provider's K8s service).
-   `kubectl` CLI installed and configured to communicate with your cluster.
-   `helm` CLI (version 3+) installed.
-   Docker installed and running (if building images locally or for the Jenkins agent).
-   A Docker Hub account (or another container registry) and credentials for pushing images.
    -   The `Jenkinsfile` expects credentials with IDs `docker-hub-user` and `docker-hub-pass` configured in Jenkins.
    -   The `deploy-cicd.ps1` script expects you to replace placeholder credentials for `regcred` secret.

## Installation & Setup

Follow these steps to set up the entire environment, including CI/CD, supporting services, and the application.

### 1. Initial Environment Setup

Clone this repository:
```bash
git clone <repository-url>
cd dave-manufor-distributed-systems-hackerthon.git
2. Deploy CI/CD Infrastructure (Jenkins & Gogs)
The ci-cd directory contains resources to set up Jenkins and Gogs.

PowerShell

# Navigate to the ci-cd directory
cd ci-cd

# IMPORTANT: Edit deploy-cicd.ps1 to replace placeholder Docker Hub credentials
# --docker-username=your-username
# --docker-password=your-password
# --docker-email=your-email@example.com

# Run the deployment script (ensure PowerShell is available or adapt to bash)
./deploy-cicd.ps1
This script will:

Create ci-cd and test namespaces.
Deploy Jenkins (accessible via NodePort).
Deploy Gogs (accessible via NodePort).
Create Docker registry secrets (regcred) in ci-cd and test namespaces.
Output the access URLs for Jenkins and Gogs.
3. Configure Jenkins
Access Jenkins using the URL provided by the deploy-cicd.ps1 script (e.g., http://localhost:<JENKINS_NODE_PORT>).
Configure Docker Hub credentials in Jenkins:
Go to "Manage Jenkins" > "Manage Credentials".
Under "Stores scoped to Jenkins", click on "(global)".
Click "Add Credentials" on the left.
Kind: "Username with password".
Scope: Global.
Username: Your Docker Hub username.
Password: Your Docker Hub password or access token.
ID: docker-hub-user
Click "OK".
Repeat for a second credential with ID docker-hub-pass (if your password/token itself needs to be a secret, otherwise you might just need one credential for username and one for password/token, or just use docker-hub-user for both username and password fields in Jenkinsfile if Jenkins handles it as such). The Jenkinsfile uses credentials('docker-hub-user') for username and credentials('docker-hub-pass') for password. It's more common to have a single credential ID that provides both. Review and adjust Jenkins credential setup and Jenkinsfile environment block as needed.
Create a new pipeline job:
Click "New Item".
Enter an item name (e.g., "widgetario-pipeline") and choose "Pipeline". Click "OK".
In the "Pipeline" section:
Definition: "Pipeline script from SCM".
SCM: "Git".
Repository URL: http://<GOGS_NODE_IP_OR_LOCALHOST>:<GOGS_HTTP_NODE_PORT>/<your-gogs-username>/widgetario.git (e.g., http://localhost:30080/gogs_user/widgetario.git). The internal service URL http://gogs:3000/... is for Jenkins to Gogs communication within the cluster if Jenkins runs as a pod configured to resolve cluster DNS.
Branch Specifier: */master or */main (depending on your default branch).
Script Path: Jenkinsfile.
Save the job.
4. Configure Gogs
Access Gogs using the URL provided by deploy-cicd.ps1 (e.g., http://localhost:<GOGS_NODE_PORT>).
Complete the Gogs initial setup if it's the first time.
Register a new user or log in.
Create a new repository named widgetario.
Push the project code to your Gogs repository:
Bash

# Ensure you are in the root of the cloned 'dave-manufor-distributed-systems-hackerthon.git' directory
git remote remove origin # If an old remote exists
git remote add gogs http://localhost:<GOGS_HTTP_NODE_PORT>/<your-gogs-username>/widgetario.git 
# Example: git remote add gogs http://localhost:30080/gogs_user/widgetario.git
git push -u gogs master # Or your default branch name
5. Deploy Supporting Infrastructure
Apply the manifests for the Ingress controller, logging, and monitoring stacks. It's recommended to apply them in separate namespaces as defined in their respective files.

NGINX Ingress Controller
Bash

kubectl apply -f ingress-controller/ic-namespace.json
kubectl apply -f ingress-controller/ic-service-account.json
kubectl apply -f ingress-controller/ic-rbac/ic-rbac-cluster-role.json
kubectl apply -f ingress-controller/ic-rbac/ic-rbac-cluster-role-binding.json
kubectl apply -f ingress-controller/ic-configmap.json
kubectl apply -f ingress-controller/ic-deployment.json
kubectl apply -f ingress-controller/ic-service.json
kubectl apply -f ingress-controller/ic-ingress-class.json
Verify: kubectl get pods -n nginx-ingress

Logging Stack (EFK)
Bash

kubectl apply -f logging/kube-logging.yaml # Creates namespace
kubectl apply -f logging/elasticsearch_svc.yaml
kubectl apply -f logging/elasticsearch_statefulset.yaml
kubectl apply -f logging/fluentd.yaml
kubectl apply -f logging/kibana.yaml
Verify: kubectl get pods -n kube-logging
To access Kibana, you might need to set up port-forwarding or an Ingress:
kubectl port-forward svc/kibana 5601:5601 -n kube-logging
Then access Kibana at http://localhost:5601.

Monitoring Stack (Prometheus & Grafana)
First, create the monitoring namespace (if monitoring/monitoring.json only contains Namespace definition, otherwise ensure it's created before other components):

Bash

# Assuming monitoring/monitoring.json defines the namespace:
kubectl apply -f monitoring/monitoring.json # Creates 'monitoring' namespace
# Or create manually if not in the file:
# kubectl create namespace monitoring
Deploy Prometheus:

Bash

kubectl apply -f monitoring/prometheus/service-account.json -n monitoring
kubectl apply -f monitoring/prometheus/cluster-role.json # No namespace for ClusterRole
kubectl apply -f monitoring/prometheus/cluster-role-binding.json # No namespace for ClusterRoleBinding
kubectl apply -f monitoring/prometheus/configmap.json -n monitoring
kubectl apply -f monitoring/prometheus/deployment.json -n monitoring
kubectl apply -f monitoring/prometheus/service.json -n monitoring
Verify: kubectl get pods -n monitoring
To access Prometheus, set up port-forwarding or an Ingress:
kubectl port-forward svc/prometheus-service 9090:9090 -n monitoring

Deploy Grafana:

Bash

kubectl apply -f monitoring/grafana/datasource-config.json -n monitoring
kubectl apply -f monitoring/grafana/deployment.json -n monitoring
kubectl apply -f monitoring/grafana/service.json -n monitoring
kubectl apply -f monitoring/grafana/ingress.json -n monitoring # Assumes Ingress controller is working
Verify: kubectl get pods -n monitoring
Access Grafana via its Ingress (e.g., http://monitoring.widgetario.local if your Ingress and DNS are set up) or port-forward:
kubectl port-forward svc/grafana 3000:80 -n monitoring
Then access Grafana at http://localhost:3000. Default credentials are often admin/admin.

Usage
Running the CI/CD Pipeline
Make a change to the application code (e.g., in one of the widgetario/ subdirectories).
Commit and push the changes to your Gogs repository:
Bash

git add .
git commit -m "My new feature"
git push gogs master # Or your default branch
Trigger the Jenkins pipeline job ("widgetario-pipeline") manually from the Jenkins UI, or configure a webhook in Gogs to trigger Jenkins automatically on push events.
The pipeline will:

Build Docker images for each service (products-api, stock-api, products-db, web).
Push the images to the configured Docker registry (REGISTRY_REPO).
Deploy the application to the test namespace using the Helm chart from widgetario-helm/.
Accessing the Application
After a successful deployment by the Jenkins pipeline (or manual Helm deployment), the Widgetario application should be running in the test namespace.

The Helm chart (widgetario-helm/templates/ingress.yaml) defines Ingress rules. If your NGINX Ingress Controller is correctly set up and you have appropriate DNS entries (or /etc/hosts modifications) for hostnames like widgetario.local (as per ingress.yaml in Helm chart, you might need to check actual host):

You can access the web frontend via the Ingress. Check the Ingress resource:

Bash

kubectl get ingress -n test
Look for the HOSTS and ADDRESS specified. For example, if the web ingress is web.widgetario.local, point your browser to http://web.widgetario.local.

If Ingress is not fully set up for external access, you can use kubectl port-forward:

Bash

# Example for the web service
kubectl port-forward svc/widgetario-test-web 8080:80 -n test
Then access http://localhost:8080 in your browser.

Manual Deployment with Helm
You can also deploy the Widgetario application manually using the Helm chart:

Bash

helm install <release-name> ./widgetario-helm \
  --namespace test --create-namespace \
  --values ./widgetario-helm/values.yaml \
  # Optionally override image tags or other values:
  # --set web.image.tag=latest
  # --set papi.image.tag=latest
  # ...and so on for sapi, pdb
To upgrade an existing release:

Bash

helm upgrade <release-name> ./widgetario-helm \
  --namespace test \
  --values ./widgetario-helm/values.yaml \
  # --set web.image.tag=new-version
To uninstall a release:

Bash

helm uninstall <release-name> -n test
Verifying Deployments
Check the status of deployed resources:

Bash

# For Helm deployments
helm list -n test
helm status <release-name> -n test

# Check pods, services, deployments, statefulsets
kubectl get pods,svc,deploy,sts -n test

# Check rollout status (as used in Jenkinsfile)
kubectl rollout status deployment/widgetario-test-papi -n test
kubectl rollout status deployment/widgetario-test-sapi -n test
kubectl rollout status deployment/widgetario-test-web -n test
kubectl rollout status statefulset/widgetario-test-pdb -n test # Note: pdb is a statefulset in helm chart
Configuration
Helm Chart Values
The primary configuration for the Widgetario application deployment is managed through the Helm chart located in widgetario-helm/.

widgetario-helm/values.yaml: Contains the default values for the chart. This includes image repositories, tags, replica counts, service types, resource requests/limits, and application-specific settings.
widgetario-helm/values.json: Appears to be an alternative JSON format for values. Helm typically uses YAML.
widgetario-helm/smoke-test.json: Contains specific values used by the Jenkins pipeline for deploying to the test environment. This allows overriding defaults for testing purposes.
widgetario-helm/smoke-test.yaml: (Likely an alternative YAML format for smoke test values).
To override default values during Helm installation or upgrade, use the --set flag or provide a custom values file with -f <your-values-file.yaml>:

Bash

helm install my-app ./widgetario-helm -n test \
  --set web.replicaCount=3 \
  --set papi.image.tag=v1.2.3
CI/CD Environment Variables
The Jenkinsfile uses environment variables for configuration:

REGISTRY: Container registry URL (e.g., index.docker.io).
REGISTRY_USER: Docker Hub username (from Jenkins credentials).
REGISTRY_PASS: Docker Hub password/token (from Jenkins credentials).
REGISTRY_REPO: Docker Hub repository path (e.g., yourusername/widgetario).
BUILD_VERSION: Jenkins build number, used for image tagging.
These are set within the environment block in the Jenkinsfile.

CI/CD
A CI/CD pipeline is defined using Jenkins and Gogs, deployed within the Kubernetes cluster.

Pipeline Overview
SCM Trigger: Changes pushed to the Gogs widgetario repository can trigger the Jenkins pipeline (manual trigger is default setup).
Build: Jenkins checks out the code and builds Docker images for each microservice (products-api, stock-api, products-db, web).
Push: The newly built images are tagged with the build number and pushed to the configured Docker registry.
Deploy: Jenkins uses Helm to deploy/upgrade the Widgetario application in the test namespace, using the images pushed in the previous step and values from smoke-test.json.
Test: Basic rollout status checks are performed. Placeholder for more comprehensive smoke tests.
Jenkinsfile Stages
The Jenkinsfile defines the following stages:

Prepare: Logs in to the Docker registry.
Build: Builds Docker images for all application components in parallel.
Products API
Stock API
Products DB
Web
Push: Pushes the built images to the Docker registry.
Deploy: Deploys the application to the test environment using helm upgrade --install. It overrides image repositories and tags with the current build's images.
Test: Waits for deployments and statefulsets to complete rollout. Includes a placeholder for actual smoke test commands.
Post: Always logs out of Docker registry. Reports success or failure.
Workflow Files
Jenkinsfile: The core declarative pipeline script.
ci-cd/deploy-cicd.ps1: Script to bootstrap Jenkins and Gogs.
ci-cd/jenkins-deployment.yaml: Kubernetes manifests for Jenkins.
ci-cd/gogs-deployment.yaml: Kubernetes manifests for Gogs.
Troubleshooting & FAQs
Refer to the ci-cd/README.md for initial troubleshooting steps for the CI/CD components.

Checking Pod Status
Bash

kubectl get pods -n <namespace>
# Examples:
kubectl get pods -n test        # For Widgetario application pods
kubectl get pods -n ci-cd       # For Jenkins, Gogs
kubectl get pods -n kube-logging # For EFK stack
kubectl get pods -n monitoring  # For Prometheus, Grafana
kubectl get pods -n nginx-ingress # For Ingress controller
Checking Pod Logs
Bash

kubectl logs <pod-name> -n <namespace>
# To follow logs:
kubectl logs -f <pod-name> -n <namespace>
For issues during CI/CD pipeline execution, check Jenkins pod logs and the build console output in the Jenkins UI.

Checking Helm Releases
Bash

helm list -n <namespace>
helm status <release-name> -n <namespace>
helm history <release-name> -n <namespace>
Accessing Dashboards
Jenkins: http://localhost:<JENKINS_NODE_PORT> (from deploy-cicd.ps1 output)
Gogs: http://localhost:<GOGS_NODE_PORT> (from deploy-cicd.ps1 output)
Kibana: Port-forward svc/kibana -n kube-logging to 5601. Access http://localhost:5601.
Grafana: Access via Ingress http://monitoring.widgetario.local (if DNS configured) or port-forward svc/grafana -n monitoring to 3000. Access http://localhost:3000.
Prometheus: Port-forward svc/prometheus-service -n monitoring to 9090. Access http://localhost:9090.
Contributing
Currently, formal contribution guidelines are not specified. If you wish to contribute:

Fork the repository (if on a platform like GitHub/GitLab, or your Gogs instance).
Create a new branch for your feature or bug fix (e.g., feature/my-new-feature or fix/issue-123).
Make your changes.
Ensure your code lints and any tests pass (if applicable).
Commit your changes with clear, descriptive messages.
Push your branch to your fork.
Open a Pull Request (or merge request) against the main repository's master (or main) branch.
Code Style: (Not specified - please define, e.g., "Follow PEP 8 for Python," "Use Prettier for JSON/YAML.")
Commit Messages: (Not specified - consider Conventional Commits or similar.)

Issues: Please open an issue in the Gogs repository (or primary issue tracker) for any bugs or feature requests.

License & Authors
License: TBD (To Be Determined). Please add a LICENSE file to the repository (e.g., MIT, Apache 2.0).
If using MIT, the SPDX identifier is MIT.

Authors:

Dave Manufor (Implied from repository name)
Daryn Ongera
Nyakio Ndambiri
Ogoro Ruth


Appendix
Kubernetes Documentation
Helm Documentation
Jenkins Documentation
Gogs Documentation
NGINX Ingress Controller Docs
Elasticsearch Reference
Fluentd Documentation
Kibana Guide
Prometheus Documentation
Grafana Documentation
Kubernetes CourseLabs Hackathon
<!-- end list -->
