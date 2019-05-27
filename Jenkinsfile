#!groovy

pipeline {
    
    agent {
        node {
            label 'Centos01'
        }
    }

triggers {
         pollSCM('H/5 * * * *')
}

           
environment {
        MVN_SETTINGS_CONFIG = 'c6e60913-dc99-47a6-8351-dd26c471f9b4'
        MVN_TOOL_VERSION = 'Maven 3.3.9'
        JDK_TOOL_VERSION = 'JDK1.8.0_151'
        MAVEN_LOCAL_REPO = '/var/lib/jenkins/m2repositories/helloworld/repository'
        IAC_DEPLOYKEY = credentials('ec2-ice-mgmt')


}



stages {    
        stage('Initialize') {
            steps {
                buildSetup()
                showEnvironmentVariables()                
            }

        }
        

        stage('Build') {
             when {
                    not {
                        branch "master"
                    }
                }
            parallel{
                stage('Package'){
                    steps {
                    echo "Compiling development build"           
                    buildApp('clean deploy') 
                    }       
                }

                      
                stage('Checkstyle') {
                    when {
                        not {
                            branch "master"
                        }
                    }

                    steps { 
                    echo "Checkstyle static analysis"          
                    testApp('checkstyle:checkstyle') 
                    }       
                } 

                stage('Sonar') {
                    when {
                        not {
                            branch "master"
                        }
                    }

                    steps {           
                        echo "Sonarqube Code Analysis"
                        testApp('sonar:sonar') 
                    }       
                }
            }
        }
             
        stage('Release Build') {
            
            when {
                anyOf {
                    branch 'master'
                }
            }

            steps {

                script{
                    lastCommit = sh (returnStdout: true, script: 'git log -1 --pretty=%B')
                

                    if (lastCommit.contains("[Release]")){
                        sh "echo  Maven release detected"  //dont trigger build
                        return
                    } else {
                        sh "echo Last commit is not from maven release plugin" //do build steps 
                        echo "Building the release from master"    
                        setReleaseVersion()
                        buildApp('clean deploy')
     
                    }
                }
            }
        }


        stage('Tag Release') {
             when {
                anyOf {
                    branch 'master'
                }
            }
            steps {

            script{

                if(env.IAC_VERSION.contains("-SNAPSHOT")){

                    echo "Finished incrementing version - no tag"
                    return

                }else{

                    echo "Tagging the release"
                    createTag(env.IAC_VERSION)       
                    env.REPO_NAME = sh(returnStdout: true, script: 'basename -s .git `git config --get remote.origin.url`')
                }
            }                 
        }   
        
     } 
    
    stage('Infrastructure'){

        steps {
                echo "Terraform Scripts"
               provisionEnvironment(env.DEPLOY_TO)

                echo "Chef post-provisioning"
                deployEnvironment(env.DEPLOY_TO)

            }
        } 
    } 
    
}


// =====
// Build Steps
// =====



def buildSetup() {
    def branchName = env.BRANCH_NAME
    if(branchName == 'master' ) {
        // This is a release candidate build
        env.DEPLOY_TO = 'fqt'
    } else {
        // Non-Release candidate build
        env.DEPLOY_TO = 'dev'

    }
}

def buildApp(goals) {
    echo "Building the app with goals: ${goals}"
    parallel (
        Application: {
            withMaven(jdk: "$JDK_TOOL_VERSION", maven: "$MVN_TOOL_VERSION", mavenSettingsConfig: "$MVN_SETTINGS_CONFIG", mavenLocalRepo: "$MAVEN_LOCAL_REPO") {
                sh "mvn ${goals} -B -Dmaven.wagon.http.ssl.insecure=true -Dmaven.wagon.http.ssl.allowall=true -Dmaven.wagon.http.ssl.ignore.validity.dates=true -Dsonar.host.url=http://sonarqube.ice.dhs.gov"

                script {
                    def pom = readMavenPom file: 'pom.xml'
                    env.IAC_VERSION = pom.version                    
                }

                archiveArtifacts(artifacts: '**/target/*.war, **/target/*.jar, **/target/*.zip',onlyIfSuccessful: true, allowEmptyArchive: true)                
            }
        }        
        
    )
}


def testApp(goals) {
    echo "Testing the app with goals: ${goals}"
    parallel (
        Application: {
            withMaven(jdk: "$JDK_TOOL_VERSION", maven: "$MVN_TOOL_VERSION", mavenSettingsConfig: "$MVN_SETTINGS_CONFIG", mavenLocalRepo: "$MAVEN_LOCAL_REPO") {
                sh "mvn ${goals} -B -Dmaven.wagon.http.ssl.insecure=true -Dmaven.wagon.http.ssl.allowall=true -Dmaven.wagon.http.ssl.ignore.validity.dates=true -Dsonar.host.url=http://sonarqube.ice.dhs.gov"

                
            }
        }        
        
    )
}



def setReleaseVersion() {
    withMaven(jdk: "$JDK_TOOL_VERSION", maven: "$MVN_TOOL_VERSION", mavenSettingsConfig: "$MVN_SETTINGS_CONFIG") {
        script {
            def pom = readMavenPom file: 'pom.xml'
            env.IAC_VERSION = pom.version.replace("-SNAPSHOT", "-${env.BUILD_NUMBER}")
            sh "mvn versions:set versions:commit -DnewVersion=${env.IAC_VERSION} -B -Dmaven.wagon.http.ssl.insecure=true -Dmaven.wagon.http.ssl.allowall=true -Dmaven.wagon.http.ssl.ignore.validity.dates=true"
              
        }
    }
}

def createTag(version) {
    sh "git config --global user.email '${env.GIT_COMMITTER_EMAIL}'"
    sh "git config --global user.name '${env.GIT_COMMITTER_NAME}'"
    sh "git add **/pom.xml pom.xml"
    sh "git commit -m 'Release ${version}'"
    sh "git tag ${version}"
    sh "git push origin ${version}"

}

def setCurrentCommit() {
    env.CURRENT_COMMIT = sh(returnStdout: true, script:  "git rev-parse --short HEAD")
    echo "The current tag is ${env.CURRENT_COMMIT}"    
}

def showEnvironmentVariables() {
    sh 'printenv'
}


def provisionEnvironment(environmentName) {
    echo "Provisioning environment: ${environmentName}"
 
    dir("terraform/${environmentName}") {
        sh '''
        /usr/local/bin/terraform init         
        /usr/local/bin/terraform apply -auto-approve
        IAC_NODE_IP=`/usr/local/bin/terraform output app_ip`
        IAC_NODE_HOSTNAME=`/usr/local/bin/terraform output hostname`
        
        '''
        script {
            env.IAC_NODE_IP = sh(returnStdout: true, script: '/usr/local/bin/terraform output app_ip').trim()
            env.IAC_NODE_HOSTNAME = sh(returnStdout: true, script: '/usr/local/bin/terraform output hostname').trim()
        }
    }
}

def deployEnvironment(environmentName) {
    
    echo "Deploying to ${env.IAC_NODE_HOSTNAME}"
    dir("$JENKINS_HOME/maa"){       
        sh "knife bootstrap ${env.IAC_NODE_IP}  -x zzadmin -i ${IAC_DEPLOYKEY} -N ${env.IAC_NODE_HOSTNAME}.irmnet.ds2.dhs.gov -E uat --sudo -r 'iac_demo'  --yes"
    }
}