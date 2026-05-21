# Getting Started with Jenkins Pipelines

This guide introduces Jenkins pipeline concepts with practical examples, from basic "Hello World" to more complex multi-stage pipelines. These examples will help you understand Jenkins pipeline syntax before deploying the three-tier application.

---

## Table of Contents
1. [Jenkins Pipeline Basics](#jenkins-pipeline-basics)
2. [Pipeline Types](#pipeline-types)
3. [Example 1: Hello World Pipeline](#example-1-hello-world-pipeline)
4. [Example 2: Parameterized Build](#example-2-parameterized-build)
5. [Example 3: Multi-Stage Pipeline](#example-3-multi-stage-pipeline)
6. [Example 4: Git Integration Pipeline](#example-4-git-integration-pipeline)
7. [Example 5: Environment Variables](#example-5-environment-variables)
8. [Example 6: Conditional Execution](#example-6-conditional-execution)
9. [Common Pipeline Patterns](#common-pipeline-patterns)
10. [Troubleshooting Tips](#troubleshooting-tips)

---

## Jenkins Pipeline Basics

### What is a Jenkins Pipeline?

A **Jenkins Pipeline** is a suite of plugins that supports implementing and integrating continuous delivery pipelines into Jenkins. Pipelines are defined using code (Pipeline-as-Code) in a `Jenkinsfile`.

### Key Concepts

- **Stage**: A distinct phase in the pipeline (e.g., Build, Test, Deploy)
- **Step**: A single task within a stage (e.g., execute shell command, checkout code)
- **Agent**: Where the pipeline or stage executes (e.g., any, specific node, Docker container)
- **Post**: Actions to run after stages complete (e.g., cleanup, notifications)

### Pipeline Syntax Types

1. **Declarative Pipeline** (Recommended)
   - Simpler, more structured syntax
   - Easier for beginners
   - More opinionated with sensible defaults

2. **Scripted Pipeline**
   - More flexible, uses Groovy directly
   - Greater control but more complex
   - Better for advanced use cases

---

## Pipeline Types

### Method 1: Pipeline Job (Inline Script)
- Define pipeline script directly in Jenkins UI
- Good for testing and learning
- Not recommended for production

### Method 2: Pipeline from SCM (Jenkinsfile)
- Store Jenkinsfile in Git repository
- Version controlled with your code
- **Recommended for production**

---

## Example 1: Hello World Pipeline

The simplest pipeline to verify Jenkins is working correctly.

### Create the Pipeline Job

1. **Jenkins Dashboard** → **New Item**
2. **Name**: `hello-world-pipeline`
3. **Type**: Pipeline
4. **Click OK**

### Pipeline Configuration

**Scroll to "Pipeline" section** and enter this script:

```groovy
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
```

### Run the Pipeline

1. **Click "Save"**
2. **Click "Build Now"** in the left sidebar
3. **Click on Build #1** to view details
4. **Click "Console Output"** to see execution logs

### Expected Output

```
Started by user admin
Running in Durability level: MAX_SURVIVABILITY
[Pipeline] Start of Pipeline
[Pipeline] node
[Pipeline] {
[Pipeline] stage (Hello)
[Pipeline] { (Hello)
[Pipeline] echo
Hello, Jenkins!
[Pipeline] echo
This is my first pipeline
[Pipeline] }
[Pipeline] stage (System Info)
[Pipeline] { (System Info)
[Pipeline] echo
Displaying system information...
[Pipeline] sh
+ echo 'Hostname: ip-172-31-45-123'
Hostname: ip-172-31-45-123
[Pipeline] sh
+ echo 'User: jenkins'
User: jenkins
...
[Pipeline] End of Pipeline
✅ Pipeline succeeded!
Finished: SUCCESS
```

---

## Example 2: Parameterized Build

Create a pipeline that accepts user input parameters.

### Create Pipeline Job

1. **New Item** → Name: `parameterized-pipeline` → Pipeline → OK

### Pipeline Script

```groovy
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
```

### Run with Parameters

1. **Save the pipeline**
2. **Click "Build with Parameters"** (appears after first save)
3. **Fill in the form**:
   - User Name: `John Doe`
   - Environment: `Staging`
   - Run Tests: ☑ Checked
   - Deployment Notes: `Testing parameter functionality`
4. **Click "Build"**

### Use Cases

- Deploy to different environments
- Toggle feature flags
- Provide version numbers
- Enter approval notes
- Configure build options

---

## Example 3: Multi-Stage Pipeline

A more realistic pipeline with build, test, and deploy stages.

### Create Pipeline Job

**New Item** → Name: `multi-stage-pipeline` → Pipeline → OK

### Pipeline Script

```groovy
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
```

### Key Features Demonstrated

- **Environment variables**: Global variables accessible in all stages
- **Multiple stages**: Organized workflow steps
- **Shell commands**: Using `sh` step for Linux commands
- **Script blocks**: Groovy code for conditional logic
- **Post actions**: Different actions based on pipeline result
- **Build metadata**: Using Jenkins built-in variables

---

## Example 4: Git Integration Pipeline

Pipeline that clones a Git repository and performs operations.

### Prerequisites

- **Git plugin** installed (comes with suggested plugins)
- **Public Git repository** URL (or private with credentials configured)

### Create Pipeline Job

**New Item** → Name: `git-integration-pipeline` → Pipeline → OK

### Pipeline Script

```groovy
pipeline {
    agent any
    
    environment {
        // Replace with your repository
        GIT_REPO = 'https://github.com/your-username/sample-project.git'
        GIT_BRANCH = 'main'
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
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: "*/${GIT_BRANCH}"]],
                    userRemoteConfigs: [[url: "${GIT_REPO}"]]
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
```

### For Private Repositories

If using a private repository, add credentials:

1. **Manage Jenkins** → **Credentials** → **System** → **Global credentials**
2. **Add Credentials**:
   - Kind: Username with password (or SSH Username with private key)
   - Username: Your Git username
   - Password/Key: Your Git password or SSH key
   - ID: `git-credentials`

**Update pipeline to use credentials:**

```groovy
checkout([
    $class: 'GitSCM',
    branches: [[name: "*/${GIT_BRANCH}"]],
    userRemoteConfigs: [[
        url: "${GIT_REPO}",
        credentialsId: 'git-credentials'
    ]]
])
```

---

## Example 5: Environment Variables

Demonstrates various ways to use and manipulate environment variables.

### Pipeline Script

```groovy
pipeline {
    agent any
    
    environment {
        // Global environment variables (available to all stages)
        GLOBAL_VAR = 'I am global'
        APP_VERSION = '1.2.3'
        BUILD_DATE = sh(script: 'date +%Y%m%d', returnStdout: true).trim()
        
        // Using credentials (example - requires credential to be configured)
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
```

### Key Concepts

- **Global variables**: Defined in `environment` block at pipeline level
- **Stage variables**: Defined in `environment` block at stage level
- **Built-in variables**: Provided by Jenkins (e.g., `BUILD_NUMBER`)
- **Dynamic variables**: Set using `script` block
- **Credentials**: Sensitive data stored securely

---

## Example 6: Conditional Execution

Pipeline with conditional stages and steps.

### Pipeline Script

```groovy
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
                    
                    // In real scenario, use input step:
                    // input message: 'Deploy to production?', 
                    //       ok: 'Deploy',
                    //       submitter: 'admin'
                    
                    echo '✅ Approval received (simulated)'
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
                    // Send notification here
                } else {
                    echo "✅ ${params.DEPLOY_ENV} deployment successful"
                }
            }
        }
    }
}
```

### `when` Directive Options

```groovy
when {
    // Branch condition
    branch 'main'
    
    // Environment condition
    environment name: 'DEPLOY_ENV', value: 'production'
    
    // Expression condition
    expression { return params.RUN_TESTS }
    
    // Multiple conditions (all must be true)
    allOf {
        branch 'main'
        environment name: 'ENV', value: 'prod'
    }
    
    // Any condition can be true
    anyOf {
        branch 'main'
        branch 'develop'
    }
    
    // Negation
    not {
        branch 'main'
    }
}
```

---

## Common Pipeline Patterns

### Pattern 1: Parallel Execution

Run multiple stages simultaneously:

```groovy
pipeline {
    agent any
    stages {
        stage('Parallel Tests') {
            parallel {
                stage('Unit Tests') {
                    steps {
                        echo 'Running unit tests...'
                        sh 'sleep 5 && echo "Unit tests completed"'
                    }
                }
                stage('Integration Tests') {
                    steps {
                        echo 'Running integration tests...'
                        sh 'sleep 5 && echo "Integration tests completed"'
                    }
                }
                stage('Linting') {
                    steps {
                        echo 'Running linter...'
                        sh 'sleep 3 && echo "Linting completed"'
                    }
                }
            }
        }
    }
}
```

### Pattern 2: Error Handling

```groovy
pipeline {
    agent any
    stages {
        stage('Risky Operation') {
            steps {
                script {
                    try {
                        sh 'exit 1'  // Command that fails
                    } catch (Exception e) {
                        echo "⚠️ Command failed: ${e.message}"
                        echo "Continuing with alternative approach..."
                        sh 'echo "Alternative successful"'
                    }
                }
            }
        }
    }
}
```

### Pattern 3: Timeout

```groovy
pipeline {
    agent any
    stages {
        stage('With Timeout') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    sh 'echo "This will timeout after 5 minutes"'
                    // Your long-running command here
                }
            }
        }
    }
}
```

### Pattern 4: Retry

```groovy
pipeline {
    agent any
    stages {
        stage('Flaky Test') {
            steps {
                retry(3) {
                    sh 'echo "Attempting flaky operation..."'
                    // Command that might fail
                }
            }
        }
    }
}
```

---

## Troubleshooting Tips

### Issue: "Agent is offline"

**Solution:**
```groovy
// Use 'any' agent or specific label
agent any
// or
agent { label 'linux' }
```

### Issue: "Permission denied" on shell scripts

**Solution:**
```groovy
sh 'chmod +x script.sh && ./script.sh'
```

### Issue: Variables not interpolating

**Problem:**
```groovy
sh 'echo ${MY_VAR}'  // ❌ Won't work in single quotes
```

**Solution:**
```groovy
sh "echo ${MY_VAR}"  // ✅ Use double quotes
// or
sh '''
    echo $MY_VAR      // ✅ Use shell variable
'''
```

### Issue: Pipeline syntax errors

**Validate syntax:**
1. **Jenkins Dashboard** → **Pipeline Syntax**
2. Use **Pipeline Syntax Generator** tool
3. **Declarative Directive Generator** for correct syntax

### Issue: Workspace not clean

**Solution:**
```groovy
post {
    always {
        cleanWs()  // Clean workspace after build
    }
}
```

---

## Summary

You've learned:
- ✅ Basic "Hello World" pipeline
- ✅ Parameterized builds with user input
- ✅ Multi-stage pipelines with build/test/deploy
- ✅ Git integration for repository checkout
- ✅ Environment variable management
- ✅ Conditional execution with `when` directive
- ✅ Common patterns: parallel, error handling, timeouts

---

## Next Steps

Now you're ready to:

1. **Create more complex pipelines** for your specific needs
2. **Integrate with version control** (GitHub, GitLab, Bitbucket)
3. **Deploy applications** using [ThreeTierWithJenkins.md](./ThreeTierWithJenkins.md)
4. **Set up webhooks** for automatic builds on code push
5. **Configure notifications** (email, Slack, Discord)

---

## Additional Resources

- **Jenkins Pipeline Documentation**: https://www.jenkins.io/doc/book/pipeline/
- **Pipeline Syntax Reference**: https://www.jenkins.io/doc/book/pipeline/syntax/
- **Pipeline Steps Reference**: https://www.jenkins.io/doc/pipeline/steps/
- **Pipeline Examples**: https://www.jenkins.io/doc/pipeline/examples/
- **Best Practices**: https://www.jenkins.io/doc/book/pipeline/pipeline-best-practices/

---

**Document Version**: 1.0  
**Last Updated**: December 30, 2025  
**Next Guide**: [ThreeTierWithJenkins.md](./ThreeTierWithJenkins.md)
