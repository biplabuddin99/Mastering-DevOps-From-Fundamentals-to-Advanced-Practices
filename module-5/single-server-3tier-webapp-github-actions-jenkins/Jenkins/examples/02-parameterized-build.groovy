// Example 2: Parameterized Build Pipeline
// Demonstrates accepting user input parameters and conditional execution
// Usage: Build with Parameters to provide values at runtime

pipeline {
    agent any
    
    parameters {
        string(
            name: 'USER_NAME',
            defaultValue: 'Guest',
            description: 'Enter your name'
        )
        choice(
            name: 'ENVIRONMENT',
            choices: ['Development', 'Staging', 'Production'],
            description: 'Select deployment environment'
        )
        booleanParam(
            name: 'RUN_TESTS',
            defaultValue: true,
            description: 'Run automated tests?'
        )
        text(
            name: 'DEPLOYMENT_NOTES',
            defaultValue: 'Regular deployment',
            description: 'Enter deployment notes'
        )
    }
    
    stages {
        stage('Display Parameters') {
            steps {
                echo "==================================="
                echo "Pipeline Parameters:"
                echo "==================================="
                echo "User Name: ${params.USER_NAME}"
                echo "Environment: ${params.ENVIRONMENT}"
                echo "Run Tests: ${params.RUN_TESTS}"
                echo "Notes: ${params.DEPLOYMENT_NOTES}"
                echo "==================================="
            }
        }
        
        stage('Conditional Test Execution') {
            when {
                expression { params.RUN_TESTS == true }
            }
            steps {
                echo "Running automated tests..."
                sh 'echo "✅ Test 1: PASSED"'
                sh 'echo "✅ Test 2: PASSED"'
                sh 'echo "✅ Test 3: PASSED"'
            }
        }
        
        stage('Deploy to Environment') {
            steps {
                script {
                    if (params.ENVIRONMENT == 'Production') {
                        echo "⚠️  WARNING: Deploying to PRODUCTION!"
                        echo "Deployment initiated by: ${params.USER_NAME}"
                    } else {
                        echo "Deploying to ${params.ENVIRONMENT}"
                    }
                }
                
                echo "Deployment completed successfully!"
            }
        }
    }
    
    post {
        success {
            echo "Pipeline completed by ${params.USER_NAME}"
            echo "Target environment: ${params.ENVIRONMENT}"
        }
    }
}
