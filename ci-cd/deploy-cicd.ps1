# Deploy CI/CD infrastructure for Widgetario application
Write-Host "Setting up CI/CD environment for Widgetario..."

# Create namespace
kubectl create namespace ci-cd --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace test --dry-run=client -o yaml | kubectl apply -f -

# Deploy Jenkins
Write-Host "Deploying Jenkins..."
kubectl apply -f jenkins-deployment.yaml
Write-Host "Waiting for Jenkins to start..."

# Deploy Gogs
Write-Host "Deploying Gogs..."
kubectl apply -f gogs-deployment.yaml
Write-Host "Waiting for Gogs to start..."

# Create Docker registry secret
Write-Host "Creating registry secrets..."
kubectl create secret docker-registry regcred `
  --docker-server=https://index.docker.io/v1/ `
  --docker-username=your-username `
  --docker-password=your-password `
  --docker-email=your-email@example.com `
  --namespace=ci-cd `
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret docker-registry regcred `
  --docker-server=https://index.docker.io/v1/ `
  --docker-username=your-username `
  --docker-password=your-password `
  --docker-email=your-email@example.com `
  --namespace=test `
  --dry-run=client -o yaml | kubectl apply -f -

# Get the NodePort for Jenkins and Gogs
$JENKINS_PORT = kubectl get svc jenkins -n ci-cd -o jsonpath="{.spec.ports[0].nodePort}"
$GOGS_PORT = kubectl get svc gogs -n ci-cd -o jsonpath="{.spec.ports[0].nodePort}"

Write-Host "CI/CD setup complete!"
Write-Host "Jenkins will be available at: http://localhost:$JENKINS_PORT"
Write-Host "Gogs will be available at: http://localhost:$GOGS_PORT"
Write-Host ""
Write-Host "Next steps:"
Write-Host "1. Access Jenkins and set up credentials for Docker Hub"
Write-Host "2. Create a Jenkins pipeline job that uses the Jenkinsfile"
Write-Host "3. Set up Gogs and create a repository"
Write-Host "4. Push your code to Gogs repository"
Write-Host "5. Trigger the Jenkins pipeline to build and deploy"
