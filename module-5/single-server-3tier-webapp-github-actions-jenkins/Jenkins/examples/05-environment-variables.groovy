// Example 5: Environment Variables
// Demonstrates various ways to use and manipulate environment variables
// Shows global, stage-specific, and dynamic variables

pipeline {
    agent any
    
    environment {
        // Global environment variables (available to all stages)
        GLOBAL_VAR = 'I am global'
        APP_VERSION = '1.2.3'
        BUILD_DATE = sh(script: 'date +%Y%m%d', returnStdout: true).trim()
        
        // Example: Using credentials from Jenkins Credentials Manager
        // Uncomment and configure credential ID in Jenkins first
        // DATABASE_PASSWORD = credentials('db-password-credential-id')
    }
    
    stages {
        stage('Display Environment Variables') {
            environment {
                // Stage-specific environment variable
                STAGE_VAR = 'I am stage-specific'
            }
            
            steps {
                echo '======================================'
                echo 'ENVIRONMENT VARIABLES'
                echo '======================================'
                
                // Custom variables
                echo "Global Variable: ${GLOBAL_VAR}"
                echo "Stage Variable: ${STAGE_VAR}"
                echo "App Version: ${APP_VERSION}"
                echo "Build Date: ${BUILD_DATE}"
                
                // Jenkins built-in variables
                echo "\nJenkins Built-in Variables:"
                echo "BUILD_NUMBER: ${env.BUILD_NUMBER}"
                echo "BUILD_ID: ${env.BUILD_ID}"
                echo "JOB_NAME: ${env.JOB_NAME}"
                echo "BUILD_URL: ${env.BUILD_URL}"
                echo "WORKSPACE: ${env.WORKSPACE}"
                echo "JENKINS_HOME: ${env.JENKINS_HOME}"
                echo "JENKINS_URL: ${env.JENKINS_URL}"
                
                // System environment variables
                echo "\nSystem Variables:"
                sh 'echo "USER: $USER"'
                sh 'echo "HOME: $HOME"'
                sh 'echo "PATH: $PATH"'
                sh 'echo "PWD: $PWD"'
            }
        }
        
        stage('Modify Variables') {
            steps {
                script {
                    // Dynamically set environment variables
                    env.DYNAMIC_VAR = "Set at runtime"
                    env.TIMESTAMP = sh(script: 'date +%s', returnStdout: true).trim()
                    
                    echo "Dynamic Variable: ${env.DYNAMIC_VAR}"
                    echo "Timestamp: ${env.TIMESTAMP}"
                    
                    // Conditional variable setting
                    if (env.BUILD_NUMBER.toInteger() > 5) {
                        env.BUILD_TYPE = "mature"
                    } else {
                        env.BUILD_TYPE = "initial"
                    }
                    
                    echo "Build Type: ${env.BUILD_TYPE}"
                }
            }
        }
        
        stage('Use Variables in Commands') {
            steps {
                sh '''
                    echo "Using shell variables:"
                    SHELL_VAR="I am a shell variable"
                    echo "Shell Variable: $SHELL_VAR"
                    
                    # Using Jenkins environment variables in shell
                    echo "Jenkins Job: $JOB_NAME"
                    echo "Build Number: $BUILD_NUMBER"
                    
                    # Create a file with build info
                    cat > /tmp/build-info-${BUILD_NUMBER}.txt << EOF
App Version: ${APP_VERSION}
Build Number: ${BUILD_NUMBER}
Build Date: ${BUILD_DATE}
Build Type: ${BUILD_TYPE}
EOF
                    
                    cat /tmp/build-info-${BUILD_NUMBER}.txt
                '''
            }
        }
    }
    
    post {
        always {
            echo "Pipeline completed for build #${env.BUILD_NUMBER}"
        }
    }
}
