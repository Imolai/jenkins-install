Write-Host ">>> Getting public key"
$PUB = Get-Content $env:USERPROFILE\.ssh\id_rsa.pub

Write-Host ">>> Adding Dockerfile"
@"
FROM jenkins/ssh-agent:latest-alpine-jdk8

RUN apk update --no-cache \
    && apk upgrade --no-cache \
    && apk add --no-cache \
        asciidoc \
        binutils autoconf automake cmake make bison \
        bzip2 bzip2-dev \
        file \
        gawk \
        gcc gcc-objc g++ \
        gfortran \
        git patch subversion \
        groff \
        jpeg-dev \
        jq \
        libffi-dev \
        libtool \
        markdown \
        nodejs \
        openblas lapack openblas-dev lapack-dev \
        openjdk11-jre \
        pcre2 pcre2-dev \
        pkgconf \
        python3 python3-dev py3-pip py3-wheel \
        R \
        readline-dev \
        ruby \
        sed \
        shadow \
        sudo \
        texinfo texlive texlive-luatex texlive-xetex \
        xz-dev \
        zip \
        zlib-dev \
        rsync \
        curl curl-dev

RUN rm /usr/glibc-compat/lib/ld-linux-x86-64.so.2 && /usr/glibc-compat/sbin/ldconfig

ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk \
    PATH="/usr/lib/jvm/java-11-openjdk/bin:`$PATH"

RUN sed -i '/export PATH=/d' /etc/profile
RUN echo "export PATH=`${PATH}" >> /etc/profile

RUN sed -i '/^# %wheel.*NOPASSWD:.*$/ s/^# //' /etc/sudoers
RUN usermod -aG wheel jenkins

"@ | Set-Content Dockerfile

Write-Host ">>> Building myjenkins-builder:1.1"
docker build -t myjenkins-builder:1.0 .

Write-Host ">>> Running agent_builder"
docker run -d --rm --name=agent_builder --network jenkins -p 2242:22 `
  -e "JENKINS_AGENT_SSH_PUBKEY=${PUB}" `
  myjenkins-builder:1.0

Write-Host ">>> Host to be set in Jenkins for agent"
docker container inspect agent_builder | Select-String -Pattern '"IPAddress": "\d+\.\d+\.\d+\.\d+"'
