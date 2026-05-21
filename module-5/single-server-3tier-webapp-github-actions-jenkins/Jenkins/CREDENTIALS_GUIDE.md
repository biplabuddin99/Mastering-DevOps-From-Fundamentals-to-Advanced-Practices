# Jenkins Credentials Manager - Complete Guide

## Overview

This document confirms and explains how **ALL sensitive data** in this Jenkins integration uses the **Jenkins Credentials Manager**. No credentials, passwords, tokens, or private keys are hardcoded in the repository.

## ✅ Credentials Manager Usage Confirmation

### What is Jenkins Credentials Manager?

Jenkins Credentials Manager is a centralized, secure vault for storing sensitive information. Credentials are stored encrypted and injected into pipelines at runtime using credential IDs.

**Benefits:**
- ✅ Credentials never appear in pipeline code
- ✅ Encrypted storage in Jenkins
- ✅ Access control and audit logging
- ✅ Easy rotation without code changes
- ✅ No credentials committed to Git repository

---

## Required Credentials

### 1. EC2 SSH Access: `ec2-ssh-key`

**Type:** SSH Username with private key  
**Purpose:** Connect to EC2 instances for deployment  
**Used in:** All deployment stages

**Setup:**
```
Jenkins Dashboard → Manage Jenkins → Credentials → System → Global credentials

Add Credentials:
- Kind: SSH Username with private key
- ID: ec2-ssh-key
- Description: EC2 Ubuntu Server SSH Access
- Username: ubuntu
- Private Key: [Enter directly or from file]
- Passphrase: [If your key has one]
```

**Usage in Jenkinsfile:**
```groovy
environment {
    EC2_SSH_KEY_ID = 'ec2-ssh-key'  // Credential ID reference
}

stage('Deploy') {
    steps {
        script {
            // Jenkins injects SSH key at runtime - no key in code
            sshagent([env.EC2_SSH_KEY_ID]) {
                sh """
                    ssh -o StrictHostKeyChecking=no ${EC2_USER}@${TARGET_EC2_IP} '
                        echo "Connected securely"
                    '
                """
            }
        }
    }
}
```

---

### 2. Database Password: `db-password`

**Type:** Secret text  
**Purpose:** PostgreSQL database authentication  
**Used in:** Database setup and backend deployment

**Setup:**
```
Jenkins Dashboard → Manage Jenkins → Credentials → System → Global credentials

Add Credentials:
- Kind: Secret text
- Scope: Global
- Secret: [Your PostgreSQL password]
- ID: db-password
- Description: PostgreSQL Database Password
```

**Usage in Jenkinsfile:**
```groovy
environment {
    DB_PASSWORD_CREDENTIAL = 'db-password'
}

stage('Database Setup') {
    steps {
        script {
            // Jenkins injects password as environment variable at runtime
            withCredentials([string(credentialsId: env.DB_PASSWORD_CREDENTIAL, variable: 'DB_PASS')]) {
                sshagent([env.EC2_SSH_KEY_ID]) {
                    sh """
                        ssh ${EC2_USER}@${TARGET_EC2_IP} '
                            export POSTGRES_PASSWORD=\${DB_PASS}
                            # Password used securely, never logged
                        '
                    """
                }
            }
        }
    }
}
```

---

### 3. GitHub Access Token (Optional): `github-token`

**Type:** Secret text  
**Purpose:** Access private repositories  
**Used in:** Git checkout stage (if repository is private)

**Setup:**
```
Jenkins Dashboard → Manage Jenkins → Credentials → System → Global credentials

Add Credentials:
- Kind: Secret text
- Scope: Global
- Secret: [Your GitHub Personal Access Token]
- ID: github-token
- Description: GitHub Access Token for Private Repositories
```

**Usage in Jenkinsfile:**
```groovy
stage('Checkout') {
    steps {
        script {
            // For private repositories only
            checkout([
                $class: 'GitSCM',
                branches: [[name: "*/main"]],
                userRemoteConfigs: [[
                    url: 'https://github.com/your-org/private-repo.git',
                    credentialsId: 'github-token'  // Token injected by Jenkins
                ]]
            ])
        }
    }
}
```

**Note:** For public repositories, no GitHub token needed when using `checkout scm`.

---

### 4. Multi-Environment Credentials (Jenkinsfile.multibranch)

For multi-environment deployments, separate credentials per environment:

#### Production: `db-password-production`
```
- Kind: Secret text
- ID: db-password-production
- Secret: [Production DB password]
```

#### Staging: `db-password-staging`
```
- Kind: Secret text
- ID: db-password-staging
- Secret: [Staging DB password]
```

#### Development: `db-password-dev`
```
- Kind: Secret text
- ID: db-password-dev
- Secret: [Development DB password]
```

**Usage:**
```groovy
stage('Determine Environment') {
    steps {
        script {
            switch(env.BRANCH_NAME) {
                case 'main':
                case 'master':
                    env.DB_PASSWORD_CREDENTIAL = 'db-password-production'
                    break
                case 'staging':
                    env.DB_PASSWORD_CREDENTIAL = 'db-password-staging'
                    break
                case 'develop':
                case 'dev':
                    env.DB_PASSWORD_CREDENTIAL = 'db-password-dev'
                    break
            }
        }
    }
}
```

---

## How Credentials Are Used

### 1. SSH Authentication (`sshagent`)

```groovy
sshagent([env.EC2_SSH_KEY_ID]) {
    sh """
        ssh ${EC2_USER}@${TARGET_EC2_IP} 'command'
    """
}
```

**What happens:**
1. Jenkins retrieves SSH private key from credential `ec2-ssh-key`
2. Temporarily starts SSH agent with the key
3. Executes SSH commands with automatic authentication
4. Removes key from memory after execution
5. **Key never appears in logs or code**

---

### 2. Secret Injection (`withCredentials`)

```groovy
withCredentials([string(credentialsId: 'db-password', variable: 'DB_PASS')]) {
    sh """
        export POSTGRES_PASSWORD=${DB_PASS}
        # Use password
    """
}
```

**What happens:**
1. Jenkins retrieves secret from credential `db-password`
2. Injects it as environment variable `DB_PASS`
3. Variable available only within the `withCredentials` block
4. **Value automatically masked in console output**
5. Variable cleared after block execution

---

### 3. Git Credentials

```groovy
checkout([
    $class: 'GitSCM',
    userRemoteConfigs: [[
        url: 'https://github.com/user/repo.git',
        credentialsId: 'github-token'
    ]]
])
```

**What happens:**
1. Jenkins retrieves token from credential `github-token`
2. Uses token for Git authentication
3. **Token never exposed in logs**

---

## Security Best Practices

### ✅ What We Do Right

1. **No Hardcoded Secrets**
   - All sensitive data uses credential IDs
   - Repository contains NO passwords, keys, or tokens

2. **Credential Masking**
   - Secrets automatically masked in console output
   - Uses `withCredentials` for automatic masking

3. **Least Privilege**
   - Each credential has specific purpose
   - Separate credentials per environment

4. **Secure Transmission**
   - SSH keys never transmitted over network
   - Passwords injected as environment variables

5. **Audit Trail**
   - Jenkins logs all credential access
   - Can track who used which credentials when

### ❌ What We Avoid

1. **Never in Git**
   ```groovy
   // ❌ WRONG - Don't do this
   environment {
       DB_PASSWORD = 'MyPassword123'
       SSH_KEY = '-----BEGIN RSA PRIVATE KEY-----...'
   }
   ```

2. **Never in Logs**
   ```groovy
   // ❌ WRONG - Don't do this
   sh "echo 'Password: ${DB_PASSWORD}'"
   
   // ✅ RIGHT - Use credentials manager
   withCredentials([string(credentialsId: 'db-password', variable: 'DB_PASS')]) {
       sh "psql -U user"  // Password injected securely
   }
   ```

3. **Never in Plain Text Files**
   ```groovy
   // ❌ WRONG - Don't do this
   sh "echo 'password' > /tmp/pass.txt"
   ```

---

## Credential Rotation

When you need to update credentials:

1. **Update in Jenkins Only**
   ```
   Jenkins → Manage Jenkins → Credentials → [Select credential] → Update
   ```

2. **No Code Changes Needed**
   - Pipeline code references credential ID
   - ID stays the same, secret value changes
   - Next build automatically uses new credential

3. **No Git Commits Required**
   - Credentials stored in Jenkins, not Git
   - Change propagates immediately

---

## Verification Checklist

Use this checklist to verify proper credentials usage:

### Single Environment (Jenkinsfile)

- [ ] `ec2-ssh-key` created (SSH Username with private key)
- [ ] `db-password` created (Secret text)
- [ ] `github-token` created if repository is private (Secret text)
- [ ] All credentials added to Jenkins Credentials Manager
- [ ] No passwords or keys in Jenkinsfile
- [ ] `sshagent([env.EC2_SSH_KEY_ID])` used for SSH
- [ ] `withCredentials` used for database password
- [ ] Credentials tested in test pipeline

### Multi-Environment (Jenkinsfile.multibranch)

- [ ] `ec2-ssh-key` created
- [ ] `db-password-production` created
- [ ] `db-password-staging` created
- [ ] `db-password-dev` created
- [ ] `github-token` created if needed
- [ ] Environment-specific credential IDs configured
- [ ] Branch-based credential selection working
- [ ] All environments tested

---

## Troubleshooting

### "Could not find credentials matching ID"

**Problem:** Jenkins can't find credential with specified ID

**Solution:**
```bash
1. Check credential ID matches exactly (case-sensitive)
2. Verify credential scope is 'Global' or accessible to job
3. Check Jenkins → Credentials → System → Global credentials
4. Ensure credential exists and ID is correct
```

### "Permission denied (publickey)"

**Problem:** SSH authentication failing

**Solution:**
```bash
1. Verify SSH key format (PEM, OpenSSH)
2. Check key permissions on EC2 instance
3. Ensure username is correct (ubuntu for Ubuntu instances)
4. Test SSH manually: ssh -i key.pem ubuntu@ec2-ip
5. Verify credential ID 'ec2-ssh-key' exists in Jenkins
```

### "Authentication failed" for PostgreSQL

**Problem:** Database password incorrect

**Solution:**
```bash
1. Verify password in Jenkins credential matches DB
2. Check credential ID matches pipeline
3. Test password manually:
   psql -U myuser -d mydb -W
4. Update credential if password changed
```

### Credentials not being masked in logs

**Problem:** Passwords appearing in console output

**Solution:**
```groovy
// ✅ Use withCredentials for automatic masking
withCredentials([string(credentialsId: 'db-password', variable: 'DB_PASS')]) {
    sh 'use password here'  // Automatically masked
}

// ❌ Don't echo or print credentials
sh "echo ${DB_PASS}"  // Will be masked but don't do this
```

---

## Examples from Our Pipelines

### Example 1: Jenkinsfile - SSH and Database Password

```groovy
pipeline {
    agent any
    
    environment {
        EC2_SSH_KEY_ID = 'ec2-ssh-key'  // ✅ Credential ID
        DB_PASSWORD_CREDENTIAL = 'db-password'  // ✅ Credential ID
        TARGET_EC2_IP = '54.123.45.67'
    }
    
    stages {
        stage('Deploy Backend') {
            steps {
                script {
                    // ✅ Jenkins Credentials Manager injects SSH key
                    withCredentials([string(credentialsId: env.DB_PASSWORD_CREDENTIAL, variable: 'DB_PASS')]) {
                        sshagent([env.EC2_SSH_KEY_ID]) {
                            sh """
                                ssh ${EC2_USER}@${TARGET_EC2_IP} '
                                    cd /home/ubuntu/app/backend
                                    
                                    # ✅ Password injected securely
                                    cat > .env << EOF
POSTGRES_PASSWORD=\${DB_PASS}
EOF
                                    
                                    npm install
                                    pm2 restart backend
                                '
                            """
                        }
                    }
                }
            }
        }
    }
}
```

### Example 2: Jenkinsfile.multibranch - Environment-Specific Credentials

```groovy
stage('Determine Environment') {
    steps {
        script {
            switch(env.BRANCH_NAME) {
                case 'main':
                    env.ENVIRONMENT = 'production'
                    env.TARGET_EC2_IP = '54.123.45.67'
                    env.DB_PASSWORD_CREDENTIAL = 'db-password-production'  // ✅ Prod credential
                    break
                case 'staging':
                    env.ENVIRONMENT = 'staging'
                    env.TARGET_EC2_IP = '54.123.45.68'
                    env.DB_PASSWORD_CREDENTIAL = 'db-password-staging'  // ✅ Staging credential
                    break
                case 'develop':
                    env.ENVIRONMENT = 'development'
                    env.TARGET_EC2_IP = '54.123.45.69'
                    env.DB_PASSWORD_CREDENTIAL = 'db-password-dev'  // ✅ Dev credential
                    break
            }
        }
    }
}

stage('Deploy') {
    steps {
        script {
            // ✅ Uses environment-specific credential determined above
            withCredentials([string(credentialsId: env.DB_PASSWORD_CREDENTIAL, variable: 'DB_PASS')]) {
                sshagent([env.EC2_SSH_KEY_ID]) {
                    sh "deploy with \${DB_PASS}"
                }
            }
        }
    }
}
```

### Example 3: Private GitHub Repository

```groovy
stage('Checkout') {
    steps {
        script {
            // ✅ Jenkins injects GitHub token for private repo access
            checkout([
                $class: 'GitSCM',
                branches: [[name: "*/main"]],
                userRemoteConfigs: [[
                    url: 'https://github.com/your-org/private-repo.git',
                    credentialsId: 'github-token'  // ✅ GitHub token from Jenkins
                ]]
            ])
        }
    }
}
```

---

## Summary

### ✅ Confirmed: All Credentials Use Jenkins Credentials Manager

| Credential | Type | Usage | Jenkinsfile | Jenkinsfile.multibranch |
|------------|------|-------|-------------|------------------------|
| `ec2-ssh-key` | SSH Username with private key | EC2 SSH access | ✅ Yes | ✅ Yes |
| `db-password` | Secret text | PostgreSQL password | ✅ Yes | ❌ No |
| `db-password-production` | Secret text | Production DB | ❌ No | ✅ Yes |
| `db-password-staging` | Secret text | Staging DB | ❌ No | ✅ Yes |
| `db-password-dev` | Secret text | Development DB | ❌ No | ✅ Yes |
| `github-token` | Secret text | Private repo access | 🟡 Optional | 🟡 Optional |

### ✅ Security Guarantees

1. **No credentials in Git repository** - All sensitive data in Jenkins only
2. **Encrypted storage** - Jenkins stores credentials encrypted
3. **Automatic masking** - Secrets masked in console output
4. **Audit logging** - All credential access logged
5. **Easy rotation** - Update in Jenkins, no code changes
6. **Access control** - Jenkins authorization controls who can use credentials

### 🎯 Quick Start

1. Create credentials in Jenkins (see setup sections above)
2. Reference credentials by ID in pipeline code
3. Use `sshagent` for SSH keys
4. Use `withCredentials` for passwords/tokens
5. Never commit credentials to Git

---

## Additional Resources

- [Jenkins Credentials Plugin Documentation](https://plugins.jenkins.io/credentials/)
- [Using Credentials in Pipeline](https://www.jenkins.io/doc/book/pipeline/jenkinsfile/#handling-credentials)
- [SSH Agent Plugin](https://plugins.jenkins.io/ssh-agent/)
- [Credentials Binding Plugin](https://plugins.jenkins.io/credentials-binding/)

---

**Document Version:** 1.0  
**Last Updated:** 2024  
**Author:** Jenkins Integration Guide

---

## Need Help?

If you have questions about credentials setup or usage:

1. Check [ThreeTierWithJenkins.md](./ThreeTierWithJenkins.md) - Section 4.3 (Credentials Setup)
2. Review [CreateJenkinsServer.md](./CreateJenkinsServer.md) - Section 7 (Security)
3. Test with [examples/04-git-integration.groovy](./examples/04-git-integration.groovy)
4. Verify with [examples/05-environment-variables.groovy](./examples/05-environment-variables.groovy)
