// Example 4: Git Integration Pipeline
// Demonstrates checking out code from Git repository and performing operations
// Supports both public and private repositories (with credentials)

pipeline {
    agent any
    
    environment {
        // Replace with your repository (public or use credentials for private)
        GIT_REPO = 'https://github.com/your-username/sample-project.git'
        GIT_BRANCH = 'main'
        // For private repos, set this to your credentials ID
        GIT_CREDENTIALS_ID = 'github-token'  // Optional: only for private repos
    }
    
    stages {
        stage('Checkout Code') {
            steps {
                echo '======================================'
                echo '📥 CHECKING OUT CODE FROM GIT'
                echo '======================================'
                echo "Repository: ${GIT_REPO}"
                echo "Branch: ${GIT_BRANCH}"
                
                // Method 1: Simple checkout (for public repos)
                // Uncomment below for public repos without credentials
                /*
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: "*/${GIT_BRANCH}"]],
                    userRemoteConfigs: [[url: "${GIT_REPO}"]]
                ])
                */
                
                // Method 2: With credentials (for private repos)
                // Uses Jenkins Credentials Manager
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: "*/${GIT_BRANCH}"]],
                    userRemoteConfigs: [[
                        url: "${GIT_REPO}",
                        credentialsId: "${GIT_CREDENTIALS_ID}"
                    ]]
                ])
                
                // Display checked out files
                sh '''
                    echo "Files in workspace:"
                    ls -lha
                    
                    echo "\nGit information:"
                    git log --oneline -5
                    
                    echo "\nCurrent branch:"
                    git branch
                '''
            }
        }
        
        stage('Analyze Code') {
            steps {
                echo '======================================'
                echo '🔍 ANALYZING CODE'
                echo '======================================'
                
                sh '''
                    echo "Counting files by type:"
                    echo "JavaScript files: $(find . -name "*.js" | wc -l)"
                    echo "Python files: $(find . -name "*.py" | wc -l)"
                    echo "Markdown files: $(find . -name "*.md" | wc -l)"
                    
                    echo "\nTotal lines of code:"
                    find . -type f \( -name "*.js" -o -name "*.py" -o -name "*.sh" \) -exec wc -l {} + | tail -1
                '''
            }
        }
        
        stage('Install Dependencies') {
            steps {
                echo '======================================'
                echo '📦 INSTALLING DEPENDENCIES'
                echo '======================================'
                
                script {
                    // Check if package.json exists (Node.js project)
                    if (fileExists('package.json')) {
                        echo "Node.js project detected"
                        sh 'npm --version || echo "npm not installed"'
                        // Uncomment to actually install:
                        // sh 'npm install'
                    }
                    
                    // Check if requirements.txt exists (Python project)
                    if (fileExists('requirements.txt')) {
                        echo "Python project detected"
                        sh 'python3 --version || echo "Python not installed"'
                        // Uncomment to actually install:
                        // sh 'pip3 install -r requirements.txt'
                    }
                    
                    // Check if Makefile exists
                    if (fileExists('Makefile')) {
                        echo "Makefile detected"
                        sh 'cat Makefile'
                    }
                }
            }
        }
        
        stage('Run Commands') {
            steps {
                echo '======================================'
                echo '⚙️  RUNNING PROJECT COMMANDS'
                echo '======================================'
                
                sh '''
                    # Simulate running project-specific commands
                    echo "Checking project structure..."
                    tree -L 2 || ls -R
                    
                    echo "\nChecking for README..."
                    if [ -f "README.md" ]; then
                        echo "README.md found:"
                        head -20 README.md
                    fi
                '''
            }
        }
    }
    
    post {
        success {
            echo '✅ Git integration pipeline completed successfully'
        }
        failure {
            echo '❌ Git integration pipeline failed'
        }
    }
}
