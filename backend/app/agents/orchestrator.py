"""Orchestrator for the RFP Agent Pipeline.

Chains the 4 ADK agents sequentially:
1. Classifier
2. Auditor
3. Vendor Intel
4. Drafter & Executor
"""

import asyncio
import logging
from typing import Optional

from app.services.supabase_client import supabase_service
from app.agents.agent1_classifier import classify_brief
from app.agents.agent2_auditor import audit_classification
from app.agents.agent3_vendor_intel import rank_vendors
from app.agents.agent4_drafter import draft_and_execute

logger = logging.getLogger(__name__)

PIPELINE_PACING_SECONDS = 60

async def kick_off_pipeline(brief: str, organization_id: str | None = None) -> str:
    """Create a job in Supabase then return the job_id immediately so the API can return without blocking.
    """
    job = supabase_service.create_job(organization_id, brief)
    return job["id"]

async def run_pipeline(job_id: str, brief: str, organization_id: str | None = None) -> dict:
    """Run the full 4-agent RFP pipeline for an existing job_id.
    Updates job status as agents complete; writes traces along the way.
    Returns a dict with the outputs of all 4 agents.
    """
    try:
        # 1. Classifier
        supabase_service.update_job_status(job_id, "running", "classifier")
        logger.info(f"Job {job_id} - Agent 1: Classifier running...")
        classification_result = await classify_brief(job_id, brief)
        classification = classification_result.model_dump()
        
        await asyncio.sleep(PIPELINE_PACING_SECONDS)
        
        # 2. Auditor
        supabase_service.update_job_status(job_id, "running", "auditor")
        logger.info(f"Job {job_id} - Agent 2: Auditor running...")
        compliance_result = await audit_classification(job_id, classification)
        compliance = compliance_result.model_dump()
        
        await asyncio.sleep(PIPELINE_PACING_SECONDS)
        
        # 3. Vendor Intel
        supabase_service.update_job_status(job_id, "running", "vendor_intel")
        logger.info(f"Job {job_id} - Agent 3: Vendor Intel running...")
        vendor_intel_result = await rank_vendors(job_id, classification, compliance)
        vendor_intel = vendor_intel_result.model_dump()
        
        await asyncio.sleep(PIPELINE_PACING_SECONDS)
        
        # 4. Drafter
        supabase_service.update_job_status(job_id, "running", "drafter")
        logger.info(f"Job {job_id} - Agent 4: Drafter running...")
        final_rfp_result = await draft_and_execute(job_id, classification, compliance, vendor_intel)
        final_rfp = final_rfp_result.model_dump()
        
        # Completion
        supabase_service.update_job_status(job_id, "completed", "drafter")
        logger.info(f"Job {job_id} - Pipeline completed successfully.")
        
        return {
            "classification": classification,
            "compliance": compliance,
            "vendor_intel": vendor_intel,
            "final_rfp": final_rfp
        }
        
    except Exception as exc:
        logger.error(f"Job {job_id} failed: {exc!r}")
        # Identify current agent
        job_res = supabase_service.client.table("rfp_jobs").select("current_agent").eq("id", job_id).execute()
        current_agent = job_res.data[0]["current_agent"] if job_res.data else "unknown"
        
        supabase_service.update_job_status(job_id, "failed", current_agent)
        supabase_service.write_trace(
            job_id=job_id,
            agent_name=current_agent,
            step_number=999,
            reasoning=f"Pipeline failed: {repr(exc)}"
        )
        raise
