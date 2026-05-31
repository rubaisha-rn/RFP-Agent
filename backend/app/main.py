"""FastAPI entry point for the RFP Agent System backend."""

from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api import auth, rfp, contacts, documents, vendor


@asynccontextmanager
async def lifespan(app: FastAPI):
    # startup: nothing for now
    yield
    # shutdown: nothing for now


app = FastAPI(
    title="RFP Agent System API",
    version="0.1.0",
    description="Backend API for the RFP Agent System hackathon project.",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # demo; tighten in production
    allow_methods=["*"],
    allow_headers=["*"],
    allow_credentials=False,
)

app.include_router(auth.router, prefix="/auth", tags=["auth"])
app.include_router(rfp.router, prefix="/rfp", tags=["rfp"])
app.include_router(contacts.router, prefix="/contacts", tags=["contacts"])
app.include_router(documents.router, prefix="/documents", tags=["documents"])
app.include_router(vendor.router, prefix="/vendor", tags=["vendor"])


@app.get("/health")
def health() -> dict:
    return {"status": "ok"}
