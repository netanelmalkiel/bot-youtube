pipeline {
    agent any
    environment {
        AWS_DEFAULT_REGION="us-east-1"
    }
    stages {
        stage(init) {
            steps {
                withCredentials([aws(accessKeyVariable: 'AWS_ACCESS_KEY_ID', credentialsId: 'natimalkiel-aws-creds', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                echo "initilazing.."      
                sh 'terraform init'
                }
            }
        } 
        stage(apply) {
            steps {
                withCredentials([aws(accessKeyVariable: 'AWS_ACCESS_KEY_ID', credentialsId: 'natimalkiel-aws-creds', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                echo "applying...."
                sh 'terraform apply -auto-approve'
                }
            }
         }
	stage(destroy) {
            steps {
                withCredentials([aws(accessKeyVariable: 'AWS_ACCESS_KEY_ID', credentialsId: 'natimalkiel-aws-creds', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                echo "destroying...."
                sh 'terraform destroy -auto-approve'
                }
            }
        }
    }
}
