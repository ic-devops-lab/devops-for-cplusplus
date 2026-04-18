# Runbook — Troubleshooting Jenkins Kubernetes Agents

This runbook covers the most common problems when moving Jenkins builds to dynamic Kubernetes agents.

---

## 1. Jenkins cannot connect to the cluster

Symptoms:

- Kubernetes cloud connection test fails
- Jenkins cannot provision pods

Checks:

1. Verify kubeconfig uses k3s **private IP**, not `127.0.0.1`
2. Verify Jenkins VM can reach `https://<k3s-private-ip>:6443`
3. Verify k3s security group allows 6443 from Jenkins
4. Verify kubeconfig certificate data is intact

Useful commands:

```bash
curl -k https://<k3s-private-ip>:6443/version
```

and on k3s:

```bash
sudo ss -ltnp | grep 6443
```

---

## 2. Pod never starts

Symptoms:

- Jenkins job waits for node
- pod is `Pending`

Checks on k3s VM:

```bash
sudo kubectl get pods
sudo kubectl describe pod <pod-name>
```

Common causes:

- insufficient CPU or RAM
- image pull failure
- invalid image name
- missing registry access
- wrong pod template configuration

---

## 3. Pod starts but agent never connects

Symptoms:

- pod is running
- Jenkins still waits for agent connection

Likely causes:

- Jenkins URL is not reachable from the pod
- wrong container name
- not using an inbound-agent-compatible image
- network path from pod to Jenkins is broken

Checks:

- verify pod template uses container name `jnlp`
- verify custom image is based on `jenkins/inbound-agent`
- verify Jenkins URL in cloud config is reachable from the k3s VM

From the k3s VM, test:

```bash
curl http://<jenkins-private-ip>:8080/login
```

---

## 4. Build starts but tools are missing

Symptoms:

- `cmake: command not found`
- `python3: command not found`
- `cppcheck: command not found`

Cause:

- custom agent image does not include required tools
- wrong Docker image tag used in pod template

Fix:

- run the image locally and verify all tools
- confirm the exact same image tag is configured in Jenkins
- rebuild and repush if needed

---

## 5. `checkout scm` fails on the pod

Symptoms:

- checkout stage fails
- repository not cloned

Checks:

- verify Git is installed in the custom image
- verify Jenkins credentials/repo access still work
- verify workspace permissions inside the pod

---

## 6. Pipeline runs but artifact archiving fails

Symptoms:

- build succeeds
- archive stage cannot find files

Checks:

- verify files are produced inside the pod workspace
- verify archive step points to correct relative path
- confirm pipeline did not switch directories unexpectedly

---

## 7. Concurrent builds do not create multiple pods

Symptoms:

- second build waits
- only one pod appears

Checks:

- pipeline may still use `disableConcurrentBuilds()`
- cluster may lack resources
- Jenkins may not be allowed to schedule another agent

Important:
If `disableConcurrentBuilds()` is present, Jenkins will intentionally serialize builds.

For concurrency testing, temporarily remove or comment that option.

---

## 8. Controller still appears to run builds

Symptoms:

- build seems to execute on Jenkins VM
- no pod appears

Checks:

- verify Jenkinsfile agent label is `k8s-agent`
- verify pod template label matches exactly
- verify cloud is enabled
- verify pipeline job is using updated Jenkinsfile from SCM

---

## 9. Where to look for logs

### Jenkins VM
Use Jenkins UI logs and system logs.

### k3s VM
Useful commands:

```bash
sudo kubectl get pods -A
sudo kubectl describe pod <pod-name>
sudo kubectl logs <pod-name> -c jnlp
sudo journalctl -u k3s -n 100 --no-pager
```

These are usually enough to identify first-run failures.

---

## 10. Safe debugging strategy

When debugging, do it in this order:

1. cluster reachable
2. Jenkins cloud connection works
3. pod template correct
4. smoke-test pipeline works
5. full project pipeline works
6. concurrent build validation works

Do not debug all layers at once.
