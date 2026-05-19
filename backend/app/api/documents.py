"""Documents route: stream the generated PDF back to the mobile app."""

from pathlib import Path
from fastapi import APIRouter, HTTPException
from fastapi.responses import FileResponse

from app.services.supabase_client import supabase_service

router = APIRouter()


@router.get("/{document_id}/download")
def download_document(document_id: str):
    # Look up the document row to get its file_path
    res = supabase_service.client.table("generated_documents").select("*").eq("id", document_id).execute()
    if not res.data:
        raise HTTPException(status_code=404, detail="document not found")
    row = res.data[0]
    file_path = Path(row["file_path"])
    if not file_path.exists():
        raise HTTPException(status_code=410, detail="document file is gone")
    return FileResponse(path=str(file_path), media_type="application/pdf", filename=file_path.name)
