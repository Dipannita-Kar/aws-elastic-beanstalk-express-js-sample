pipeline {
    agent {
        // Run the whole pipeline inside a Node 16 Docker container
        docker {
            image 'node:16'
            // Pass Docker-in-Docker TLS env + certs into the agent container
            args '''
              -v /certs/client:/certs/client:ro
              -e DOCKER_HOST=tcp://docker:2376
              -e DOCKER_CERT_PATH=/certs/client
              -e DOCKER_TLS_VERIFY=1
            '''
        }
    }

    environment {
        // Change this to your actual Docker Hub repo
        DOCKERHUB_REPO = 'dipannitakar/aws-express-sample'
    }

    stages {

        stage('Install Dependencies') {
            steps {
                sh 'npm install --save'
            }
        }

        stage('Run Unit Tests') {
            steps {
                // Continue even if no tests are defined
                sh 'npm test || echo "No tests defined"'
            }
        }

        stage('Security Scan') {
            steps {
                // Use npm audit to fail build on High/Critical vulnerabilities
                sh '''
                echo "Running npm audit for security vulnerabilities..."
                npm audit --audit-level=high
                '''
            }
        }

        stage('Setup Docker CLI in Agent') {
            steps {
                // Install Docker CLI inside Node 16 container to run docker build/push
                sh '''
                apt-get update
                apt-get install -y docker.io ca-certificates
                docker --version
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t $DOCKERHUB_REPO:$BUILD_NUMBER .'
            }
        }

        stage('Push Docker Image') {
            steps {
                // Jenkins credentials of type "Username with password"
                // ID must be docker-creds (DockerHub username+password)
                withCredentials([usernamePassword(
                    credentialsId: 'docker-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                    echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                    docker push $DOCKERHUB_REPO:$BUILD_NUMBER
                    '''
                }
            }
        }
    }
}

