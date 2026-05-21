// Example 6: Conditional Execution
// Demonstrates conditional stages and steps based on parameters and expressions
// Shows approval gates and multiple when conditions

pipeline {
    agent any
    
    parameters {
        choice(
            name: 'DEPLOY_ENV',
            choices: ['dev', 'staging', 'production'],
            description: 'Deployment environment'
        )
        booleanParam(
            name: 'RUN_SECURITY_SCAN',
            defaultValue: false,
            description: 'Run security vulnerability scan?'
        )
    }
    
    stages {
        stage('Build') {
            steps {
                echo 'Building application...'
                sh 'echo "Build artifacts created"'
            }
        }
        
        stage('Test - Development') {
            when {
                expression { params.DEPLOY_ENV == 'dev' }
            }
            steps {
                echo '🧪 Running basic tests for development...'
                sh 'echo "✅ Unit tests passed"'
            }
        }
        
        stage('Test - Staging') {
            when {
                expression { params.DEPLOY_ENV == 'staging' }
            }
            steps {
                echo '🧪 Running comprehensive tests for staging...'
                sh 'echo "✅ Unit tests passed"'
                sh 'echo "✅ Integration tests passed"'
            }
        }
        
        stage('Test - Production') {
            when {
                expression { params.DEPLOY_ENV == 'production' }
            }
            steps {
                echo '🧪 Running full test suite for production...'
                sh 'echo "✅ Unit tests passed"'
                sh 'echo "✅ Integration tests passed"'
                sh 'echo "✅ E2E tests passed"'
            }
        }
        
        stage('Security Scan') {
            when {
                expression { params.RUN_SECURITY_SCAN == true }
            }
            steps {
                echo '🔒 Running security vulnerability scan...'
                sh '''
                    echo "Scanning dependencies..."
                    sleep 2
                    echo "✅ No critical vulnerabilities found"
                '''
            }
        }
        
        stage('Approval for Production') {
            when {
                expression { params.DEPLOY_ENV == 'production' }
            }
            steps {
                script {
                    echo '⚠️  Production deployment requires approval'
                    
                    // In real scenario, use input step for manual approval:
                    // Uses Jenkins user permissions
                    timeout(time: 1, unit: 'HOURS') {
                        input(
                            message: 'Deploy to production?', 
                            ok: 'Deploy',
                            submitter: 'admin,ops-team'  // Only these users can approve
                        )
                    }
                    
                    echo '✅ Approval received'
                }
            }
        }
        
        stage('Deploy') {
            steps {
                script {
                    echo "🚀 Deploying to ${params.DEPLOY_ENV}..."
                    
                    switch(params.DEPLOY_ENV) {
                        case 'dev':
                            sh 'echo "Deploying to http://dev.example.com"'
                            break
                        case 'staging':
                            sh 'echo "Deploying to http://staging.example.com"'
                            break
                        case 'production':
                            sh 'echo "Deploying to http://example.com"'
                            break
                    }
                    
                    echo "✅ Deployment to ${params.DEPLOY_ENV} completed!"
                }
            }
        }
    }
    
    post {
        success {
            script {
                if (params.DEPLOY_ENV == 'production') {
                    echo '🎉 Production deployment successful!'
                    // Send notification here (email, Slack, etc.)
                } else {
                    echo "✅ ${params.DEPLOY_ENV} deployment successful"
                }
            }
        }
    }
}
