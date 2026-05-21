// Example 1: Hello World Pipeline
// The simplest pipeline to verify Jenkins is working correctly
// Usage: Copy this to Jenkins Pipeline job or reference from SCM

pipeline {
    agent any
    
    stages {
        stage('Hello') {
            steps {
                echo 'Hello, Jenkins!'
                echo 'This is my first pipeline'
            }
        }
        
        stage('System Info') {
            steps {
                echo 'Displaying system information...'
                sh 'echo "Hostname: $(hostname)"'
                sh 'echo "User: $(whoami)"'
                sh 'echo "Date: $(date)"'
                sh 'echo "Current directory: $(pwd)"'
            }
        }
        
        stage('Goodbye') {
            steps {
                echo 'Pipeline completed successfully!'
            }
        }
    }
    
    post {
        always {
            echo 'This runs regardless of pipeline result'
        }
        success {
            echo '✅ Pipeline succeeded!'
        }
        failure {
            echo '❌ Pipeline failed!'
        }
    }
}
