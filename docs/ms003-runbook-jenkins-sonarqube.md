# Runbook — Jenkins + SonarQube Integration for C++

This runbook describes how to connect the existing Jenkins CI pipeline to SonarQube for C++ analysis.

It assumes:

- Jenkins is already provisioned and working
- SonarQube server is reachable
- the project builds successfully in Jenkins
- the project uses CMake

---

## 1. Goal

Extend the Jenkins pipeline so it:

- submits C++ analysis to SonarQube
- waits for the quality gate result
- fails the pipeline if the gate fails

That makes code quality part of the CI workflow.

---

## 2. Jenkins plugins needed

Add these Jenkins plugins if not already present:

- SonarQube Scanner for Jenkins (install manually or recreate the Jensins VM)
- Pipeline (already present from Milestone 2)
- Credentials (already present from Milestone 2)

The SonarQube Scanner for Jenkins plugin provides:
- `withSonarQubeEnv`
- `waitForQualityGate`

These are the key pipeline steps for this milestone.

---

## 3. Store SonarQube token in Jenkins credentials

In Jenkins UI:

1. Go to **Manage Jenkins**
2. Open **Credentials**
3. Add a new credential

Use:

- Kind: **Secret text**
- Secret: SonarQube token created on the SonarQube server
- ID: `sonarqube-token`

Then reference that credential in SonarQube server configuration.

---

## 4. Configure SonarQube server in Jenkins

In Jenkins UI:

1. Go to **Manage Jenkins**
2. Open **System**
3. Find the **SonarQube servers** section
4. Add a server entry

Recommended values:

- Name: `sonarqube`
- Server URL: `http://<sonarqube-internal-ip>:9000`
- Server authentication token: use Jenkins credentials

---

## 5. Configure a Webhook in SonarQube

Go to Project -> Project settings -> Webhooks

Create a webhook with:
Name: Jenkins
URL: http://<jenkins-internal-ip>:8080/sonarqube-webhook/
Events: Select "Quality Gate event"
Replace <jenkins-internal-ip> with your actual Jenkins server IP/hostname.

---

## 6. Make CMake produce compile_commands.json

For C++ analysis, the project should export compilation commands.

In CMake, ensure:

```cmake
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
```

If you do not want to hardcode it in `CMakeLists.txt`, pass it during configure:

```bash
cmake -S . -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
```

After build, verify:

```bash
ls -l build/compile_commands.json
```

This file is required for the C++ SonarQube analysis approach used in this lab.

---

## 7. Add sonar-project.properties

Create a file at repository root:

```properties
sonar.projectKey=devops-for-cplusplus
sonar.projectName=devops-for-cplusplus
sonar.sources=app/src,app/include
sonar.tests=app/tests
sonar.sourceEncoding=UTF-8
sonar.cfamily.compile-commands=build/compile_commands.json
```

Adjust values later if the project structure changes.

This file keeps scanner configuration in the repository instead of hiding it in Jenkins.

---

## 8. Ensure SonarScanner is available

Choose one approach.

### Option A — install scanner on Jenkins VM
Install `sonar-scanner` as a tool on the Jenkins host.

### Option B — use Jenkins tool configuration
Configure SonarScanner in Jenkins global tools.

Manage Jenkins -> Tools -> \
SonarQube Scanner installations -> Add SonarQube Scanner -> \
- Name: sonar-scanner
- Install automatically: True
-> Save

For this milestone, either is acceptable as long as the setup is reproducible and documented.

---

## 9. Add pipeline stages

Insert SonarQube analysis after tests and before packaging.

Recommended order:

1. Checkout
2. Bootstrap Python
3. Build
4. Unit Tests
5. Integration Tests
6. SonarQube Analysis
7. Quality Gate
8. Package Artifact
9. Archive Artifact

That ensures packaging happens only after analysis and gate success.

---

## 10. Example Jenkinsfile stages

```groovy
stage('SonarQube Analysis') {
  environment {
    SONAR_SCANNER_HOME = tool name: 'sonar-scanner'
  }
  steps {
    withSonarQubeEnv('sonarqube') {
      sh '''
        ${SONAR_SCANNER_HOME}/bin/sonar-scanner
      '''
    }
  }
}

stage('Quality Gate') {
  steps {
    timeout(time: 10, unit: 'MINUTES') {
      waitForQualityGate abortPipeline: true
    }
  }
}
```

If you prefer to pass parameters explicitly instead of relying only on `sonar-project.properties`, you can do so in the `sonar-scanner` command.

---

## 11. Optional helper script

To keep pipeline logic small, add:

`scripts/sonar_scan.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

if [[ ! -f "build/compile_commands.json" ]]; then
  echo "ERROR: build/compile_commands.json not found"
  exit 1
fi

sonar-scanner
```

Then Jenkins can run:

```groovy
sh './scripts/sonar_scan.sh'
```

This keeps analysis logic in the repository.

---

## 12. Validate the first analysis

After running the pipeline:

- open Jenkins build page
- confirm the SonarQube Analysis stage succeeds
- confirm the Quality Gate stage finishes
- open SonarQube UI
- verify project dashboard is populated

Things to check in SonarQube:
- issues
- code smells
- quality gate result
- project history after repeated scans

---

## 13. Troubleshooting

### `compile_commands.json` missing
Check the build configuration and confirm CMake export is enabled.

### `sonar-scanner` not found
Install/configure the scanner on Jenkins and verify PATH.

### Jenkins cannot reach SonarQube
Check:
- SonarQube server URL in Jenkins
- EC2 security group
- network access from Jenkins VM to SonarQube VM

### Quality gate waits forever
Check webhook/plugin setup and SonarQube server availability.
Also inspect Jenkins logs and SonarQube background task status.

### Analysis fails on C++ configuration
Confirm:
- project builds successfully
- `build/compile_commands.json` exists
- paths in `sonar-project.properties` are correct

---

## 13. Definition of done

Jenkins integration is ready when:

- Jenkins can authenticate to SonarQube
- pipeline submits analysis successfully
- quality gate result is returned to Jenkins
- pipeline can fail on a bad gate result
- analysis results are visible in SonarQube UI

