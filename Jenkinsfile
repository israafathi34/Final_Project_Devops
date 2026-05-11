@Library('depi-shared-library@main') _
// Note: If using filesystem-based library (not Git), configure in Jenkins UI:
// Manage Jenkins → Configure System → Global Pipeline Libraries
// Set "Default version" to "master" or leave empty, then you can use:
// @Library('depi-shared-library') _  (without @main)

pipeline {
    agent any
    
    environment {
        IMAGE_TAG    = "${env.BUILD_NUMBER}"
        ECR_REGISTRY = "532334935385.dkr.ecr.us-east-1.amazonaws.com"
        ECR_IMAGE    = "${ECR_REGISTRY}/depi"
        AWS_REGION   = "us-east-1"
        // GitHub credential ID (username/password) configured by Ansible from Vault; repo URL for push
        // GITHUB_CREDENTIAL_ID = "github-credentials"
        GITHUB_REPO_URL      = "https://github.com/israafathi34/Final_Project_Devops.git"
    }
    
    stages {
        
        stage('Checkout') {
            steps {
                echo "Cloning repository..."
                script {
                    def useManualClone = false
                    try {
                        checkout scm
                        echo "Using checkout scm (Pipeline from SCM)"
                    } catch (Exception e) {
                        echo "checkout scm not available, cloning manually..."
                        useManualClone = true
                        sh """
                            rm -rf Jenkins_App || true
                            git clone https://github.com/israafathi34/Final_Project_Devops.git
                        """
                    }
                    env.USE_MANUAL_CLONE = useManualClone.toString()
                }
            }
        }
        
        
        stage('BuildImage') {
            steps {
                script {
                    def workDir = env.USE_MANUAL_CLONE == 'true' ? 'Jenkins_App' : '.'
                    def imageName = "${ECR_IMAGE}:${IMAGE_TAG}"
                    buildImage(imageName, workDir, 'docker/Dockerfile')
                }
            }
        }

        stage('ScanImage') {
            steps {
                script {
                    def imageName = "${ECR_IMAGE}:${IMAGE_TAG}"
                    scanImage(imageName)
                }
            }
        }

        // stage('PushImage') {
        //     steps {
        //         script {
        //             def imageName = "${ECR_IMAGE}:${IMAGE_TAG}"
        //             pushImageECR(imageName, AWS_REGION)
        //         }
        //     }
        // }
        stage('PushImage') {
            steps {
                script {
                    echo "============================================"
                    echo "Stage: PushImageECR"
                    echo "============================================"

                    withCredentials([
                        string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                    ]) {

                        sh '''
                            echo "Configuring AWS credentials..."

                            aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
                            aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
                            aws configure set region us-east-1

                            echo "Logging into ECR..."

                            aws ecr get-login-password --region us-east-1 \
                            | docker login --username AWS --password-stdin 532334935385.dkr.ecr.us-east-1.amazonaws.com

                            echo "Pushing image..."

                            docker push 532334935385.dkr.ecr.us-east-1.amazonaws.com/depi:4
                            docker push 532334935385.dkr.ecr.us-east-1.amazonaws.com/depi:latest
                        '''
                    }
                }
            }
        }

        stage('RemoveImageLocally') {
            steps {
                script {
                    def imageName = "${ECR_IMAGE}:${IMAGE_TAG}"
                    removeImageLocally(imageName)
                }
            }
        }

        stage('UpdateManifests') {
            steps {
                script {
                    def imageUrl = "${ECR_IMAGE}:${IMAGE_TAG}"
                    def manifestsDir = env.USE_MANUAL_CLONE == 'true' ? 'Jenkins_App/k8s' : 'k8s'
                    updateManifests(imageUrl, manifestsDir)
                }
            }
        }

        stage('PushManifests') {
            steps {
                script {
                    def msg = "CI: update image to ${IMAGE_TAG}"
                    def manifestsDir = env.USE_MANUAL_CLONE == 'true' ? 'Jenkins_App/k8s' : 'k8s'
                    pushManifests(msg, manifestsDir, null, env.GITHUB_CREDENTIAL_ID, env.GITHUB_REPO_URL)
                }
            }
        }
    }
    
    post {
        always {
            echo "============================================"
            echo "POST ACTION: ALWAYS"
            echo "Pipeline execution completed"
            echo "============================================"
            deleteDir()
        }
        success {
            echo "============================================"
            echo "POST ACTION: SUCCESS"
            echo "Pipeline succeeded! Application deployed."
            echo "============================================"
        }
        failure {
            echo "============================================"
            echo "POST ACTION: FAILURE"
            echo "Pipeline failed! Check logs for details."
            echo "============================================"
        }
    }
}
