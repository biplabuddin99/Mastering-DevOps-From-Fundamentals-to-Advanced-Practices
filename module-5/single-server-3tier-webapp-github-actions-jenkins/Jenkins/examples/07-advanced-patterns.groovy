// Example 7: Advanced Pipeline Patterns
// Demonstrates parallel execution, error handling, timeouts, and retries
// These are common patterns used in production pipelines

pipeline {
    agent any
    
    stages {
        stage('Parallel Execution') {
            // Run multiple stages simultaneously for faster execution
            parallel {
                stage('Unit Tests') {
                    steps {
                        echo 'Running unit tests...'
                        sh 'sleep 5 && echo "✅ Unit tests completed"'
                    }
                }
                
                stage('Integration Tests') {
                    steps {
                        echo 'Running integration tests...'
                        sh 'sleep 5 && echo "✅ Integration tests completed"'
                    }
                }
                
                stage('Linting') {
                    steps {
                        echo 'Running linter...'
                        sh 'sleep 3 && echo "✅ Linting completed"'
                    }
                }
                
                stage('Security Scan') {
                    steps {
                        echo 'Running security scan...'
                        sh 'sleep 4 && echo "✅ Security scan completed"'
                    }
                }
            }
        }
        
        stage('Error Handling') {
            steps {
                script {
                    echo 'Demonstrating error handling...'
                    
                    try {
                        // Simulate a command that might fail
                        sh 'echo "Attempting risky operation..."'
                        // sh 'exit 1'  // Uncomment to test error handling
                        echo "Operation succeeded"
                    } catch (Exception e) {
                        echo "⚠️ Operation failed: ${e.message}"
                        echo "Continuing with alternative approach..."
                        sh 'echo "✅ Alternative approach successful"'
                    } finally {
                        echo "Cleanup performed"
                    }
                }
            }
        }
        
        stage('Timeout Example') {
            steps {
                echo 'Stage with timeout constraint...'
                
                // This stage will abort if it takes longer than 5 minutes
                timeout(time: 5, unit: 'MINUTES') {
                    sh '''
                        echo "Running long operation..."
                        sleep 3
                        echo "✅ Operation completed within timeout"
                    '''
                }
            }
        }
        
        stage('Retry Example') {
            steps {
                echo 'Stage with retry logic...'
                
                // Retry up to 3 times if the operation fails
                retry(3) {
                    script {
                        echo "Attempt ${env.RETRY_COUNT ?: 1} of operation"
                        
                        // Simulate flaky operation
                        sh '''
                            echo "Attempting flaky operation..."
                            # Uncomment to test retry: exit 1
                            echo "✅ Operation succeeded"
                        '''
                    }
                }
            }
        }
        
        stage('When Directive Examples') {
            // Multiple when conditions demonstrated
            parallel {
                stage('Branch Specific') {
                    when {
                        branch 'main'
                    }
                    steps {
                        echo 'This only runs on main branch'
                    }
                }
                
                stage('Environment Specific') {
                    when {
                        environment name: 'DEPLOY_ENV', value: 'production'
                    }
                    steps {
                        echo 'This only runs for production environment'
                    }
                }
                
                stage('Multiple Conditions (allOf)') {
                    when {
                        allOf {
                            branch 'main'
                            environment name: 'ENV', value: 'prod'
                        }
                    }
                    steps {
                        echo 'This runs when ALL conditions are true'
                    }
                }
                
                stage('Multiple Conditions (anyOf)') {
                    when {
                        anyOf {
                            branch 'main'
                            branch 'develop'
                        }
                    }
                    steps {
                        echo 'This runs when ANY condition is true'
                    }
                }
                
                stage('Negation') {
                    when {
                        not {
                            branch 'main'
                        }
                    }
                    steps {
                        echo 'This runs on any branch EXCEPT main'
                    }
                }
            }
        }
        
        stage('Build with Workspace Cleanup') {
            steps {
                echo 'Building with clean workspace...'
                
                // Clean workspace before build
                cleanWs()
                
                sh 'echo "Building in clean workspace..."'
                sh 'echo "✅ Build completed"'
            }
        }
    }
    
    post {
        always {
            echo 'Pipeline completed - this always runs'
            
            // Archive artifacts for later retrieval
            // archiveArtifacts artifacts: '**/target/*.jar', allowEmptyArchive: true
            
            // Publish test results
            // junit '**/target/test-results/*.xml'
        }
        
        success {
            echo '✅ All stages completed successfully'
        }
        
        failure {
            echo '❌ Pipeline failed'
            
            // Send notification on failure
            // emailext subject: 'Build Failed', body: 'Check Jenkins', to: 'team@example.com'
        }
        
        unstable {
            echo '⚠️ Pipeline completed but marked as unstable'
        }
        
        cleanup {
            echo 'Cleaning up resources...'
            // Clean workspace after build (optional)
            // cleanWs()
        }
    }
}
