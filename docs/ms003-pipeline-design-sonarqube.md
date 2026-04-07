# Pipeline Design — SonarQube Quality Gate Milestone

This document explains where SonarQube fits into the existing CI pipeline and why.

---

## 1. Existing CI baseline

Before this milestone, the pipeline already did:

1. Checkout
2. Bootstrap Python
3. Build
4. Unit Tests
5. Integration Tests
6. Code Quality (local lightweight checks)
7. Package Artifact
8. Archive Artifact

That was enough for a basic Jenkins CI flow.

---

## 2. What changes in this milestone

This milestone adds two stages:

- SonarQube Analysis
- Quality Gate

The updated flow becomes:

1. Checkout
2. Bootstrap Python
3. Build
4. Unit Tests
5. Integration Tests
6. Local Code Quality
7. SonarQube Analysis
8. Quality Gate
9. Package Artifact
10. Archive Artifact

---

## 3. Why SonarQube comes before packaging

Packaging should happen only after the code passes not just build and tests, but also the chosen quality gate.

That means:

- build success is not enough
- test success is not enough
- analysis and gate result influence whether the build is considered acceptable

This is the main reason for adding SonarQube as part of CI instead of treating it as optional reporting.

---

## 4. Why keep local checks too

The existing local checks (`cppcheck`, `clang-format`) still have value:

- they are fast
- they fail early
- they are simple to understand

SonarQube adds a broader and more centralized quality layer, but it does not replace basic local checks completely.

So the project benefits from both:
- local fast checks
- centralized quality reporting and gating

---

## 5. C++-specific pipeline concern

For this project, SonarQube must analyze C++ with compilation context.

Therefore the build stage must produce:

```text
build/compile_commands.json
```

Without that file, the chosen C++ analysis flow is incomplete.

That is why the build stage becomes an explicit prerequisite for SonarQube analysis.

---

## 6. Example Jenkinsfile shape

```groovy
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
      find app/src app/include -type f \( -name "*.cpp" -o -name "*.hpp" \) -print0 |         xargs -0 clang-format --dry-run --Werror
    '''
  }
}

stage('SonarQube Analysis') {
  steps {
    withSonarQubeEnv('sonarqube') {
      sh './scripts/sonar_scan.sh'
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

stage('Package Artifact') {
  steps {
    sh './scripts/package.sh'
  }
}
```

---

## 7. Quality gate behavior

The quality gate stage should be authoritative.

If the gate fails:
- pipeline fails
- packaging and later stages should not continue

That is exactly the behavior wanted for this milestone.

---

## 8. Outcome

After this milestone, the project demonstrates:

- reproducible Jenkins CI
- reproducible SonarQube infrastructure
- C++ analysis with real build context
- centralized quality reporting
- gating behavior before packaging

That is a meaningful step closer to a production-like delivery flow.
