--
-- PostgreSQL database dump
--

\restrict 7n6cheklCmlMdRbgF6cUbBcWpXtA611JG9jX6NzAkRZp3UwSoKg2sZMrExZQs8q

-- Dumped from database version 17.6
-- Dumped by pg_dump version 18.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA public;


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'standard public schema';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: agent_traces; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agent_traces (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    job_id uuid,
    agent_name text NOT NULL,
    step_number integer NOT NULL,
    reasoning text,
    tool_called text,
    tool_input jsonb,
    tool_output jsonb,
    output_data jsonb,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: calendar_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.calendar_events (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    job_id uuid,
    title text NOT NULL,
    description text,
    event_date timestamp with time zone NOT NULL,
    attendees jsonb DEFAULT '[]'::jsonb,
    status text DEFAULT 'scheduled'::text,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: generated_documents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.generated_documents (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    job_id uuid,
    document_type text DEFAULT 'rfp'::text,
    file_path text,
    pdf_url text,
    content_json jsonb,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: organizations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organizations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    company_name text NOT NULL,
    company_email text NOT NULL,
    password_hash text NOT NULL,
    setup_data jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: portal_postings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.portal_postings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    job_id uuid,
    portal_name text DEFAULT 'PPRA e-Pak'::text,
    reference_id text,
    title text NOT NULL,
    posted_url text,
    closing_date timestamp with time zone,
    status text DEFAULT 'live'::text,
    posted_at timestamp with time zone DEFAULT now()
);


--
-- Name: ppra_rules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ppra_rules (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    rule_code text NOT NULL,
    category text NOT NULL,
    threshold_min numeric DEFAULT 0,
    threshold_max numeric,
    bidding_method text,
    mandatory_clause text,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: rfp_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rfp_jobs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid,
    status text DEFAULT 'pending'::text,
    current_agent text,
    brief text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    completed_at timestamp with time zone
);


--
-- Name: sent_emails; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sent_emails (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    job_id uuid,
    to_email text NOT NULL,
    to_name text,
    subject text NOT NULL,
    body text NOT NULL,
    status text DEFAULT 'sent'::text,
    sent_at timestamp with time zone DEFAULT now()
);


--
-- Name: vendors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vendors (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    email text NOT NULL,
    category text NOT NULL,
    registration_status text DEFAULT 'active'::text,
    past_performance_score numeric DEFAULT 0,
    avg_bid_amount numeric DEFAULT 0,
    blacklisted boolean DEFAULT false,
    conflict_flags jsonb DEFAULT '[]'::jsonb,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: agent_traces agent_traces_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_traces
    ADD CONSTRAINT agent_traces_pkey PRIMARY KEY (id);


--
-- Name: calendar_events calendar_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calendar_events
    ADD CONSTRAINT calendar_events_pkey PRIMARY KEY (id);


--
-- Name: generated_documents generated_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.generated_documents
    ADD CONSTRAINT generated_documents_pkey PRIMARY KEY (id);


--
-- Name: organizations organizations_company_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_company_email_key UNIQUE (company_email);


--
-- Name: organizations organizations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_pkey PRIMARY KEY (id);


--
-- Name: portal_postings portal_postings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.portal_postings
    ADD CONSTRAINT portal_postings_pkey PRIMARY KEY (id);


--
-- Name: portal_postings portal_postings_reference_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.portal_postings
    ADD CONSTRAINT portal_postings_reference_id_key UNIQUE (reference_id);


--
-- Name: ppra_rules ppra_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ppra_rules
    ADD CONSTRAINT ppra_rules_pkey PRIMARY KEY (id);


--
-- Name: ppra_rules ppra_rules_rule_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ppra_rules
    ADD CONSTRAINT ppra_rules_rule_code_key UNIQUE (rule_code);


--
-- Name: rfp_jobs rfp_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rfp_jobs
    ADD CONSTRAINT rfp_jobs_pkey PRIMARY KEY (id);


--
-- Name: sent_emails sent_emails_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sent_emails
    ADD CONSTRAINT sent_emails_pkey PRIMARY KEY (id);


--
-- Name: vendors vendors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendors
    ADD CONSTRAINT vendors_pkey PRIMARY KEY (id);


--
-- Name: agent_traces agent_traces_job_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_traces
    ADD CONSTRAINT agent_traces_job_id_fkey FOREIGN KEY (job_id) REFERENCES public.rfp_jobs(id) ON DELETE CASCADE;


--
-- Name: calendar_events calendar_events_job_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calendar_events
    ADD CONSTRAINT calendar_events_job_id_fkey FOREIGN KEY (job_id) REFERENCES public.rfp_jobs(id) ON DELETE CASCADE;


--
-- Name: generated_documents generated_documents_job_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.generated_documents
    ADD CONSTRAINT generated_documents_job_id_fkey FOREIGN KEY (job_id) REFERENCES public.rfp_jobs(id) ON DELETE CASCADE;


--
-- Name: portal_postings portal_postings_job_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.portal_postings
    ADD CONSTRAINT portal_postings_job_id_fkey FOREIGN KEY (job_id) REFERENCES public.rfp_jobs(id) ON DELETE CASCADE;


--
-- Name: rfp_jobs rfp_jobs_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rfp_jobs
    ADD CONSTRAINT rfp_jobs_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id);


--
-- Name: sent_emails sent_emails_job_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sent_emails
    ADD CONSTRAINT sent_emails_job_id_fkey FOREIGN KEY (job_id) REFERENCES public.rfp_jobs(id) ON DELETE CASCADE;


--
-- Name: agent_traces; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.agent_traces ENABLE ROW LEVEL SECURITY;

--
-- Name: calendar_events anon read calendar; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "anon read calendar" ON public.calendar_events FOR SELECT USING (true);


--
-- Name: generated_documents anon read docs; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "anon read docs" ON public.generated_documents FOR SELECT USING (true);


--
-- Name: sent_emails anon read emails; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "anon read emails" ON public.sent_emails FOR SELECT USING (true);


--
-- Name: rfp_jobs anon read jobs; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "anon read jobs" ON public.rfp_jobs FOR SELECT USING (true);


--
-- Name: portal_postings anon read portal; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "anon read portal" ON public.portal_postings FOR SELECT USING (true);


--
-- Name: ppra_rules anon read ppra_rules; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "anon read ppra_rules" ON public.ppra_rules FOR SELECT USING (true);


--
-- Name: agent_traces anon read traces; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "anon read traces" ON public.agent_traces FOR SELECT USING (true);


--
-- Name: vendors anon read vendors; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "anon read vendors" ON public.vendors FOR SELECT USING (true);


--
-- Name: calendar_events; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.calendar_events ENABLE ROW LEVEL SECURITY;

--
-- Name: generated_documents; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.generated_documents ENABLE ROW LEVEL SECURITY;

--
-- Name: organizations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;

--
-- Name: portal_postings; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.portal_postings ENABLE ROW LEVEL SECURITY;

--
-- Name: ppra_rules; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.ppra_rules ENABLE ROW LEVEL SECURITY;

--
-- Name: rfp_jobs; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.rfp_jobs ENABLE ROW LEVEL SECURITY;

--
-- Name: sent_emails; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.sent_emails ENABLE ROW LEVEL SECURITY;

--
-- Name: vendors; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.vendors ENABLE ROW LEVEL SECURITY;

--
-- PostgreSQL database dump complete
--

\unrestrict 7n6cheklCmlMdRbgF6cUbBcWpXtA611JG9jX6NzAkRZp3UwSoKg2sZMrExZQs8q

