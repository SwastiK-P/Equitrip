#!/usr/bin/env python3
"""Align a Nugen model to the Equitrip ledger domain, end to end.

Upload corpus -> upload benchmark -> create alignment -> wait -> deploy -> test.
Each step's id is saved to docs/nugen/state.json so a rerun resumes instead of
paying for a second alignment. The API key is read from NUGEN_API_KEY or the
file named by NUGEN_KEY_FILE, never stored in the repo.

    NUGEN_KEY_FILE=~/path/key python3 scripts/nugen_align.py
"""
import json, os, sys, time
from pathlib import Path
import requests

BASE = "https://api.nugen.in/api/v3"
ROOT = Path(__file__).resolve().parent.parent / "docs" / "nugen"
STATE = ROOT / "state.json"
BASE_MODEL = os.environ.get("NUGEN_BASE_MODEL", "llama-v3p2-3b-reasoning")

key = os.environ.get("NUGEN_API_KEY") or Path(os.path.expanduser(os.environ["NUGEN_KEY_FILE"])).read_text().strip()
H = {"Authorization": f"Bearer {key}"}
state = json.loads(STATE.read_text()) if STATE.exists() else {}


def save():
    STATE.write_text(json.dumps(state, indent=2))


def call(method, path, **kw):
    r = requests.request(method, BASE + path, headers=H, timeout=120, **kw)
    if not r.ok:
        sys.exit(f"{method} {path} -> {r.status_code}: {r.text}")
    return r.json()


def wait(path, done=("READY", "DEPLOYED"), every=15):
    while True:
        s = call("GET", path)
        print(f"  {path}: {s.get('status')}", flush=True)
        if s.get("status") in done:
            return s
        if s.get("status") in ("FAILED", "ERROR"):
            sys.exit(f"failed: {s}")
        time.sleep(every)


if "document_ids" not in state:
    # Every Markdown file in corpus/ is one document; the ledger guide first,
    # since the benchmark is filed against a single document.
    paths = sorted((ROOT / "corpus").glob("*.md"), key=lambda p: (p.stem != "split-modes", p.name))
    handles = [open(p, "rb") for p in paths]
    try:
        r = call("POST", "/documents/create",
                 files=[("files", (p.name, h, "text/markdown")) for p, h in zip(paths, handles)],
                 data=[("names", p.stem) for p in paths] + [("categories", "equitrip")])
    finally:
        for h in handles: h.close()
    state["document_ids"] = r["document_ids"]; save()
for doc in state["document_ids"]:
    wait(f"/documents/{doc}/status")
state["document_id"] = state["document_ids"][0]

if "benchmark_id" not in state:
    with open(ROOT / "equitrip_benchmark.json", "rb") as f:
        r = call("POST", "/benchmarks/upload",
                 files={"file": ("equitrip_benchmark.json", f, "application/json")},
                 data={"name": "Equitrip ledger QA", "benchmark_name": "Equitrip ledger QA",
                       "document_id": state["document_id"],
                       "description": "Split modes, balances, settlements, departures, offline"})
    state["benchmark_id"] = r["benchmark_id"]; save()

if "alignment_id" not in state:
    r = call("POST", "/alignment-projects/create", json={
        "alignment_name": "Equitrip Ledger Assistant",
        "base_model_id": BASE_MODEL,
        "document_ids": state["document_ids"],
        "benchmark_id": state["benchmark_id"],
        "description": "Answers questions about Equitrip's group expense ledger."})
    state["alignment_id"] = r["alignment_id"]; save()
wait(f"/alignment-projects/{state['alignment_id']}/status", every=30)

if "model_id" not in state:
    models = call("GET", "/models/aligned")["domain_aligned_models"]
    state["model_id"] = next(m["model_id"] for m in models if m["alignment_id"] == state["alignment_id"]); save()
mid = state["model_id"]

if call("GET", f"/models/{mid}")["deployment_status"] != "DEPLOYED":
    call("POST", f"/models/{mid}/deployment")
wait(f"/models/{mid}/deployment/status")

model = call("GET", f"/models/{mid}")
print("evaluation:", json.dumps(model.get("evaluation_data", {}).get("comparison"), indent=2))

r = call("POST", "/inference/chat/completions", json={
    "model": mid, "max_tokens": 150, "temperature": 0.1,
    "messages": [{"role": "user", "content": "Who can confirm a pending settlement in Equitrip?"}]})
print("model_id:", mid)
print("answer:", r["choices"][0]["message"]["content"])
