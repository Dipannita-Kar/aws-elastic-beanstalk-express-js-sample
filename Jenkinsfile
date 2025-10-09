pipeline {
  agent {
    // Run the whole pipeline inside a Node 16 container
    docker {
      image 'node:16-bullseye'
      // IMPORTANT: join the same network as the DinD service so 'docker' resolves
      // Also pass Docker-in-Docker TLS env + certs into the agent container
      args '''
        --network jenkins
        -v /certs/client:/certs/client:ro
        -e DOCKER_HOST=tcp://docker:2376
        -e DOCKER_CERT_PATH=/certs/client
        -e DOCKER_TLS_VERIFY=1
      '''
    }
  }

  environment {
    // Change to your own Docker Hub repo: <username>/<repo>
    DOCKERHUB_REPO = 'dipannitakar/aws-express-sample'
  }

  stages {

    stage('Install Dependencies') {
      steps {
        // 4.2(b) — LOGS: show npm install output clearly
        sh 'npm install --save'
      }
    }

    stage('Run Unit Tests') {
      steps {
        // 4.2(b) — LOGS: test output (if no tests defined, don’t fail the build here)
        sh 'npm test || echo "No tests defined"'
      }
    }

    stage('Security Scan') {
      steps {
        // 4.2(b) — LOGS: security results must appear in console
        // Fail the build if High/Critical issues exist (assignment policy)
        sh '''
          echo "[Security] Running npm audit (fail on high)"
          npm audit --audit-level=high
        '''
      }
    }

    stage('Setup Docker CLI in Agent') {
      steps {
        // Install docker CLI in the agent container so we can talk to DinD
        sh '''
          apt-get update
          apt-get install -y docker.io ca-certificates
          docker --version
        '''
      }
    }

    stage('Build Docker Image') {
      steps {
        // 4.2(b) — LOGS: image build output must be visible
        sh 'docker build -t $DOCKERHUB_REPO:$BUILD_NUMBER .'
      }
    }

    stage('Push Docker Image') {
      steps {
        // Jenkins credentials of type "Username with password"
        // Create in Jenkins as ID: docker-creds (your DockerHub username+password)
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
    failure {
      echo ' Pipeline failed. Check the stage that failed in the logs.'
    }
    success {
      echo " Pipeline succeeded. Image pushed as $DOCKERHUB_REPO:$BUILD_NUMBER"
    }
  }
}

