# Widgetario CI/CD Pipeline Setup

This guide explains how to set up and use the CI/CD pipeline for the Widgetario application.

## Prerequisites

- Kubernetes cluster (Docker Desktop with Kubernetes enabled)
- kubectl configured to access your cluster
- Helm installed
- Docker Hub account (or another container registry)

## Setup Instructions

### 1. Scale down existing deployments (if any)

```powershell
kubectl scale deploy/products-api deploy/stock-api deploy/web sts/products-db --replicas 0
```

### 2. Deploy CI/CD Infrastructure

```powershell
cd ci-cd
./deploy-cicd.ps1
```

This will:
- Create ci-cd and test namespaces
- Deploy Jenkins and Gogs
- Create Docker registry secrets
- Display URLs for accessing Jenkins and Gogs

### 3. Configure Jenkins

1. Access Jenkins using the URL provided by the deploy script
2. Add Docker Hub credentials:
   - Go to "Manage Jenkins" > "Manage Credentials"
   - Add credentials with ID `docker-hub-user` and `docker-hub-pass`

3. Create a new pipeline job:
   - Click "New Item", choose "Pipeline"
   - In the Pipeline section, select "Pipeline script from SCM"
   - Select "Git" as SCM
   - Enter your Gogs repository URL: `http://gogs:3000/gogs/widgetario.git`
   - Set Script Path to `Jenkinsfile`
   - Save the job

### 4. Configure Gogs

1. Access Gogs using the URL provided by the deploy script
2. Register a new user
3. Create a new repository called `widgetario`
4. Push your code to the Gogs repository:

```powershell
git init
git add .
git commit -m "Initial commit"
git remote add origin http://localhost:30080/username/widgetario.git
git push -u origin master
```

### 5. Run the Pipeline

1. Trigger the Jenkins pipeline manually
2. The pipeline will:
   - Build container images for all components
   - Push the images to Docker Hub
   - Deploy to the test namespace using Helm
   - Run tests

### 6. Access the Application

After successful deployment, you can access the application through:

```powershell
# Get the service URL
kubectl get svc -n test
```

## Pipeline Stages

1. **Prepare**: Log in to Docker Hub
2. **Build**: Build container images for all components
3. **Push**: Push images to Docker Hub
4. **Deploy**: Deploy the application to the test namespace using Helm
5. **Test**: Run smoke tests

## Helm Chart

The deployment uses our Helm chart located in the `widgetario-helm` directory. You can customize the deployment by:

1. Modifying `values.json` for default values
2. Using `smoke-test.json` for test environment deployments
3. Creating additional values files for different environments

## Troubleshooting

If you encounter issues:

1. Check pod status:
   ```powershell
   kubectl get pods -n test
   kubectl get pods -n ci-cd
   ```

2. Check pod logs:
   ```powershell
   kubectl logs <pod-name> -n <namespace>
   ```

3. Check Helm releases:
   ```powershell
   helm list -n test
   ```
