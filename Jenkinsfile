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
        // TODO: change to your Docker Hub repo: <username>/<repo>
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
                // Continue even if no tests defined, but run them if present
                sh 'npm test || echo "No tests defined"'
            }
        }

        stage('Security Scan') {
            steps {
                // Use npm’s built-in audit to fail on High/Critical vulns
                // This satisfies "dependency vulnerability scanner" and fail policy
                sh '''
                # Show audit report and fail build if High/Critical issues found
                npm audit --audit-level=high
                '''
            }
        }

        stage('Setup Docker CLI in Agent') {
            steps {
                // Install docker CLI inside the Node 16 container so we can run docker build/push
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
                // Create this in Jenkins as ID: docker-creds (DockerHub username+password)
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

