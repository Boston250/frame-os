-- Remaining FRAME OS capabilities. Apply after modules.sql.
CREATE TABLE daily_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), employee_id uuid NOT NULL REFERENCES employees(id), report_date date NOT NULL,
  completed_today text NOT NULL, pending_work text, blockers text, next_actions text NOT NULL,
  approval_request_id uuid REFERENCES approval_requests(id), submitted_at timestamptz NOT NULL DEFAULT now(), UNIQUE(employee_id,report_date)
);
CREATE TABLE meetings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), company_id uuid NOT NULL REFERENCES companies(id), title text NOT NULL,
  starts_at timestamptz NOT NULL, ends_at timestamptz NOT NULL, department_id uuid REFERENCES departments(id), agenda text,
  notes text, decisions text, created_by uuid NOT NULL REFERENCES employees(id), created_at timestamptz NOT NULL DEFAULT now(), CHECK(ends_at > starts_at)
);
CREATE TABLE meeting_participants (
  meeting_id uuid NOT NULL REFERENCES meetings(id), employee_id uuid NOT NULL REFERENCES employees(id), attended boolean,
  PRIMARY KEY(meeting_id,employee_id)
);

CREATE TABLE disciplinary_cases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), company_id uuid NOT NULL REFERENCES companies(id), employee_id uuid NOT NULL REFERENCES employees(id),
  warning_type text NOT NULL, warning_level text NOT NULL, reason text NOT NULL, incident_date date NOT NULL,
  manager_id uuid NOT NULL REFERENCES employees(id), related_entity_type text, related_entity_id uuid, employee_response text,
  hr_reviewed_by uuid REFERENCES employees(id), expires_on date, status text NOT NULL CHECK(status IN ('draft','under_review','active','expired','closed')),
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE job_openings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), company_id uuid NOT NULL REFERENCES companies(id), department_id uuid NOT NULL REFERENCES departments(id),
  title text NOT NULL, description text, hiring_manager_id uuid NOT NULL REFERENCES employees(id), positions integer NOT NULL DEFAULT 1 CHECK(positions>0),
  status text NOT NULL CHECK(status IN ('draft','open','paused','closed')), approval_request_id uuid REFERENCES approval_requests(id), created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE candidates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), job_opening_id uuid NOT NULL REFERENCES job_openings(id), name text NOT NULL,
  email text, phone text, stage text NOT NULL CHECK(stage IN ('applicant','screening','interview','evaluation','offer','hired','rejected')),
  score numeric(5,2) CHECK(score BETWEEN 0 AND 100), salary_proposal numeric(14,2), currency char(3),
  document_name text, document_reference text, notes text, created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE employee_exits (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), employee_id uuid NOT NULL REFERENCES employees(id), initiated_by uuid NOT NULL REFERENCES employees(id),
  exit_date date NOT NULL, reason text NOT NULL, approval_request_id uuid REFERENCES approval_requests(id), status approval_status NOT NULL DEFAULT 'draft',
  access_disabled_at timestamptz, assets_cleared_at timestamptz, created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE client_complaints (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), company_id uuid NOT NULL REFERENCES companies(id), customer_id uuid NOT NULL REFERENCES customers(id),
  reference text NOT NULL, issue text NOT NULL, priority text NOT NULL CHECK(priority IN ('low','normal','high','urgent')),
  responsible_employee_id uuid NOT NULL REFERENCES employees(id), deadline timestamptz NOT NULL, resolution text,
  escalation_level text NOT NULL DEFAULT 'employee' CHECK(escalation_level IN ('employee','manager','general_manager','ceo')),
  status text NOT NULL CHECK(status IN ('open','in_progress','resolved','closed')), created_at timestamptz NOT NULL DEFAULT now(), UNIQUE(company_id,reference)
);
CREATE TABLE client_performance_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), company_id uuid NOT NULL REFERENCES companies(id), customer_id uuid NOT NULL REFERENCES customers(id),
  contract_id uuid NOT NULL REFERENCES contracts(id), period_start date NOT NULL, period_end date NOT NULL,
  status text NOT NULL CHECK(status IN ('draft','account_manager_review','gm_approval','approved','delivered')),
  observations text, recommendations text, next_priorities text, approval_request_id uuid REFERENCES approval_requests(id),
  generated_reference text, delivered_at timestamptz, created_by uuid NOT NULL REFERENCES employees(id), created_at timestamptz NOT NULL DEFAULT now(),
  CHECK(period_end >= period_start)
);
CREATE TABLE client_metrics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), report_id uuid NOT NULL REFERENCES client_performance_reports(id), metric_name text NOT NULL,
  baseline numeric(18,4), previous_value numeric(18,4), current_value numeric(18,4) NOT NULL, unit text NOT NULL
);

CREATE TABLE expense_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), company_id uuid NOT NULL REFERENCES companies(id), requested_by uuid NOT NULL REFERENCES employees(id),
  department_id uuid NOT NULL REFERENCES departments(id), description text NOT NULL, amount numeric(14,2) NOT NULL CHECK(amount>0), currency char(3) NOT NULL,
  budget_id uuid REFERENCES budgets(id), is_over_budget boolean NOT NULL DEFAULT false, approval_request_id uuid REFERENCES approval_requests(id),
  status payment_status NOT NULL DEFAULT 'draft', payment_reference text, payment_date date, created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE commission_rules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), company_id uuid NOT NULL REFERENCES companies(id), name text NOT NULL,
  employee_id uuid REFERENCES employees(id), service_id uuid REFERENCES services(id), package_id uuid REFERENCES packages(id),
  rule jsonb NOT NULL, valid_from date NOT NULL, valid_until date, status record_status NOT NULL DEFAULT 'active', CHECK(valid_until IS NULL OR valid_until>=valid_from)
);
CREATE TABLE commissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), employee_id uuid NOT NULL REFERENCES employees(id), contract_id uuid NOT NULL REFERENCES contracts(id),
  rule_id uuid NOT NULL REFERENCES commission_rules(id), qualifying_payment_id uuid, amount numeric(14,2) NOT NULL CHECK(amount>=0), currency char(3) NOT NULL,
  status text NOT NULL CHECK(status IN ('pending','qualified','included_in_payroll','void')), payroll_item_id uuid REFERENCES payroll_items(id), created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE asset_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), asset_id uuid NOT NULL REFERENCES assets(id), event_type text NOT NULL CHECK(event_type IN ('checkout','return','transfer','damage','loss','maintenance')),
  employee_id uuid REFERENCES employees(id), condition_before text, condition_after text, notes text, occurred_at timestamptz NOT NULL DEFAULT now(),
  recorded_by uuid NOT NULL REFERENCES employees(id)
);
CREATE TABLE asset_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), company_id uuid NOT NULL REFERENCES companies(id), employee_id uuid NOT NULL REFERENCES employees(id),
  asset_id uuid REFERENCES assets(id), request_type text NOT NULL CHECK(request_type IN ('equipment','repair','replacement','return')),
  description text NOT NULL, needed_by date, approval_request_id uuid REFERENCES approval_requests(id),
  status approval_status NOT NULL DEFAULT 'draft', created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE document_references (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), company_id uuid NOT NULL REFERENCES companies(id), entity_type text NOT NULL, entity_id uuid NOT NULL,
  document_name text NOT NULL, reference_number text NOT NULL, created_by uuid NOT NULL REFERENCES employees(id), created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(company_id,reference_number)
);

CREATE TABLE notification_deliveries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), notification_id uuid NOT NULL REFERENCES notifications(id),
  channel text NOT NULL CHECK(channel IN ('in_app','email','whatsapp')), destination text, status text NOT NULL CHECK(status IN ('queued','sent','failed','cancelled')),
  provider_reference text, attempts integer NOT NULL DEFAULT 0, last_error text, sent_at timestamptz, created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE outbound_jobs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), company_id uuid REFERENCES companies(id), job_type text NOT NULL, payload jsonb NOT NULL,
  deduplication_key text NOT NULL UNIQUE, status text NOT NULL DEFAULT 'queued' CHECK(status IN ('queued','running','completed','failed','dead')),
  attempts integer NOT NULL DEFAULT 0, available_at timestamptz NOT NULL DEFAULT now(), locked_at timestamptz, completed_at timestamptz,
  last_error text, created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX outbound_jobs_ready_idx ON outbound_jobs(available_at) WHERE status IN ('queued','failed');
CREATE TABLE export_jobs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), company_id uuid NOT NULL REFERENCES companies(id), requested_by uuid NOT NULL REFERENCES employees(id),
  report_key text NOT NULL, format text NOT NULL CHECK(format IN ('pdf','xlsx')), filters jsonb NOT NULL DEFAULT '{}', status text NOT NULL DEFAULT 'queued',
  output_reference text, expires_at timestamptz, completed_at timestamptz, created_at timestamptz NOT NULL DEFAULT now()
);

-- Calendar is a permission-filtered projection across tasks, meetings, leave, shifts,
-- payroll, renewals, reporting dates, follow-ups and company events.
