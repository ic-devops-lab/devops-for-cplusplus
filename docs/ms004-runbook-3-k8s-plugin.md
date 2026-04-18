# Runbook — Jenkins Kubernetes Plugin Integration

This runbook connects the existing Jenkins controller to the k3s cluster and configures the dynamic Kubernetes agents.

---

## 1. Goal

Configure Jenkins so that:

- it can authenticate to k3s
- it can create agent pods dynamically
- those pods use the custom Docker image
- pipelines can target those agents by label

---

## 2. Required plugin

Install the Jenkins plugin:

- **Kubernetes**

Do this through the same reproducible plugin installation mechanism you used earlier, or install it manually in Jenkins if you want to validate first and automate later.

If you automate it, add `kubernetes` to the Jenkins plugin list in the [Jenkins Controller provision script](../infra/terraform/user_data/jenkins_master_setup.sh).

---

## 3. Add kubeconfig to Jenkins credentials

In Jenkins UI:

1. Open **Manage Jenkins**
2. Open **Credentials**
3. Choose the appropriate store
4. Add a new credential

Recommended option:

- Kind: **Secret file**

Upload the adjusted kubeconfig file from the k3s runbook.

Alternative:
- Secret text with kubeconfig content

Recommended credential ID:

```text
k3s-kubeconfig
```

Use a stable, descriptive ID so later automation is easier.

---

## 4. Add Kubernetes cloud in Jenkins

In Jenkins UI:

1. Open **Manage Jenkins**
2. Open **Clouds**
3. Add a new cloud
4. Select **Kubernetes**

Configure with values similar to these.

### Cloud name
```text
k3s
```

### Kubernetes URL
Use the API endpoint from the adjusted kubeconfig, for example:

```text
https://<k3s-private-ip>:6443
```

### Kubernetes namespace
```text
default
```

### Jenkins URL
This must be reachable from the k3s VM / agent pod.

Example:

```text
http://<jenkins-private-ip>:8080
```

If Jenkins is only exposed publicly, use the reachable URL that the pod can access.

### Credentials
Select the kubeconfig credential created earlier.

If you see a warning like this:
```
'TCP port for inbound agents' is disabled in Global Security settings. Connecting Kubernetes agents will not work without this or WebSocket mode!
```
Enable **WebSocket** option.

---

## 5. Test Jenkins to k3s connectivity

Use the built-in **Test Connection** function in the Jenkins Kubernetes cloud configuration page.

Success means:

- Jenkins can authenticate to the k3s API
- Jenkins can query the cluster
- your kubeconfig and network path are correct

If it fails, do not continue until this works.

---

## 6. Create the pod template

Under the Kubernetes cloud configuration, add a pod template.

Suggested values:

### Name
```text
jenkins-k8s-agent
```

### Namespace
```text
default
```

### Labels
```text
k8s-agent
```

### Usage
Use this label in Jenkins pipelines.

---

## 7. Pod template container configuration

Add a container with values similar to:

### Container name
```text
jnlp
```

### Docker image
```text
<your-dockerhub-user>/jenkins-cpp-agent:1.0
```

Example:

```text
icdevopslab/jenkins-cpp-agent:1.0
```

### Working directory
```text
/home/jenkins/agent
```

### Always pull image
Optional.
For initial debugging, it can be helpful.
Later, you may disable frequent pulls if not needed.

### Ensure pod gets deleted automatically

In the Jenkins Kubernetes cloud pod template, set:

**Pod Retention**: Never

That means:
- delete pod after build finishes
- delete pod after failure
- delete pod after abort/timeout

---

### Command to run

**Very important!**

For the jnlp container, leave **Command to run** and **Arguments** empty unless intentionally overriding inbound-agent startup. Using a long-running placeholder command such as `sleep` keeps the pod alive but prevents the Jenkins agent from connecting.

## 8. Why use `jnlp` as the container name

The Jenkins Kubernetes plugin expects the inbound agent container to connect Jenkins to the pod.

Using the `jenkins/inbound-agent`-based image with container name `jnlp` is the simplest path.

That is why the custom image was built on top of `jenkins/inbound-agent`.

---

## 9. Save and validate cloud setup

After saving the cloud and pod template:

- verify the cloud appears correctly in Jenkins
- verify the pod template is visible
- verify the label is exactly what you plan to use in the Jenkinsfile

Typos in the label are one of the most common causes of failed first runs.

---

## 10. Validate with a simple test pipeline

Before migrating the full project pipeline, create or run a tiny test pipeline that only prints environment info.

Example:

```groovy
pipeline {
  agent none

  stages {
    stage('Smoke Test') {
      agent {
        label 'k8s-agent'
      }

      options {
        timeout(time: 5, unit: 'MINUTES')
      }

      steps {
        sh 'hostname'
        sh 'whoami'
        sh 'git --version'
        sh 'cmake --version'
        sh 'python3 --version'
      }
    }
  }

  post {
    aborted {
      echo 'Pipeline aborted by timeout or user action.'
    }
    failure {
      echo 'Pipeline failed.'
    }
    success {
      echo 'Pipeline succeeded.'
    }
  }
}
```

This should cause Jenkins to:

- create a new pod
- connect the agent
- run the stage
- destroy the pod afterward

Only after this works should you migrate the full pipeline.

---

## 11. Validate agent work correctly

### Validate pod creation on k3s

1. On the k3s VM:
```bash
sudo kubectl get pods -w
```
2. Trigger the test pipeline.

Expected behavior:

- a Jenkins agent pod appears
- pod reaches `Running`
- pipeline runs
- pod disappears after completion

This confirms the dynamic agent flow is working.

### Validate concurrentcy

1. Temporarily remove disableConcurrentBuilds() from the options of your pipeline or stage if it's set.
2. In the **Manage Jenkins > Clouds > k3s > Configure** check that **Concurrency Limit** parameter has more than `1` as a value.
3. On the k3s node turn on monitoring of Pods changes:
```
sudo -i
kubectl get pods -w
```
4. Trigger two pipeline runs
5. Confirm two agent pods appear and change events occur asynchronously

---

## 12. Definition of done

This runbook is complete when:

- Jenkins cloud is configured
- connection test succeeds
- pod template uses the custom image
- a test pipeline runs successfully on the k8s agent

---

## 13. Troubleshooting

To locate a problem:
- In Jenkins
  - analyze pipeline's Console Output
  - in the settings of the `k3s` cloud and template set **Pod Retention** option to `Always` or `On Failure` to prevent termination of the failed pods
- On k3s master VM:
  - use the following commands to get and analyze failing pods
    ```
    sudo -i

    # monitor changes during the pipeline running
    kubectl get pods -w

    # analyze failed pod
    kubectl logs <pod-name>
    kubectl describe pod <pod-name>
    ```
  - delete retained failed/stopped pods after analysis:
    ```
    sudo -i

    # delete agent pod
    kubectl get pods
    ## look for the pod with a name starting from `jenkins-k8s-agent`
    kubectl delete pod <pod-name>

    # delete multiple agent pods
    kubectl get pods | awk '/jenkins-k8s-agent/{print $1}' | xargs kubectl delete pod
  ```
