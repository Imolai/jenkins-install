Write-Host ">>> Creating jenkins network"
docker network create jenkins

# Docker in Docker image
# dind variants of this image will automatically generate TLS certificates in the directory specified by the DOCKER_TLS_CERTDIR environment variable
Write-Host ">>> Running jenkins-docker (docker:dind) image"
docker run --name jenkins-docker --rm --detach `
  --privileged --network jenkins --network-alias docker `
  --env DOCKER_TLS_CERTDIR=/certs `
  --volume jenkins-docker-certs:/certs/client `
  --volume jenkins-data:/var/jenkins_home `
  docker:dind

Write-Host ">>> Adding Dockerfile"
@"
FROM jenkins/jenkins:lts-jdk11
USER root
RUN apt-get update && apt-get install -y apt-transport-https \
       ca-certificates curl gnupg2 \
       software-properties-common
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
RUN apt-key fingerprint 0EBFCD88
RUN add-apt-repository \
       "deb [arch=amd64] https://download.docker.com/linux/debian \
       `$(lsb_release -cs) stable"
RUN apt-get update && apt-get install -y docker-ce-cli
USER jenkins
RUN jenkins-plugin-cli --plugins "blueocean:1.24.7 docker-workflow:1.26"
"@ | Set-Content Dockerfile

Write-Host ">>> Building myjenkins-blueocean:1.2"
docker build -t myjenkins-blueocean:1.2 .

Write-Host ">>> Running jenkins-blueocean"
docker run --name jenkins-blueocean --rm --detach `
  --network jenkins --env DOCKER_HOST=tcp://docker:2376 `
  --env DOCKER_CERT_PATH=/certs/client --env DOCKER_TLS_VERIFY=1 `
  --volume jenkins-data:/var/jenkins_home `
  --volume jenkins-docker-certs:/certs/client:ro `
  --publish 8080:8080 --publish 50000:50000 myjenkins-blueocean:1.2

Write-Host ">>> Showing initial password"
docker exec -it jenkins-blueocean sh -c 'cat /var/jenkins_home/secrets/initialAdminPassword'
