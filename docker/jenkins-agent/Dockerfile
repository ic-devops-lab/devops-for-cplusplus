FROM jenkins/inbound-agent:latest

USER root

ENV DEBIAN_FRONTEND=noninteractive

RUN \
  apt-get update -y && \
  apt-get install -y bash ca-certificates curl git build-essential cmake cppcheck clang-format python3 python3-venv python3-pip && \
  rm -rf /var/lib/apt/lists/*

USER jenkins