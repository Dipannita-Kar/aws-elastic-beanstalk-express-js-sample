pipeline {
  agent {
    docker { image 'node:16' }
  }
  stages {
    stage('Smoke') {
      steps {
        sh 'node -v && npm -v'
      }
    }
  }
}

