
---

# **Azure DevOps + ACR Containerization Setup (Complete UI Steps with GitHub PAT)**

---

## **Step 1 — Attach Git Repo to Azure DevOps Project (with GitHub PAT)**

### **Step 1a — Create a GitHub Personal Access Token (PAT)**

1. Go to **GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)**
2. Click **Generate new token → Classic**
3. Fill:

   * **Name:** `azure-devops-pat`
   * **Expiration:** 30/90 days or custom
   * **Scopes:**

     * `repo` → Full control of private repositories
     * `workflow` → optional if using GitHub Actions
4. Click **Generate token**
5. **Copy the PAT** — you will not be able to see it again

> This token will authenticate Azure DevOps with your GitHub repository.

---

### **Step 1b — Connect GitHub Repo in Azure DevOps**

1. Go to **Azure DevOps → Repos → Import a repository**
2. Choose **GitHub** as the source
3. Paste the **repo URL**
4. When prompted for authentication, use the **GitHub PAT** generated above
5. Click **Import**

✅ GitHub repo is now connected to Azure DevOps.

---

## **Step 2 — Create Azure Container Registry (ACR)**

**UI Steps (Portal):**

1. Go to **Azure Portal → Container Registries → Create**
2. Fill the form:

   * **Subscription** → your subscription
   * **Resource Group** → select or create new
   * **Registry Name** → must be unique (e.g., `mycompanyacr`)
   * **SKU** → Basic / Standard / Premium (Standard recommended)
3. Click **Review + Create → Create**

✅ ACR is ready.

---

## **Step 3 — Create a Service Principal (SP) for Azure DevOps**

**UI Steps (Portal):**

1. **Azure Active Directory → App registrations → New registration**
2. Fill:

   * Name: `azure-devops-acr-sp`
   * Supported account types: Single tenant
   * Redirect URI: leave blank
3. Click **Register**

---

### **Generate Client Secret**

1. Go to your app → **Certificates & secrets → New client secret**
2. Add description → set expiry → click **Add**
3. Copy **Value** (client secret)

---

### **Assign ACR Role to SP**

1. Go to **ACR → Access control (IAM) → Add → Add role assignment**
2. Role: **AcrPush**
3. Assign access to: **User, group, or service principal**
4. Select `azure-devops-acr-sp`
5. Click **Save**

✅ SP now has permissions to push images to ACR.

---

## **Step 4 — Create Azure DevOps Service Connection**

**UI Steps (Azure DevOps Project):**

1. **Project Settings → Service connections → New service connection**
2. Select **Docker Registry → Azure Container Registry → Next**

---

### **Option 1 — Automatic (Recommended)**

* Authentication Type: **Subscription**
* Select **Azure Subscription**
* Select your **ACR**
* Service connection name: `azure-devops-acr-sp`
* Grant access to all pipelines → Check
* Click **Verify & Save**

> Uses DevOps-managed SP automatically.

---

### **Option 2 — Manual Service Principal (Optional / Advanced)**

* Authentication Type: **Service Principal (manual)**
* Fill fields:

  * **Login Server:** `https://<your-acr-name>.azurecr.io`
  * **Service Principal ID:** Application (client) ID
  * **Service Principal Key:** Client Secret
  * **Tenant ID:** Directory (tenant) ID
* Name: `azure-devops-acr-sp`
* Grant access → Check
* Verify & Save

✅ DevOps can now authenticate to ACR.

---

## **Step 5 — Create Pipeline to Build & Push Docker Image**

**UI/YAML Steps:**

1. Azure DevOps → **Pipelines → Create Pipeline → YAML → your repo**
2. Use this YAML template:

```yaml
trigger:
- main  # your branch

pool:
  vmImage: ubuntu-latest

variables:
  imageName: myapp
  tag: $(Build.BuildId)

steps:
# Build Docker image
- task: Docker@2
  displayName: 'Build Docker image'
  inputs:
    command: build
    Dockerfile: '**/Dockerfile'
    repository: $(imageName)
    tags: |
      $(tag)
    containerRegistry: azure-devops-acr-sp

# Push Docker image to ACR
- task: Docker@2
  displayName: 'Push Docker image to ACR'
  inputs:
    command: push
    repository: $(imageName)
    tags: |
      $(tag)
    containerRegistry: azure-devops-acr-sp
```

3. Ensure **Dockerfile exists** in repo root or correct path

4. Save → Run pipeline → verify logs → image should appear in ACR

✅ Pipeline builds & pushes Docker image.

---

## **Step 6 — Microsoft-Hosted Agent Limitation**

* If you see:

```
No hosted parallelism has been purchased or granted
```

**Fix options:**

1. Request free parallelism: [https://aka.ms/azpipelines-parallelism-request](https://aka.ms/azpipelines-parallelism-request)
2. Use a **self-hosted agent** (local machine or Azure VM)
3. Buy paid parallel jobs

> For learning, option 1 or 2 is sufficient.

---

## **Step 7 — Optional Next Steps**

1. Tag Docker images by branch or version → semantic versioning
2. Add deployment stage → deploy images from ACR to:

   * Azure Web App for Containers
   * Azure Kubernetes Service (AKS)
   * Azure Container Apps
3. Add CI/CD best practices → automated testing, approvals

---

# **✅ What You Have Now**

* GitHub repo connected to Azure DevOps using PAT
* ACR created
* Service Principal created and assigned `AcrPush`
* DevOps service connection configured
* Pipeline builds & pushes Docker image to ACR
* Ready to add deployment stage for full CI/CD

---

### How to setup self hosted agent

```
anantgsaraf123@DESKTOP-CL9FNGA:~/myagent$ ./config.sh

  ___                      ______ _            _ _
 / _ \                     | ___ (_)          | (_)
/ /_\ \_____   _ _ __ ___  | |_/ /_ _ __   ___| |_ _ __   ___  ___
|  _  |_  / | | | '__/ _ \ |  __/| | '_ \ / _ \ | | '_ \ / _ \/ __|
| | | |/ /| |_| | | |  __/ | |   | | |_) |  __/ | | | | |  __/\__ \
\_| |_/___|\__,_|_|  \___| \_|   |_| .__/ \___|_|_|_| |_|\___||___/
                                   | |
        agent v4.264.2             |_|          (commit 491eca9)


>> End User License Agreements:

Building sources from a TFVC repository requires accepting the Team Explorer Everywhere End User License Agreement. This step is not required for building sources from Git repositories.

A copy of the Team Explorer Everywhere license agreement can be found at:
  /home/anantgsaraf123/myagent/license.html

Enter (Y/N) Accept the Team Explorer Everywhere license agreement now? (press enter for N) > y

>> Connect:

Enter server URL > https://dev.azure.com/GOVINDA-AZURE-BEGINEER-PROJECT/BEGINEER-WEB-APP-BUILDING-PROJECT
Enter a valid value for authentication type.
Enter authentication type (press enter for PAT) > PAT
Enter personal access token > ************************************************************************************
Error reported in diagnostic logs. Please examine the log for more details.
    - /home/anantgsaraf123/myagent/_diag/Agent_20251205-035605-utc.log
The controller for path '/BEGINEER-WEB-APP-BUILDING-PROJECT/_apis/connectionData' was not found or does not implement IController.
Failed to connect.  Try again or ctrl-c to quit
Enter server URL > https://dev.azure.com/GOVINDA-AZURE-BEGINEER-PROJECT
Enter authentication type (press enter for PAT) > PAT
Enter personal access token > ************************************************************************************
Connecting to server ...

>> Register Agent:

Enter agent pool (press enter for default) > Govinda-ubuntu
Enter agent name (press enter for DESKTOP-CL9FNGA) > PERSONAL-LAPTOP-DESKTOP-CL9FNGA
Scanning for tool capabilities.
Connecting to the server.
Successfully added the agent
Testing agent connection.
Enter work folder (press enter for _work) >
2025-12-05 04:05:59Z: Settings Saved.

```