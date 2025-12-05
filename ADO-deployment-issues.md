# Azure DevOps Deployment Issues & Solutions

This document summarizes the issues encountered and solutions applied while setting up a self-hosted Azure DevOps agent on WSL (Ubuntu) and configuring a Java/Docker pipeline.

## 1. Self-Hosted Agent Setup (WSL/Ubuntu)

### DNS Resolution Failure
**Issue:** `wget` failed to download the agent package inside WSL due to DNS resolution errors (`vstsagentpackage.azureedge.net`).
**Solution:**
- **Workaround:** Downloaded the agent tarball on Windows and copied it to the WSL instance:
  ```bash
  cp /mnt/c/Users/<windows-user>/Downloads/vsts-agent-linux-x64-*.tar.gz ~/myagent/
  ```
- **Fix:** Updated `/etc/resolv.conf` to use Google DNS (`8.8.8.8`) to fix connectivity.

### Root User Restriction
**Issue:** Running `./config.sh` failed with the error "Must not run with sudo".
**Solution:**
- Created a standard user account.
- Granted sudo permissions (`usermod -aG sudo <user>`).
- Ran the configuration script as the standard user.

### Server URL Configuration
**Issue:** Agent failed to connect when using the specific **Project URL**.
**Solution:** Used the **Organization URL** instead:
- **Incorrect:** `https://dev.azure.com/{org}/{project}`
- **Correct:** `https://dev.azure.com/{org}`

### Service Startup
**Issue:** `sudo ./svc.sh start` failed because the service unit was not found.
**Solution:** The service must be installed before it can be started.
1. Run `sudo ./svc.sh install`
2. Run `sudo ./svc.sh start`

## 2. Docker Configuration

### Permission Denied
**Issue:** Pipeline failed with "permission denied while trying to connect to the Docker daemon socket".
**Solution:**
1. Installed Docker on WSL: `sudo apt-get install docker.io`
2. Added the agent user to the docker group: `sudo usermod -aG docker $USER`
3. **Restarted the agent** (crucial step) for group permissions to take effect.

### Deprecated Base Image
**Issue:** Docker build failed with `docker.io/library/openjdk:8-jre-alpine: not found`.
**Cause:** The official `openjdk` images have been deprecated and removed from Docker Hub.
**Solution:** Updated `Dockerfile` to use the recommended replacement:
```dockerfile
FROM eclipse-temurin:8-jre-alpine
```

## 3. Git Repository Sync

### Changes Not Reflecting in Pipeline
**Issue:** Pipeline continued to build old code despite local commits being pushed.
**Cause:** Local repository was pushing to **GitHub**, but the Azure Pipeline was configured to pull from **Azure Repos**.
**Solution:**
- **Option A:** Push code to Azure Repos manually:
  ```bash
  git remote add azure <azure-repo-url>
  git push azure master
  ```
- **Option B:** Configure the Pipeline in Azure DevOps to pull source code directly from GitHub.

## 4. Pipeline Build Issues (Maven/Java)

### Missing JAR File
**Issue:** Docker build step failed with `COPY target/... not found`.
**Cause:** The Dockerfile expects a compiled JAR file, but the pipeline was missing a build step to create it.
**Solution:** Added a `Maven@4` task to `azure-pipelines.yml` *before* the Docker task to compile the Java application.

### JDK Version Not Found
**Issue:** Maven task failed with "Failed to find the specified JDK version".
**Cause:** The self-hosted agent (WSL) did not have the expected Java environment variables set.
**Solution:**
1. Installed Java and Maven on WSL:
   ```bash
   sudo apt-get install openjdk-21-jdk maven
   ```
2. Manually mapped the environment variable in `azure-pipelines.yml` to point to the installed JDK path (tricking the task to use JDK 21 while asking for 17):
   ```yaml
   variables:
     JAVA_HOME_17_X64: '/usr/lib/jvm/java-21-openjdk-amd64'
   ```
