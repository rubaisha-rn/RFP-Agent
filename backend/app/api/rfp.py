"""RFP routes: kick off the pipeline, poll status, get full results."""

import asyncio
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from app.agents.orchestrator import kick_off_pipeline, run_pipeline
from app.services.job_manager import get_job_status, get_job_full

router = APIRouter()


class GenerateRequest(BaseModel):
    brief: str
    organization_id: str | None = None


class GenerateResponse(BaseModel):
    job_id: str
    status: str
    message: str


@router.post("/generate", response_model=GenerateResponse)
async def generate_rfp(req: GenerateRequest):
    if not req.brief or len(req.brief.strip()) < 20:
        raise HTTPException(
            status_code=400,
            detail="brief must be at least 20 characters",
        )
    job_id = await kick_off_pipeline(req.brief, req.organization_id)

    # Use asyncio.create_task instead of BackgroundTasks to ensure proper async background execution alongside the ADK agents
    asyncio.create_task(run_pipeline(job_id, req.brief, req.organization_id))

    return GenerateResponse(
        job_id=job_id,
        status="pending",
        message="Pipeline kicked off; poll /rfp/status/{job_id} for progress.",
    )


@router.get("/status/{job_id}")
def status(job_id: str) -> dict:
    try:
        return get_job_status(job_id)
    except ValueError:
        raise HTTPException(status_code=404, detail="job not found")


@router.get("/result/{job_id}")
def result(job_id: str) -> dict:
    try:
        return get_job_full(job_id)
    except ValueError:
        raise HTTPException(status_code=404, detail="job not found")
