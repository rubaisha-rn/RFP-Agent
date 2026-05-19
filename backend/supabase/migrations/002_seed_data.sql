-- Seed Data for Vendors
INSERT INTO public.vendors (id, name, email, category, registration_status, past_performance_score, avg_bid_amount, blacklisted, conflict_flags, created_at) VALUES
('efd4c25d-cc4f-4a3b-a52d-cd43412c8879', 'TechNova Solutions Pvt Ltd', 'bids@technova.pk', 'IT_services', 'active', 4.7, 2500000, false, '[]'::jsonb, '2026-05-18T11:40:45.094251+00:00'),
('91939fee-b6d6-4cea-8a5d-6a097681a2e6', 'Digital Sphere Pakistan', 'tenders@digitalsphere.com.pk', 'IT_services', 'active', 4.3, 2200000, false, '[]'::jsonb, '2026-05-18T11:40:45.094251+00:00'),
('00c0904c-922e-47cf-bb40-1d11a0ddf540', 'Innovate Systems', 'rfp@innovatesys.pk', 'IT_services', 'active', 4.5, 2800000, false, '[]'::jsonb, '2026-05-18T11:40:45.094251+00:00'),
('cb95f801-73dc-48dc-950c-79de7709933c', 'CodeCraft Engineers', 'sales@codecraft.pk', 'IT_services', 'active', 4.1, 1900000, false, '[]'::jsonb, '2026-05-18T11:40:45.094251+00:00'),
('9b7707f3-1b9a-47b9-a5dc-309ce5c7fe54', 'NexGen Infotech', 'bids@nexgen.pk', 'IT_services', 'active', 3.9, 2100000, false, '[]'::jsonb, '2026-05-18T11:40:45.094251+00:00'),
('5af29ef6-063e-48b5-a034-16d4eb97a815', 'Apex Technologies', 'procurement@apextech.pk', 'IT_services', 'active', 4.6, 3000000, false, '[]'::jsonb, '2026-05-18T11:40:45.094251+00:00'),
('d27fc1a0-8a24-4a69-9dc8-e8c5355cb2d6', 'Quantum IT Services', 'tender@quantumit.pk', 'IT_services', 'active', 4.0, 2400000, false, '["pending_litigation"]'::jsonb, '2026-05-18T11:40:45.094251+00:00'),
('1f4c0bb3-800f-4662-8289-0e621a749b48', 'BlackBox Solutions', 'info@blackbox.pk', 'IT_services', 'blacklisted', 1.2, 0, true, '["blacklisted_2024"]'::jsonb, '2026-05-18T11:40:45.094251+00:00'),
('0754af8e-0b83-4008-86d9-49b39a9dc773', 'GreenBuild Constructors', 'bids@greenbuild.pk', 'works', 'active', 4.4, 15000000, false, '[]'::jsonb, '2026-05-18T11:40:45.094251+00:00'),
('79c22667-1766-4cd6-9b39-566b51dcfb70', 'Steelcore Engineering', 'tenders@steelcore.pk', 'works', 'active', 4.2, 12000000, false, '[]'::jsonb, '2026-05-18T11:40:45.094251+00:00'),
('93dd6d53-23e1-4365-bbff-fd49222977ed', 'MediSupply Co', 'orders@medisupply.pk', 'goods', 'active', 4.5, 3500000, false, '[]'::jsonb, '2026-05-18T11:40:45.094251+00:00'),
('16ec644c-ba64-4a35-bc84-237c451e36f3', 'OfficeWorld Stationers', 'sales@officeworld.pk', 'goods', 'active', 4.0, 450000, false, '[]'::jsonb, '2026-05-18T11:40:45.094251+00:00');

-- Seed Data for PPRA Rules
INSERT INTO public.ppra_rules (id, rule_code, category, threshold_min, threshold_max, bidding_method, mandatory_clause, created_at) VALUES
('31c98235-2735-4df8-ae54-f981d9cc687c', 'PPRA-R12', 'general', 0, 100000, 'petty_purchase', 'Direct procurement allowed for amounts up to PKR 100,000 with reasonable record keeping.', '2026-05-18T11:40:45.094251+00:00'),
('7c3f4689-bcc3-4d00-9555-7add03a397de', 'PPRA-R20', 'general', 100001, 500000, 'request_for_quotation', 'Minimum three quotations required from prequalified vendors.', '2026-05-18T11:40:45.094251+00:00'),
('e135211e-b893-4144-ad83-56626e466a67', 'PPRA-R36a', 'general', 500001, 3000000, 'single_stage_one_envelope', 'Open competitive bidding via single-stage single-envelope procedure. Public advertisement mandatory.', '2026-05-18T11:40:45.094251+00:00'),
('386cb383-9165-4145-aa2d-138a5494da3c', 'PPRA-R36b', 'goods', 3000001, 100000000, 'single_stage_two_envelope', 'Technical and financial proposals in separate sealed envelopes. Technical evaluation precedes financial.', '2026-05-18T11:40:45.094251+00:00'),
('6ebc86f9-4d12-4035-95bc-5dac34560d17', 'PPRA-R36c', 'services', 3000001, 100000000, 'two_stage_bidding', 'Two-stage bidding for complex consulting services. First stage technical, second stage financial after refinement.', '2026-05-18T11:40:45.094251+00:00'),
('3a77d6c9-5f84-44fe-af63-705dc23a5c99', 'PPRA-R36d', 'works', 10000001, 999999999, 'two_stage_two_envelope', 'Two-stage two-envelope procedure for complex works contracts above PKR 10 million.', '2026-05-18T11:40:45.094251+00:00'),
('7cf45918-5ad1-4abc-8212-e5e8af803e9b', 'PPRA-R20A', 'goods', 0, 999999999, 'mandatory_advertisement', 'All procurements above PKR 500,000 must be advertised on PPRA website and one English + one Urdu newspaper.', '2026-05-18T11:40:45.094251+00:00'),
('71285ddd-613e-4735-b42a-c3687bff353c', 'PPRA-R8', 'all', 0, 999999999, 'integrity_pact', 'Integrity Pact required for all procurements exceeding PKR 10 million.', '2026-05-18T11:40:45.094251+00:00'),
('d3390f38-adde-48fa-81f1-ff7cb30a5045', 'PPRA-R35', 'all', 0, 999999999, 'bid_validity', 'Minimum bid validity period of 90 days from bid opening date.', '2026-05-18T11:40:45.094251+00:00'),
('eda0f8e3-1943-4f0f-90c3-393ad2b9001a', 'PPRA-R38', 'all', 0, 999999999, 'evaluation_criteria', 'Evaluation criteria and method must be disclosed in bidding documents. Lowest evaluated bid wins.', '2026-05-18T11:40:45.094251+00:00');
