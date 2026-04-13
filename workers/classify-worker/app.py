from fastapi import FastAPI
from pydantic import BaseModel
from datetime import datetime
import time
import os
import json
import boto3

app = FastAPI()

class ClassifyRequest(BaseModel):
    text: str
    labels: list[str]

client = boto3.client(
    "bedrock-runtime",
    endpoint_url=os.getenv("BEDROCK_ENDPOINT"),
)

@app.get("/health")
def health():
    return {"status": "healthy", "worker": "classify-worker"}

@app.post("/process")
def process(request: ClassifyRequest):
    start = time.time()

    body = {
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 1024,
        "messages": [
            {
                "role": "user",
                "content": f"Classify the text into one of these labels: {request.labels}\n\n{request.text}"
            }
        ],
        "system": f"Classify the text into one of these labels: {request.labels}"
    }

    response = client.invoke_model(
        modelId=os.getenv("BEDROCK_MODEL_ID"),
        body=json.dumps(body),
    )

    response_body = json.loads(response["body"].read())
    latency_ms = int((time.time() - start) * 1000)

    return {
        "worker": "classify-worker",
        "result": response_body["content"][0]["text"],
        "model_response": response_body,
        "input_tokens": response_body["usage"]["input_tokens"],
        "output_tokens": response_body["usage"]["output_tokens"],
        "latency_ms": latency_ms,
        "timestamp": datetime.utcnow().isoformat()
    }
