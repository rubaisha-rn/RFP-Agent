from supabase import create_client, Client
from app.config import settings

class SupabaseService:
    def __init__(self):
        self.client: Client = create_client(
            settings.supabase_url,
            settings.supabase_service_role_key
        )

    def create_job(self, organization_id: str, brief: str) -> dict:
        result = self.client.table("rfp_jobs").insert({
            "organization_id": organization_id,
            "brief": brief
        }).execute()
        return result.data[0] if result.data else {}

    def update_job_status(self, job_id: str, status: str, current_agent: str = None) -> None:
        data = {"status": status}
        if current_agent is not None:
            data["current_agent"] = current_agent
        self.client.table("rfp_jobs").update(data).eq("id", job_id).execute()

    def write_trace(self, job_id: str, agent_name: str, step_number: int, reasoning: str, 
                    tool_called: str = None, tool_input: dict = None, tool_output: dict = None, 
                    output_data: dict = None) -> None:
        data = {
            "job_id": job_id,
            "agent_name": agent_name,
            "step_number": step_number,
            "reasoning": reasoning
        }
        if tool_called is not None:
            data["tool_called"] = tool_called
        if tool_input is not None:
            data["tool_input"] = tool_input
        if tool_output is not None:
            data["tool_output"] = tool_output
        if output_data is not None:
            data["output_data"] = output_data
            
        self.client.table("agent_traces").insert(data).execute()

    def list_vendors(self, category: str = None) -> list[dict]:
        # Excludes blacklisted vendors automatically
        query = self.client.table("vendors").select("*").neq("blacklisted", True)
        if category:
            query = query.eq("category", category)
        result = query.execute()
        return result.data

    def get_ppra_rules(self) -> list[dict]:
        result = self.client.table("ppra_rules").select("*").execute()
        return result.data

    def save_document(self, job_id: str, document_type: str, file_path: str, pdf_url: str, content_json: dict) -> dict:
        result = self.client.table("generated_documents").insert({
            "job_id": job_id,
            "document_type": document_type,
            "file_path": file_path,
            "pdf_url": pdf_url,
            "content_json": content_json
        }).execute()
        return result.data[0] if result.data else {}

    def save_sent_email(self, job_id: str, to_email: str, to_name: str, subject: str, body: str) -> dict:
        result = self.client.table("sent_emails").insert({
            "job_id": job_id,
            "to_email": to_email,
            "to_name": to_name,
            "subject": subject,
            "body": body
        }).execute()
        return result.data[0] if result.data else {}

    def save_calendar_event(self, job_id: str, title: str, description: str, event_date: str, attendees: list[str]) -> dict:
        result = self.client.table("calendar_events").insert({
            "job_id": job_id,
            "title": title,
            "description": description,
            "event_date": event_date,
            "attendees": attendees
        }).execute()
        return result.data[0] if result.data else {}

    def save_portal_posting(self, job_id: str, reference_id: str, title: str, posted_url: str, closing_date: str) -> dict:
        result = self.client.table("portal_postings").insert({
            "job_id": job_id,
            "reference_id": reference_id,
            "title": title,
            "posted_url": posted_url,
            "closing_date": closing_date
        }).execute()
        return result.data[0] if result.data else {}

supabase_service = SupabaseService()
