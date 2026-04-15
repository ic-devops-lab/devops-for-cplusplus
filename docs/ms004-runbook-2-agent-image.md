# Runbook — Custom Jenkins Agent Docker Image

This runbook creates the Docker image used by Jenkins dynamic Kubernetes agents.

This is a critical part of the milestone.

Without a custom image, the agent pod will not contain all tools required by the current pipeline.

---

## 1. Goal

Build and publish a Docker image that includes:

- Jenkins inbound agent support
- git
- bash
- CMake
- compiler toolchain
- Python
- Python venv support
- cppcheck
- clang-format
- curl

This image will be used by the Jenkins Kubernetes plugin pod template.

---

## 2. Why a custom image is required

The existing pipeline expects tools already available when the build starts.

If the pod image lacks those tools, builds will fail at runtime.

Installing tools dynamically in each pod would make builds:

- slower
- less reproducible
- harder to debug

So the image becomes part of the infrastructure for this milestone.

---

## 3. Docker Hub approach

This milestone uses Docker Hub rather than AWS ECR to keep the flow simple.

Suggested image name pattern:

```text
<your-dockerhub-user>/jenkins-cpp-agent:1.0
```

Example:

```text
icdevopslab/jenkins-cpp-agent:1.0
```

You can update the tag later as the image evolves.

---

## 4. Dockerfile location

Create:

`docker/jenkins-agent/Dockerfile`

---

## 5. Dockerfile content

Use this as the starting point:

```dockerfile
FROM jenkins/inbound-agent:latest

USER root

ENV DEBIAN_FRONTEND=noninteractive

RUN \
  apt-get update -y && \
  apt-get install -y bash ca-certificates curl git build-essential cmake cppcheck clang-format python3 python3-venv python3-pip && \
  rm -rf /var/lib/apt/lists/*

USER jenkins
```

This is intentionally minimal but sufficient for the current pipeline.

---

## 6. Build and push commands

From the repository root:

```bash
export IMAGE_TAG="jenkins-cpp-agent:1.0"
export DOCKERFILE_PATH="docker/jenkins-agent/Dockerfile"
export DOCKERHUB_USER="<your-dockerhub-user>"
export DOCKERHUB_TOKEN="<your-dockerhub-token>"

# Build
docker build -t "${DOCKERHUB_USER}/${IMAGE_TAG}" -f "${DOCKERFILE_PATH}" .

# Check image locally
docker run --rm -it "${DOCKERHUB_USER}/${IMAGE_TAG}" bash

# Log in
echo "${DOCKERHUB_TOKEN}" | docker login -u "${DOCKERHUB_USER}" --password-stdin

# Push
docker push "${DOCKERHUB_USER}/${IMAGE_TAG}"
```

Example with a concrete image reference:
```
export IMAGE_TAG="jenkins-cpp-agent:1.0"
export DOCKERFILE_PATH="docker/jenkins-agent/Dockerfile"
export DOCKERHUB_USER="icdevopslab"
export DOCKERHUB_TOKEN="<dockerhub-token>"

docker build -t "${DOCKERHUB_USER}/${IMAGE_TAG}" -f "${DOCKERFILE_PATH}" .
echo "${DOCKERHUB_TOKEN}" | docker login -u "${DOCKERHUB_USER}" --password-stdin
docker push "${DOCKERHUB_USER}/${IMAGE_TAG}"
```

---

### Recommended validation before push

Run the image interactively:

```bash
docker run --rm -it "${DOCKERHUB_USER}/${IMAGE_TAG}" bash
```

Then verify:

```bash
git --version
cmake --version
python3 --version
cppcheck --version
clang-format --version
g++ --version
```

Do this before pushing the image.\
It will save time later.\
If any required tool is missing, update the Dockerfile before pushing the image.

---

## 7. Optional improvement — build and push from Jenkins

Instead of building and pushing the agent image manually, you can create a dedicated Jenkins pipeline for it.

### Jenkins credentials for Docker Hub

In Jenkins, add Docker Hub credentials first.

Recommended credential type:
- **Username with password**

Suggested credential ID:
```
dockerhub-creds
```

Use:
- `username` = Docker Hub username
- `password` = Docker Hub token

Do not hardcode the token in the Jenkinsfile.

### Example dedicated Jenkins pipeline for the agent image

Create a separate pipeline job, for example:
```
jenkins-agent-image-build
```

A simple Jenkinsfile example:
```groovy
pipeline {
  agent any

  environment {
    IMAGE_TAG = 'jenkins-cpp-agent:1.0'
    DOCKERFILE_PATH = 'docker/jenkins-agent/Dockerfile'
    DOCKERHUB_USER = 'icdevopslab'
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build Image') {
      steps {
        sh '''
          docker build -t "${DOCKERHUB_USER}/${IMAGE_TAG}" -f "${DOCKERFILE_PATH}" .
        '''
      }
    }

    stage('Push Image') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'dockerhub-creds',
          usernameVariable: 'DOCKER_USER',
          passwordVariable: 'DOCKER_TOKEN'
        )]) {
          sh '''
            echo "${DOCKER_TOKEN}" | docker login -u "${DOCKER_USER}" --password-stdin
            docker push "${DOCKERHUB_USER}/${IMAGE_TAG}"
          '''
        }
      }
    }
  }
}
```

This is a minimal starting point.

Also you could add the stages for checks and cleanup:
```groovy
...
    stage('Build Image') {...}

    stage('Check') {
      steps {
        sh '''
          docker run --rm "${DOCKERHUB_USER}/${IMAGE_TAG}" bash -c '
            echo "=== Git Version ===" && git --version
            echo "=== CMake Version ===" && cmake --version
            echo "=== Python3 Version ===" && python3 --version
            echo "=== Cppcheck Version ===" && cppcheck --version
            echo "=== Clang-Format Version ===" && clang-format --version
            echo "=== G++ Version ===" && g++ --version
          '
        '''
      }
    }

    stage('Push Image') {...}

    stage('Cleanup') {
      steps {
        sh '''
          docker image prune -f
          docker system prune -f
        '''
      }
    }
...
```

### Important note about where this pipeline runs

If this pipeline is executed on the Jenkins controller, Docker must be installed there and the Jenkins runtime must be allowed to use it.

That is acceptable for a lab, but it is not ideal long term.

Later options could include:
- dedicated Docker-capable build node
- Kubernetes pod with Docker build tooling
- rootless image build tools such as Kaniko or Buildah

For this milestone, running the image-build pipeline on the Jenkins controller is acceptable if that is the simplest path.

---

## 8. Definition of done

This runbook section is complete when:
- the custom image builds successfully
- required tools are present in the image
- the image is pushed to Docker Hub
- Jenkins pod template references the correct image
- optional dedicated Jenkins pipeline can rebuild and republish the image

---
