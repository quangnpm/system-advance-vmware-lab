pipeline {
    agent any
    triggers { pollSCM('H/1 * * * *') }
    options { timestamps(); disableConcurrentBuilds() }
    environment {
        TARGET_HOST = '192.168.1.131'
        TARGET_USER = 'labdeploy'
        SSH_CREDENTIALS_ID = 'lab-target-key'
        DEPLOY_DIR = '/home/labdeploy/system-advance-lab'
        ENABLE_K8S = 'true'
    }
    stages {
        stage('Validate') {
            steps {
                sh '''
                    test -s app/index.html
                    grep -q '<html' app/index.html
                    test -f Dockerfile
                    test -f compose.yaml
                    docker compose -f compose.yaml config --quiet
                '''
            }
        }
        stage('Prepare Ansible') {
            steps { sh 'ansible-galaxy collection install -r ansible/requirements.yml' }
        }
        stage('Deploy to local VM') {
            steps {
                writeFile file: 'ansible/inventory.ini', text: """[web]
${env.TARGET_HOST} ansible_user=${env.TARGET_USER}

[web:vars]
ansible_python_interpreter=/usr/bin/python3
"""
                withCredentials([sshUserPrivateKey(credentialsId: env.SSH_CREDENTIALS_ID,
                                                   keyFileVariable: 'SSH_KEY',
                                                   usernameVariable: 'SSH_USER')]) {
                    sh '''
                        ansible-playbook -i ansible/inventory.ini ansible/site.yml \\
                          --private-key "$SSH_KEY" \\
                          -u "$SSH_USER" \\
                          -e "deploy_dir=$DEPLOY_DIR"
                    '''
                }
            }
        }
        stage('Deploy to local Kubernetes (optional)') {
            when { expression { env.ENABLE_K8S == 'true' } }
            steps {
                sh '''
                    docker build -t system-advance-web:local .
                    kind load docker-image system-advance-web:local --name lab
                    kubectl apply -f k8s/
                    kubectl rollout status deployment/system-advance-web --timeout=120s
                '''
            }
        }
    }
    post {
        success { echo 'Deployment completed. Check the web page and container health.' }
        failure { echo 'Pipeline failed. Start with the first failing stage in the console log.' }
    }
}
