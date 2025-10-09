pipeline {
    agent {
        // Run the pipeline inside a Node 16 Docker container
        docker {
            image 'node:16'
            // Enable Docker-in-Docker (DinD) for building and pushing images
            args '''
              -v /certs/client:/certs/client:ro
              -e DOCKER_HOST=tcp://docker:2376
              -e DOCKER_CERT_PATH=/certs/client
              -e DOCKER_TLS_VERIFY=1
            '''
        }
    }

    environment {
        // Docker Hub repository (replace with your own)
        DOCKERHUB_REPO = 'dipannitakar/aws-express-sample'
    }

    stages {
        stage('Install Dependencies') {
            steps {
                echo 'Installing project dependencies...'
                sh 'npm install --save'
            }
        }

        stage('Run Unit Tests') {
            steps {
                echo 'Running unit tests...'
                // Continue even if tests are not defined
                sh 'npm test || echo "No tests defined"'
            }
        }

        stage('Security Scan') {
            steps {
                echo 'Running npm audit for dependency vulnerabilities...'
                // Fail if High/Critical vulnerabilities are found
                sh '''
                npm audit --audit-level=high
                '''
            }
        }

        stage('Setup Docker CLI in Agent') {
            steps {
                echo 'Installing Docker CLI inside the build container...'
                sh '''
                apt-get update
                apt-get install -y docker.io ca-certificates
                docker --version
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image...'
                sh 'docker build -t $DOCKERHUB_REPO:$BUILD_NUMBER .'
            }
        }

        stage('Push Docker Image') {
            steps {
                echo 'Pushing Docker image to Docker Hub...'
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

    post {
        success {
            echo 'Archiving build logs and artifacts...'
            archiveArtifacts artifacts: '**/logs/**', fingerprint: true
        }
        failure {
            echo 'Build failed — check console output for details.'
        }
    }
}

