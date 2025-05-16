pipeline {
    agent any
    
    environment {
        REGISTRY = "index.docker.io"
        REGISTRY_USER = credentials('docker-hub-user')
        REGISTRY_PASS = credentials('docker-hub-pass')
        REGISTRY_REPO = "${REGISTRY_USER}/widgetario"
        BUILD_VERSION = "${BUILD_NUMBER}"
    }
    
    stages {
        stage('Prepare') {
            steps {
                sh 'echo Building version: ${BUILD_VERSION}'
                sh 'docker login -u ${REGISTRY_USER} -p ${REGISTRY_PASS} ${REGISTRY}'
            }
        }
        
        stage('Build') {
            parallel {
                stage('Products API') {
                    steps {
                        dir('widgetario/products-api') {
                            sh 'docker build -t ${REGISTRY_REPO}/products-api:${BUILD_VERSION} .'
                        }
                    }
                }
                stage('Stock API') {
                    steps {
                        dir('widgetario/stock-api') {
                            sh 'docker build -t ${REGISTRY_REPO}/stock-api:${BUILD_VERSION} .'
                        }
                    }
                }
                stage('Products DB') {
                    steps {
                        dir('widgetario/products-db') {
                            sh 'docker build -t ${REGISTRY_REPO}/products-db:${BUILD_VERSION} .'
                        }
                    }
                }
                stage('Web') {
                    steps {
                        dir('widgetario/web') {
                            sh 'docker build -t ${REGISTRY_REPO}/web:${BUILD_VERSION} .'
                        }
                    }
                }
            }
        }
        
        stage('Push') {
            steps {
                sh 'docker push ${REGISTRY_REPO}/products-api:${BUILD_VERSION}'
                sh 'docker push ${REGISTRY_REPO}/stock-api:${BUILD_VERSION}'
                sh 'docker push ${REGISTRY_REPO}/products-db:${BUILD_VERSION}'
                sh 'docker push ${REGISTRY_REPO}/web:${BUILD_VERSION}'
            }
        }
        
        stage('Deploy') {
            steps {
                sh '''
                # Deploy to test environment using Helm
                helm upgrade --install widgetario-test ./widgetario-helm \
                  --namespace test --create-namespace \
                  --values ./widgetario-helm/smoke-test.json \
                  --set papi.image.repository=${REGISTRY_REPO}/products-api \
                  --set papi.image.tag=${BUILD_VERSION} \
                  --set sapi.image.repository=${REGISTRY_REPO}/stock-api \
                  --set sapi.image.tag=${BUILD_VERSION} \
                  --set pdb.image.repository=${REGISTRY_REPO}/products-db \
                  --set pdb.image.tag=${BUILD_VERSION} \
                  --set web.image.repository=${REGISTRY_REPO}/web \
                  --set web.image.tag=${BUILD_VERSION}
                '''
            }
        }
        
        stage('Test') {
            steps {
                sh '''
                # Wait for deployment to be ready
                kubectl rollout status deployment/widgetario-test-papi -n test
                kubectl rollout status deployment/widgetario-test-sapi -n test
                kubectl rollout status deployment/widgetario-test-web -n test
                kubectl rollout status statefulset/widgetario-test-pdb -n test
                
                # Run smoke tests
                echo "Running smoke tests against test environment..."
                # Add your test commands here
                '''
            }
        }
    }
    
    post {
        always {
            sh 'docker logout ${REGISTRY}'
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
