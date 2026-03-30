# Pipeline Design — Milestone 2

## 1. Goal

The goal of the first Jenkins pipeline is to automate the same core flow that already works locally:

- build the application
- run tests
- run lightweight code quality checks
- package the application
- archive the artifact

This keeps CI behavior close to the developer workflow established in Milestone 1.

---

## 2. Design principles

### Keep it small
The pipeline should solve one problem well:
**reliable CI for the current project state**.

### Reuse existing scripts where practical
Where it makes sense, Jenkins should call the same scripts already used locally.
That reduces drift between local development and CI.

### Prefer visibility over cleverness
Simple, explicit stages are better than compact but hard-to-read pipeline logic.

### Do not add deployment yet
This milestone should stop at a verified build artifact.

---

## 3. Stages

## Stage 1 — Checkout
Fetch source code from the repository.

Purpose:
- make Jenkins pipeline reproducible from SCM
- ensure pipeline always runs against committed project state

---

## Stage 2 — Build
Run the CMake-based build.

Expected command:
```bash
./scripts/build.sh
```

Purpose:
- configure project
- compile service
- produce test binaries

Output:
- compiled application binary
- compiled unit test binary
- build directory

---

## Stage 3 — Unit Tests
Run C++ unit tests.

Expected command:
```bash
ctest --test-dir build --output-on-failure
```

Purpose:
- validate internal logic quickly
- fail fast on code-level regressions

Why separate from integration tests:
- unit tests are faster
- failures are easier to localize

---

## Stage 4 — Integration Tests
Run Python integration tests against the compiled binary.

Expected command:
```bash
pytest app/tests/integration -q
```

Purpose:
- verify the service behaves correctly from the outside
- validate real HTTP interactions
- ensure the application runs, not just compiles

This is an important layer because the CI system should validate executable behavior, not only compile success.

---

## Stage 5 — Code Quality
Run lightweight quality checks locally in the pipeline.

Possible tools:
- `clang-format` for formatting validation
- `cppcheck` for static analysis
- optional `clang-tidy`

Purpose:
- demonstrate quality gates
- catch common issues early
- avoid adding a separate quality platform too soon

Why not SonarQube yet:
- requires extra infrastructure
- would expand milestone scope
- not necessary to prove CI capability at this stage

---

## Stage 6 — Package
Create a simple distributable artifact.

Example:
```bash
tar -czf build/echo_server.tar.gz build/echo_server
```

Purpose:
- produce a stable output from the pipeline
- prepare the project for later deployment milestones
- make CI output tangible and downloadable

---

## Stage 7 — Archive Artifact
Archive the artifact in Jenkins.

Example Jenkins step:
```groovy
archiveArtifacts artifacts: 'build/*.tar.gz', fingerprint: true
```

Purpose:
- preserve build output
- allow artifact download from Jenkins UI
- establish artifact-oriented delivery thinking

---

## 4. Why artifact archiving is enough for now

At this milestone, Jenkins itself can store the packaged artifact.

That is enough because:
- there is only one primary artifact
- the goal is to prove packaging and retrieval
- external artifact repositories can come later

This avoids unnecessary complexity while preserving the delivery mindset.

---

## 5. Why Blue Ocean is useful here

Blue Ocean is optional, but useful.

Benefits:
- stage flow is easier to understand
- failed stages are easier to inspect
- pipeline runs look cleaner during demos
- makes early Jenkins learning smoother

It does not change pipeline behavior. It improves usability and visibility.

---

## 6. Expected Jenkinsfile shape

The Jenkinsfile should be:
- short
- declarative
- stage-based
- easy to read

The early version does not need:
- parallel stages
- shared libraries
- matrix builds
- dynamic agents

Those can be introduced only when they solve a real problem.

---

## 7. Success criteria

The pipeline design is successful when:
- a code change can be built by Jenkins
- tests are executed automatically
- quality checks are visible
- an artifact is produced
- a reviewer can understand the pipeline quickly

---

## Troubleshooting

### Code Quality step fails

In the Console Output you see something like this:
```
...
app/src/config.cpp:14:14: error: code should be clang-formatted [-Wclang-format-violations] const char* value = std::getenv(key);
^
app/src/config.cpp:21:76: error: code should be clang-formatted [-Wclang-format-violations] throw std::runtime_error(std::string("invalid integer for env var: ") + key);
...

+ CLANG_FORMAT_EXIT=123
+ echo cppcheck exit code: 0
cppcheck exit code: 0
+ echo clang-format exit code: 123
clang-format exit code: 123
+ [ 0 -ne 0 ]
+ [ 123 -ne 0 ]
+ echo Code quality checks failed
Code quality checks failed
+ exit 1
script returned exit code 1
```

**How to fix**

On the devops host:
1. Install `clang-format` if you didn't do it yet
```
apt update -y
apt install -y clang-format
```
2. Fix code format issues
```
cd <project-root>
find app/src app/include -type f \( -name "*.cpp" -o -name "*.hpp" \) -print0 | \
xargs -0 clang-format -i
```
3. Commit and push changes
```
git add .
git commit -m "Code format fixes"
git push
```
4. Start the pipeline again
