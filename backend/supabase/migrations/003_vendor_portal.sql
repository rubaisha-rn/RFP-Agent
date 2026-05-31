-- 003_vendor_portal.sql
-- Adds vendor self-service portal: vendor auth + bid response submissions

ALTER TABLE vendors ADD COLUMN IF NOT EXISTS password_hash text;
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS registered_at timestamptz;
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS is_self_registered boolean DEFAULT false;
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS ntn_number text;

CREATE TABLE IF NOT EXISTS vendor_responses (
  id uuid primary key default gen_random_uuid(),
  vendor_id uuid references vendors(id) ON DELETE CASCADE,
  job_id uuid references rfp_jobs(id) ON DELETE CASCADE,
  bid_amount_pkr numeric NOT NULL,
  technical_summary text NOT NULL,
  proposal_url text,
  status text DEFAULT 'submitted',
  submitted_at timestamptz default now(),
  UNIQUE(vendor_id, job_id)
);

CREATE INDEX IF NOT EXISTS idx_sent_emails_to_email ON sent_emails(to_email);
CREATE INDEX IF NOT EXISTS idx_vendor_responses_job ON vendor_responses(job_id);
CREATE INDEX IF NOT EXISTS idx_vendor_responses_vendor ON vendor_responses(vendor_id);