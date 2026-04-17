# Runbook — Pipeline Migration to Kubernetes Agents

This runbook moves the existing project pipeline from controller execution to Kubernetes-based Jenkins agents.

---

## 1. Goal

Make the existing pipeline execute on ephemeral k3s-based Jenkins agents instead of the Jenkins controller VM.

---

## 2. Before changing the real pipeline

Do not migrate the full pipeline immediately.

First ensure all of these already work:

- k3s cluster is reachable ([runbook 1](ms004-runbook-1-k3s-provision.md))
- pod template exists ([runbook 2](./ms004-runbook-2-agent-image.md))
- Jenkins Kubernetes cloud is configured ([runbook 3](ms004-runbook-3-k8s-plugin.md))
- custom Docker image contains required tools ([runbook 3](ms004-runbook-3-k8s-plugin.md))
- test pipeline succeeds on `k8s-agent` ([runbook 3](ms004-runbook-3-k8s-plugin.md))

Only then update the real pipeline.

---

## 3. Updated agent section in the current pipeline

### Current pipeline execution model

Before this milestone, the Jenkinsfile likely starts with something like:

```groovy
pipeline {
  agent any
```

This allows Jenkins to run stages on the controller node.

That is what we want to stop doing.

---

### Updated agent section

Replace the top-level agent section with:

```groovy
pipeline {
  agent {
    label 'k8s-agent'
  }
```

This tells Jenkins:

- look for a node with label `k8s-agent`
- the Kubernetes plugin should provision a matching pod
- run the pipeline there

---

## 4. Why this can work without rewriting the whole pipeline

Most of the current pipeline logic can remain unchanged if the custom agent image already contains the required tools.

That is the benefit of the custom image approach.

Your existing stages such as:

- bootstrap Python
- build
- unit tests
- integration tests
- code quality
- SonarQube scan
- package artifact

can stay largely the same unless they depend on controller-specific paths or tools.

---

## 5. First migration pass

Suggested first pass:

- keep the Jenkinsfile logic as close as possible to the working version
- only change the agent section
- run one build
- fix environment-specific problems one by one

Do not refactor the pipeline aggressively at the same time.

---

## 6. Example Jenkinsfile shape

Example:

```groovy
pipeline {
  agent {
    label 'k8s-agent'
  }

  options {
    disableConcurrentBuilds()
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Bootstrap Python') {
      steps {
        sh 'chmod +x scripts/*.sh'
        sh './scripts/bootstrap.sh'
      }
    }

    stage('Build') {
      steps {
        sh './scripts/build.sh'
      }
    }

    stage('Unit Tests') {
      steps {
        sh 'ctest --test-dir build --output-on-failure'
      }
    }

    stage('Integration Tests') {
      steps {
        sh '''
          . .venv/bin/activate
          pytest app/tests/integration -q
        '''
      }
    }

    stage('Code Quality') {
      steps {
        sh '''
          set -e
          cppcheck --enable=all --inconclusive --quiet app/src app/include 2> cppcheck-report.txt || true
          find app/src app/include -type f \( -name "*.cpp" -o -name "*.hpp" \) -print0 |             xargs -0 clang-format --dry-run --Werror
        '''
      }
    }

    stage('Package Artifact') {
      steps {
        sh './scripts/package.sh'
      }
    }

    stage('Archive Artifact') {
      steps {
        archiveArtifacts artifacts: 'build/*.tar.gz', fingerprint: true
        archiveArtifacts artifacts: 'cppcheck-report.txt', fingerprint: true, onlyIfSuccessful: false
      }
    }
  }

  post {
    always {
      deleteDir()
    }
  }
}
```

This is intentionally similar to the previous milestone.

---

## 7. Validate the first real run

When you trigger the full pipeline:

1. watch Jenkins stages
2. watch the pod appear in k3s
3. confirm the build runs inside the pod
4. confirm the pod disappears after the job

On the k3s VM:

```bash
sudo kubectl get pods -w
```

You should see an agent pod created dynamically for the build.

---

## 8. Validate workspace behavior

Because the pod is ephemeral, workspace behavior matters.

Check that:

- checkout works
- scripts are available
- `.venv` is created inside the pod workspace
- build directory is created normally
- archived artifacts still appear in Jenkins

If these behave correctly, the migration is successful.

---

## 9. Concurrent build validation

To prove the architecture is working, trigger two builds close together.

Expected result:

- Jenkins creates two separate agent pods
- each build gets its own ephemeral execution environment
- controller remains orchestration-only

This is one of the strongest demonstrations of the milestone.

---

## 10. Important note on concurrency testing

If your Jenkinsfile still includes:

```groovy
disableConcurrentBuilds()
```

then Jenkins will intentionally serialize builds.

That is useful for normal operation, but it prevents validating dynamic multi-pod scaling.

So for the concurrency test only, temporarily remove or comment out `disableConcurrentBuilds()`.

After the test, restore the option if you still want serialized pipeline execution.

---

## 11. Definition of done

The pipeline migration is complete when:

- the real project pipeline runs successfully on `k8s-agent`
- builds no longer run on the Jenkins controller
- concurrent builds create multiple pods
- artifacts still archive correctly

---
