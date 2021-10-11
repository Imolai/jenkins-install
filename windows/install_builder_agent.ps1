Write-Host ">>> Getting public key"
$PUB = Get-Content $env:USERPROFILE\.ssh\id_rsa.pub

Write-Host ">>> Adding Dockerfile"
@"
FROM jenkins/ssh-agent:latest-alpine-jdk8

RUN apk update --no-cache \
    && apk upgrade --no-cache \
    && apk add --no-cache \
	    curl \
	    rsync \
		file \
		sed \
		gawk \
		zip \
		bzip2 \
		git \
		patch \
		binutils \
		libtool \
		readline-dev \
		bison \
		pkgconf \
		make \
		cmake \
		autoconf \
		automake \
		gcc \
		gcc-objc \
		g++ \
		gfortran \
		python3 \
		ruby \
		R \
		nodejs \
		openjdk11-jre \
		groff \
		markdown \
		asciidoc \
		jq

ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk \
    PATH="/usr/lib/jvm/java-11-openjdk/bin:`$PATH"

RUN sed -i '/export PATH=/d' /etc/profile
RUN echo "export PATH=`${PATH}" >> /etc/profile

"@ | Set-Content Dockerfile

Write-Host ">>> Building myjenkins-builder:1.1"
docker build -t myjenkins-builder:1.0 .

Write-Host ">>> Running agent_builder"
docker run -d --rm --name=agent_builder --network jenkins -p 2242:22 `
  -e "JENKINS_AGENT_SSH_PUBKEY=${PUB}" `
  myjenkins-builder:1.0

Write-Host ">>> Host to be set in Jenkins for agent"
docker container inspect agent_builder | Select-String -Pattern '"IPAddress": "\d+\.\d+\.\d+\.\d+"'
