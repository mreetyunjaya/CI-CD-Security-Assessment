##Docker Installation
#!/bin/bash
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common 
curl -fsSL https://yum.dockerproject.org/gpg | sudo apt-key add - 
sudo add-apt-repository \
    "deb https://apt.dockerproject.org/repo/ \
    ubuntu-$(lsb_release -cs) \
    main" 
sudo apt-get update
sudo apt-get -y install docker-engine 
# add current user to docker group so there is no need to use sudo when running docker
sudo usermod -aG docker $(whoami)
#let docker run when server is restarted
sudo systemctl enable docker
#create random password for jenkins user which will be created automatically
export Jenkins_PW=$(openssl rand -base64 16)
export JAVA_OPTS="-Djenkins.install.runSetupWizard=false"

#we're providing the server its public hostname for its relative links
export JenkinsPublicHostname=$(curl -s http://169.254.169.254/latest/meta-data/public-hostname)
export SeleniumPrivateIp=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
#build the jenkins container
docker-compose up -d --build

#let the jenkins docker complete bootstrapping with our groovy script provided
sleep 45

#create new environment without inheriting anything from this shell for this wget to work..
env -i /bin/bash -c 'wget http://127.0.0.1:8080/jnlpJars/jenkins-cli.jar'

sleep 5
#create the pipeline in jenkins
java -jar ./jenkins-cli.jar -s http://localhost:8080 -auth myjenkins:$Jenkins_PW create-job pythonpipeline < config.xml

echo "------- Your temporary Jenkins login ---------"
echo "myjenkins"
echo $Jenkins_PW
