// Example 3: Multi-Stage Pipeline
// A realistic pipeline with build, test, and deploy stages
// Demonstrates environment variables and complex workflow

pipeline {
    agent any
    
    environment {
        APP_NAME = 'sample-app'
        BUILD_NUMBER_ENV = "${env.BUILD_NUMBER}"
        DEPLOYMENT_PATH = '/tmp/jenkins-demo'
    }
    
    stages {
        stage('Preparation') {
            steps {
                echo '======================================'
                echo '🔧 PREPARATION STAGE'
                echo '======================================'
                echo "App Name: ${APP_NAME}"
                echo "Build Number: ${BUILD_NUMBER_ENV}"
                echo "Jenkins URL: ${env.JENKINS_URL}"
                echo "Workspace: ${env.WORKSPACE}"
                
                // Clean workspace
                sh 'echo "Cleaning workspace..."'
                sh "mkdir -p ${DEPLOYMENT_PATH}"
            }
        }
        
        stage('Build') {
            steps {
                echo '======================================'
                echo '🏗️  BUILD STAGE'
                echo '======================================'
                
                // Simulate build process
                sh '''
                    echo "Compiling source code..."
                    sleep 2
                    echo "Creating build artifacts..."
                    sleep 1
                    echo "Build completed successfully!"
                '''
                
                // Create a dummy build artifact
                sh """
                    echo "Build #${BUILD_NUMBER_ENV}" > ${DEPLOYMENT_PATH}/build-info.txt
                    echo "Timestamp: \$(date)" >> ${DEPLOYMENT_PATH}/build-info.txt
                    cat ${DEPLOYMENT_PATH}/build-info.txt
                """
            }
        }
        
        stage('Test') {
            steps {
                echo '======================================'
                echo '🧪 TEST STAGE'
                echo '======================================'
                
                // Simulate test execution
                sh '''
                    echo "Running unit tests..."
                    sleep 2
                    echo "✅ Unit tests: 25 passed, 0 failed"
                    
                    echo "Running integration tests..."
                    sleep 2
                    echo "✅ Integration tests: 15 passed, 0 failed"
                    
                    echo "Running linting..."
                    sleep 1
                    echo "✅ Linting: No issues found"
                '''
            }
        }
        
        stage('Quality Gate') {
            steps {
                echo '======================================'
                echo '🎯 QUALITY GATE'
                echo '======================================'
                
                script {
                    def testsPassed = true
                    def codeCoverage = 85  // Simulated coverage
                    
                    if (codeCoverage >= 80) {
                        echo "✅ Code coverage: ${codeCoverage}% (Threshold: 80%)"
                    } else {
                        error "❌ Code coverage below threshold: ${codeCoverage}%"
                    }
                    
                    echo "✅ All quality gates passed!"
                }
            }
        }
        
        stage('Deploy') {
            steps {
                echo '======================================'
                echo '🚀 DEPLOYMENT STAGE'
                echo '======================================'
                
                // Simulate deployment
                sh """
                    echo "Deploying ${APP_NAME} build #${BUILD_NUMBER_ENV}..."
                    sleep 2
                    
                    echo "Copying artifacts to ${DEPLOYMENT_PATH}..."
                    echo "Application deployed successfully!" > ${DEPLOYMENT_PATH}/deployment.log
                    
                    echo "Deployment completed!"
                    ls -lh ${DEPLOYMENT_PATH}/
                """
            }
        }
        
        stage('Health Check') {
            steps {
                echo '======================================'
                echo '❤️  HEALTH CHECK'
                echo '======================================'
                
                sh '''
                    echo "Performing health checks..."
                    sleep 2
                    echo "✅ Application is responding"
                    echo "✅ Database connection successful"
                    echo "✅ All services healthy"
                '''
            }
        }
    }
    
    post {
        always {
            echo '======================================'
            echo 'PIPELINE COMPLETED'
            echo '======================================'
            echo "Duration: ${currentBuild.durationString}"
        }
        
        success {
            echo '✅ Pipeline succeeded! 🎉'
            echo "Build #${BUILD_NUMBER_ENV} deployed successfully"
        }
        
        failure {
            echo '❌ Pipeline failed! 😞'
            echo 'Please check the logs for errors'
        }
        
        cleanup {
            echo 'Cleaning up temporary files...'
            // In real scenario, clean up resources here
        }
    }
}
