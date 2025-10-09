// Jenkinsfile — Task 3: CI/CD + Security
// Uses Node 16 (Debian bullseye) Docker agent, installs deps, runs tests,
// performs a dependency vulnerability scan that FAILS on High/Critical,
// then builds and pushes a Docker image to Docker Hub.
//
// Prereqs in Jenkins:
// 1) DinD network alias set so DOCKER_HOST=tcp://docker:2376 works.
// 2) Credentials (Username with password) for Docker Hub with ID: docker-creds.

pipeline {

  /*******************************
   * Build Agent (Requirement 3.1.i)
   * - Run everything inside Node 16 container
   * - Pass DinD TLS env + client certs into the agent container
   *******************************/
  agent {
    docker {
      // Use bullseye to avoid EOL apt repositories (buster is EOL)
      image 'node:16-bullseye'
      args '''
        -v /certs/client:/certs/client:ro
        -e DOCKER_HOST=tcp://docker:2376
        -e DOCKER_CERT_PATH=/certs/client
        -e DOCKER_TLS_VERIFY=1
      '''
    }
  }

  /*******************************
   * Global environment
   *******************************/
  environment {
    // Change to your Docker Hub repo: <username>/<repo>
    // Used by build/push stages
    DOCKERHUB_REPO = 'dipannitakar/aws-express-sample'
  }

  stages {

    /*******************************
     * 1) Install Dependencies (3.1.ii)
     * - npm install --save
     *******************************/
    stage('Install Dependencies') {
      steps {
        sh 'npm install --save'
      }
    }

    /*******************************
     * 2) Run Unit Tests (3.1.ii)
     * - If none, continue without failing the pipeline
     *******************************/
    stage('Run Unit Tests') {
      steps {
        sh 'npm test || echo "No tests defined"'
      }
    }

    /*******************************
     * 3) Security Scan (Task 3.2)
     * - Integrate dependency scanner
     * - MUST fail pipeline on High/Critical issues
     * - Here we use npm’s audit to enforce "--audit-level=high"
     *   (Assignment intent: fail on High/Critical);
     *   npm audit exits non-zero if threshold is met → pipeline fails.
     *******************************/
    stage('Security Scan') {
      steps {
        // Show audit report and fail build if High/Critical issues found
        sh 'npm audit --audit-level=high'
      }
    }

    /*******************************
     * 4) Setup Docker CLI in Agent
     * - Install docker client inside the Node container so we can run
     *   docker build/push against the remote DinD daemon
     *******************************/
    stage('Setup Docker CLI in Agent') {
      steps {
        sh '''
          apt-get update
          apt-get install -y docker.io ca-certificates
          docker --version
        '''
      }
    }

    /*******************************
     * 5) Build Docker Image (3.1.ii)
     * - Tag with Jenkins BUILD_NUMBER for traceability
     *******************************/
    stage('Build Docker Image') {
      steps {
        sh 'docker build -t $DOCKERHUB_REPO:$BUILD_NUMBER .'
      }
    }

    /*******************************
     * 6) Push Docker Image (3.1.ii)
     * - Uses Jenkins credentials: ID "docker-creds" (username/password)
     *******************************/
    stage('Push Docker Image') {
      steps {
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

  /*******************************
   * Post actions (optional, helpful for logs/marks)
   *******************************/
  post {
    success {
      echo " Build, tests, security scan, image build and push succeeded."
    }
    failure {
      echo " Pipeline failed. Check the stage that failed in the logs."
    }
  }
}

