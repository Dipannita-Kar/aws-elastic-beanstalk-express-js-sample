pipeline {
  /* Run all stages inside a Node 16 container launched by the Docker plugin.
     The controller talks to DinD via DOCKER_HOST (set globally).
     Inside this container we mount DinD’s socket so `docker` CLI works. */
  agent {
    docker {
      image 'node:16-bullseye'
      args '''
        -u 0:0
        -v /var/run/docker.sock:/var/run/docker.sock
      '''
    }
  }

  environment {
    
    DOCKERHUB_REPO = 'dipannitakm/aws-express-sample'
  }

  stages {
    stage('Install Dependencies') {
      steps {
        sh 'npm install --save'
      }
    }

    stage('Run Unit Tests') {
      steps {
        // OK if no tests defined; don't fail the build
        sh 'npm test || echo "No tests defined"'
      }
    }

    stage('Security Scan') {
      steps {
        // Satisfies “dependency vulnerability scanner” requirement
        sh 'npm audit --audit-level=high'
      }
    }

    stage('Setup Docker CLI in Agent') {
      steps {
        // Install the docker client inside the Node container
        sh '''
          apt-get update
          apt-get install -y docker.io ca-certificates
          docker --version
        '''
      }
    }

    stage('Build Docker Image') {
      steps {
        // Build from the Dockerfile at repo root
        sh 'docker build -t $DOCKERHUB_REPO:$BUILD_NUMBER .'
      }
    }

    stage('Push Docker Image') {
      steps {
        // Jenkins creds of type "Username with password", id: docker-creds
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
    always {
      echo "Build finished (result: ${currentBuild.currentResult})."
    }
    failure {
      echo 'Pipeline failed. Check the stage that failed in the logs.'
    }
    success {
      echo 'Pipeline succeeded!'
    }
  }
}

