Write-Host ">>> Getting public key"
$PUB = Get-Content $env:USERPROFILE\.ssh\id_rsa.pub

Write-Host ">>> Running agent1"
docker run -d --rm --name=agent1 --network jenkins -p 22:22 `
  -e "JENKINS_AGENT_SSH_PUBKEY=${PUB}" `
  jenkins/ssh-agent:jdk11

Write-Host ">>> Getting environment variables"
$VARS = "^(Chocolatey.*|COMPUTERNAME|.*DRIVE|OS|PATHEXT|USERNAME)$"
$MY_ENV = Get-ChildItem Env: | Where-Object -Property Value -NotMatch "\\" | Where-Object -Property Name -NotMatch "${VARS}" | `
  Select-Object -Property Name,Value | ConvertTo-Csv -Delimiter `= -NoTypeInformation | Select-Object -Skip 1 | % {$_ -Replace '"', ''}

Write-Host ">>> Completing environment on agent"
docker exec agent1 sh -c "echo '${$MY_ENV}' >> /etc/environment"

Write-Host ">>> Host to be set in Jenkins for agent"
docker container inspect agent1 | Select-String -Pattern '"IPAddress": "\d+\.\d+\.\d+\.\d+"'