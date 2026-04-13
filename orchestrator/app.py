from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import httpx
import os
import asyncio

app = FastAPI()

# Base prefix for all worker internal DNS names — matches Terraform naming
WORKER_BASE = os.getenv("WORKER_BASE")
if not WORKER_BASE:
    raise RuntimeError("WORKER_BASE environment variable is not set")

# Cloud Map private DNS namespace for service discovery
NAMESPACE_NAME = os.getenv("NAMESPACE_NAME")
if not NAMESPACE_NAME:
    raise RuntimeError("NAMESPACE_NAME environment variable is not set")


# -----------------------------------------------------------
# Request models — one per worker
# -----------------------------------------------------------
class SummaryRequest(BaseModel):
    text: str

class ClassifyRequest(BaseModel):
    text: str
    labels: list[str]

class ExtractRequest(BaseModel):
    document: str

class RedactRequest(BaseModel):
    text: str
    sensitive_types: list[str]

class TranslateRequest(BaseModel):
    text: str
    target_language: str


# -----------------------------------------------------------
# Helper — builds the Cloud Map service discovery URL
# Format: http://{worker_name}.{namespace_name}:8000/process
# -----------------------------------------------------------

def worker_url(worker_name: str) -> str:
    return f"http://{worker_name}.{NAMESPACE_NAME}:8000/process"

# -----------------------------------------------------------
# Helper — calls a single worker with retry logic
# -----------------------------------------------------------
async def call_worker(client: httpx.AsyncClient, worker_name: str, payload: dict) -> dict:
    url = worker_url(worker_name)
    for attempt in range(5):
        try:
            print(f"[orchestrator] Calling {worker_name} at {url} (attempt {attempt + 1})", flush=True)
            r = await client.post(url, json=payload, follow_redirects=True)
            r.raise_for_status()
            return r.json()
        except httpx.ConnectError as e:
            print(f"[orchestrator] DNS/Connect error calling {worker_name}: {e}", flush=True)
            await asyncio.sleep(2)
        except httpx.HTTPStatusError as e:
            print(f"[orchestrator] HTTP error from {worker_name}: {e}", flush=True)
            return {"error": f"worker returned {e.response.status_code}"}
        except Exception as e:
            print(f"[orchestrator] Unexpected error calling {worker_name}: {e}", flush=True)
            await asyncio.sleep(2)
    return {"error": f"{worker_name} unreachable after 5 attempts"}


# -----------------------------------------------------------
# Health check
# -----------------------------------------------------------
@app.get("/health")
async def health():
    return {"status": "ok", "worker_base": WORKER_BASE, "namespace_name": NAMESPACE_NAME}


# -----------------------------------------------------------
# Individual worker endpoints
# -----------------------------------------------------------
@app.post("/summarize")
async def summarize(request: SummaryRequest):
    async with httpx.AsyncClient(timeout=30.0) as client:
        return await call_worker(client, "summaries-worker", request.dict())


@app.post("/classify")
async def classify(request: ClassifyRequest):
    async with httpx.AsyncClient(timeout=30.0) as client:
        return await call_worker(client, "classify-worker", request.dict())


@app.post("/extract")
async def extract(request: ExtractRequest):
    async with httpx.AsyncClient(timeout=30.0) as client:
        return await call_worker(client, "extract-worker", request.dict())


@app.post("/redact")
async def redact(request: RedactRequest):
    async with httpx.AsyncClient(timeout=30.0) as client:
        return await call_worker(client, "redact-worker", request.dict())


@app.post("/translate")
async def translate(request: TranslateRequest):
    async with httpx.AsyncClient(timeout=30.0) as client:
        return await call_worker(client, "translate-worker", request.dict())


# -----------------------------------------------------------
# /run — calls ALL workers in parallel (generic payload fan-out)
# Each worker gets only the fields it needs
# -----------------------------------------------------------
class RunRequest(BaseModel):
    text: str
    labels: list[str] = ["positive", "negative", "neutral"]
    sensitive_types: list[str] = ["name", "email", "phone", "ssn"]
    target_language: str = "Spanish"

@app.post("/run")
async def run_all(request: RunRequest):
    async with httpx.AsyncClient(timeout=30.0) as client:
        results = await asyncio.gather(
            call_worker(client, "summaries-worker", {"text": request.text}),
            call_worker(client, "classify-worker",  {"text": request.text, "labels": request.labels}),
            call_worker(client, "extract-worker",   {"document": request.text}),
            call_worker(client, "redact-worker",    {"text": request.text, "sensitive_types": request.sensitive_types}),
            call_worker(client, "translate-worker", {"text": request.text, "target_language": request.target_language}),
        )

    return {
        "results": {
            "summaries-worker": results[0],
            "classify-worker":  results[1],
            "extract-worker":   results[2],
            "redact-worker":    results[3],
            "translate-worker": results[4],
        }
    }