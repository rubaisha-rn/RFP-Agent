import sys
from app.services.supabase_client import supabase_service

def test():
    try:
        print("Querying generated_documents...")
        res = supabase_service.client.table("generated_documents").select("*").limit(1).execute()
        print("docs keys:", res.data[0].keys() if res.data else "empty")
    except Exception as e:
        print("docs error:", e)

    try:
        print("Querying sent_emails...")
        res = supabase_service.client.table("sent_emails").select("*").limit(1).execute()
        print("emails keys:", res.data[0].keys() if res.data else "empty")
    except Exception as e:
        print("emails error:", e)

    try:
        print("Querying calendar_events...")
        res = supabase_service.client.table("calendar_events").select("*").limit(1).execute()
        print("events keys:", res.data[0].keys() if res.data else "empty")
    except Exception as e:
        print("events error:", e)

    try:
        print("Querying portal_postings...")
        res = supabase_service.client.table("portal_postings").select("*").limit(1).execute()
        print("portal keys:", res.data[0].keys() if res.data else "empty")
    except Exception as e:
        print("portal error:", e)

if __name__ == "__main__":
    test()
