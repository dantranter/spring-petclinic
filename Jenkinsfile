pipeline {
  agent {
    kubernetes {
        label 'kaniko'
        yaml """
apiVersion: v1
kind: Pod
metadata:
  name: kaniko
spec:
  containers:
  - name: maven
    image: maven:3.5.0
    command:
    - cat
    tty: true
  - name: kaniko
    image: gcr.io/kaniko-project/executor:debug
    imagePullPolicy: Always
    command:
    - /busybox/cat
    tty: true
    volumeMounts:
      - name: kaniko-secret
        mountPath: /secret
    env:
      - name: GOOGLE_APPLICATION_CREDENTIALS
        value: /secret/kaniko-secret.json
  restartPolicy: Never
  volumes:
    - name: kaniko-secret
      secret:
        secretName: kaniko-secret
"""
    }
  }
  stages {
    stage('Maven') {
      steps {
        container('maven') {
          sh 'mvn clean install'
        }
      }
    }
    stage('Docker Build') {
        steps {
            container(name:'kaniko', shell:'/busybox/sh') {
                sh '''#!/busybox/sh 
                    /kaniko/executor -f `pwd`/Dockerfile -c `pwd` --destination=gcr.io/cloudbees-public/bin-auth/petclinic:latest
                    '''
            }
        }
        post {
            success{
                echo "sign it"
            }
        }
    }
  }
}