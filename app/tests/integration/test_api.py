import os
import subprocess
import time
from pathlib import Path

import pytest
import requests

ROOT = Path(__file__).resolve().parents[3]
BUILD_DIR = ROOT / "build"
SERVER_BIN = BUILD_DIR / "echo_server"
BASE_URL = os.getenv("BASE_URL", "http://127.0.0.1:18080")


def wait_for_server(url: str, timeout: float = 10.0) -> None:
    started = time.time()
    while time.time() - started < timeout:
        try:
            response = requests.get(f"{url}/health", timeout=1)
            if response.status_code == 200:
                return
        except Exception:
            time.sleep(0.2)
    raise RuntimeError("server did not start in time")


@pytest.fixture(scope="session")
def server_process():
    if not SERVER_BIN.exists():
        raise FileNotFoundError(f"server binary not found: {SERVER_BIN}")

    env = os.environ.copy()
    env["APP_BIND_ADDRESS"] = "127.0.0.1"
    env["APP_PORT"] = "18080"
    env["APP_ENV"] = "test"
    env["APP_NODE_ID"] = "itest-node"
    process = subprocess.Popen([str(SERVER_BIN)], env=env)
    try:
        wait_for_server(BASE_URL)
        yield process
    finally:
        process.terminate()
        process.wait(timeout=5)


def test_health(server_process):
    response = requests.get(f"{BASE_URL}/health", timeout=2)
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_version(server_process):
    response = requests.get(f"{BASE_URL}/version", timeout=2)
    assert response.status_code == 200
    assert "version" in response.json()


def test_echo(server_process):
    response = requests.post(
        f"{BASE_URL}/echo",
        json={"message": "hello from pytest", "metadata": {"suite": "integration"}},
        timeout=2,
    )
    assert response.status_code == 200
    body = response.json()
    assert body["received"] == "hello from pytest"
    assert body["metadata"]["suite"] == "integration"


def test_echo_rejects_bad_payload(server_process):
    response = requests.post(f"{BASE_URL}/echo", json={"missing": "message"}, timeout=2)
    assert response.status_code == 400
