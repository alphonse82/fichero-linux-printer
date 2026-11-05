"""Load the extension-less CUPS backend as a module, with a fake PyUSB."""

from importlib.machinery import SourceFileLoader
import importlib.util
from pathlib import Path
import sys

import pytest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tests" / "fakeusb"))

import usb.core  # noqa: E402  (the fake, never real hardware)


@pytest.fixture
def backend(monkeypatch):
    loader = SourceFileLoader("fichero_backend", str(ROOT / "resources" / "fichero"))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    monkeypatch.setattr(module.time, "sleep", lambda seconds: None)
    monkeypatch.setattr(usb.core, "DEVICES", [])
    return module


@pytest.fixture
def ppd():
    return ROOT / "resources" / "FICHERO-D11s.ppd"
