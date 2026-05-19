#!/usr/bin/env bash
# Render startup command for FastAPI

python -m uvicorn app.main:app --host 0.0.0.0 --port $PORT