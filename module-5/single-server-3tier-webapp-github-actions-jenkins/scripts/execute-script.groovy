pipeline {
    agent any

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Get EC2 Public IP') {
            steps {
                sh '''
                    chmod +x scripts/ec2-public-ip.sh
                    ./scripts/ec2-public-ip.sh
                '''
            }
        }
    }
}
