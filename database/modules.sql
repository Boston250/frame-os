-- FRAME OS business module schema. Apply after schema.sql.
CREATE TYPE customer_status AS ENUM ('lead','active','inactive','archived');
CREATE TYPE contract_status AS ENUM ('draft','pending_sales_manager','pending_general_manager','active','expired','terminated','void');
CREATE TYPE task_status AS ENUM ('draft','assigned','in_progress','submitted','manager_review','correction','completed','failed','cancelled');
CREATE TYPE kpi_status AS ENUM ('draft','pending_hr','pending_gm','pending_ceo','active','final_review','locked','rejected');
CREATE TYPE payment_status AS ENUM ('draft','pending','approved','paid','void');

CREATE TABLE customers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), company_id uuid NOT NULL REFERENCES companies(id),
  customer_number text NOT NULL, predecessor_id uuid REFERENCES customers(id), business_name text NOT NULL,
  phone text, email text, address text, industry text, contact_name text, lead_source text,
  status customer_status NOT NULL DEFAULT 'lead', custom_fields jsonb NOT NULL DEFAULT '{}',
  created_by uuid NOT NULL REFERENCES employees(id), archived_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(company_id, customer_number)
);
CREATE INDEX customers_identity_idx ON customers(company_id, lower(email), phone);

CREATE TABLE customer_ownership (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), customer_id uuid NOT NULL REFERENCES customers(id),
  employee_id uuid NOT NULL REFERENCES employees(id), ownership_type text NOT NULL CHECK(ownership_type IN ('sales','account_manager','operations')),
  assigned_by uuid NOT NULL REFERENCES employees(id), valid_from timestamptz NOT NULL DEFAULT now(), valid_until timestamptz,
  CHECK(valid_until IS NULL OR valid_until > valid_from)
);
CREATE UNIQUE INDEX customer_active_owner_idx ON customer_ownership(customer_id, ownership_type) WHERE valid_until IS NULL;

CREATE TABLE pipelines (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), company_id uuid NOT NULL REFERENCES companies(id), name text NOT NULL,
  status record_status NOT NULL DEFAULT 'active', created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE pipeline_stages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), pipeline_id uuid NOT NULL REFERENCES pipelines(id), name text NOT NULL,
  position integer NOT NULL CHECK(position > 0), is_won boolean NOT NULL DEFAULT false, is_lost boolean NOT NULL DEFAULT false,
  required_fields jsonb NOT NULL DEFAULT '[]', UNIQUE(pipeline_id, position)
);
CREATE TABLE opportunities (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), customer_id uuid NOT NULL REFERENCES customers(id), pipeline_id uuid NOT NULL REFERENCES pipelines(id),
  stage_id uuid NOT NULL REFERENCES pipeline_stages(id), owner_id uuid NOT NULL REFERENCES employees(id), value numeric(14,2), currency char(3),
  next_follow_up_at timestamptz, last_activity_at timestamptz NOT NULL DEFAULT now(), won_lost_reason text,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE services (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), company_id uuid NOT NULL REFERENCES companies(id), name text NOT NULL,
  description text, standard_price numeric(14,2), currency char(3), status record_status NOT NULL DEFAULT 'active',
  configured_by uuid NOT NULL REFERENCES employees(id), created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE packages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), company_id uuid NOT NULL REFERENCES companies(id), name text NOT NULL,
  price numeric(14,2) NOT NULL CHECK(price >= 0), currency char(3) NOT NULL, duration_days integer CHECK(duration_days > 0),
  is_special boolean NOT NULL DEFAULT false, approval_request_id uuid REFERENCES approval_requests(id), status record_status NOT NULL DEFAULT 'active',
  created_by uuid NOT NULL REFERENCES employees(id), created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE package_services (
  package_id uuid NOT NULL REFERENCES packages(id), service_id uuid NOT NULL REFERENCES services(id), quantity numeric(12,2) NOT NULL DEFAULT 1,
  deliverable text NOT NULL, PRIMARY KEY(package_id, service_id, deliverable)
);

CREATE TABLE contracts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), company_id uuid NOT NULL REFERENCES companies(id), customer_id uuid NOT NULL REFERENCES customers(id),
  contract_number text NOT NULL, package_id uuid REFERENCES packages(id), salesperson_id uuid NOT NULL REFERENCES employees(id),
  account_manager_id uuid REFERENCES employees(id), price numeric(14,2) NOT NULL CHECK(price >= 0), currency char(3) NOT NULL,
  starts_on date NOT NULL, ends_on date NOT NULL, payment_terms text NOT NULL, reporting_frequency text,
  document_name text, document_reference text, status contract_status NOT NULL DEFAULT 'draft', revision integer NOT NULL DEFAULT 1,
  activated_at timestamptz, terminated_at timestamptz, created_by uuid NOT NULL REFERENCES employees(id),
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(company_id, contract_number), CHECK(ends_on > starts_on)
);
CREATE TABLE contract_deliverables (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), contract_id uuid NOT NULL REFERENCES contracts(id), service_id uuid REFERENCES services(id),
  description text NOT NULL, quantity numeric(12,2), due_rule text, created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE tasks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), company_id uuid NOT NULL REFERENCES companies(id), customer_id uuid REFERENCES customers(id),
  contract_id uuid REFERENCES contracts(id), parent_id uuid REFERENCES tasks(id), title text NOT NULL, description text,
  assignee_id uuid NOT NULL REFERENCES employees(id), assigned_by uuid NOT NULL REFERENCES employees(id), direct_manager_id uuid NOT NULL REFERENCES employees(id),
  is_personal boolean NOT NULL DEFAULT false, monthly_kpi_item_id uuid, deadline timestamptz NOT NULL,
  status task_status NOT NULL DEFAULT 'assigned', progress smallint NOT NULL DEFAULT 0 CHECK(progress BETWEEN 0 AND 100),
  manager_score smallint CHECK(manager_score BETWEEN 0 AND 100), manager_note text,
  submitted_at timestamptz, completed_at timestamptz, failed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX tasks_assignee_status_idx ON tasks(assignee_id, status, deadline);
CREATE TABLE task_deadline_extensions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), task_id uuid NOT NULL REFERENCES tasks(id), old_deadline timestamptz NOT NULL,
  new_deadline timestamptz NOT NULL, reason text NOT NULL, extended_by uuid NOT NULL REFERENCES employees(id), created_at timestamptz NOT NULL DEFAULT now(),
  CHECK(new_deadline > old_deadline AND new_deadline <= old_deadline + interval '3 days')
);
CREATE TABLE task_submissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), task_id uuid NOT NULL REFERENCES tasks(id), revision integer NOT NULL,
  submitted_by uuid NOT NULL REFERENCES employees(id), evidence text NOT NULL, status text NOT NULL CHECK(status IN ('submitted','approved','rejected')),
  reviewed_by uuid REFERENCES employees(id), review_note text, created_at timestamptz NOT NULL DEFAULT now(), UNIQUE(task_id, revision)
);

CREATE TABLE monthly_kpi_plans (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), company_id uuid NOT NULL REFERENCES companies(id), employee_id uuid NOT NULL REFERENCES employees(id),
  month date NOT NULL CHECK(date_trunc('month',month)=month), status kpi_status NOT NULL DEFAULT 'draft', final_score numeric(5,2) CHECK(final_score BETWEEN 0 AND 100),
  salary_factor numeric(6,4) CHECK(salary_factor BETWEEN 0 AND 2), locked_at timestamptz, created_by uuid NOT NULL REFERENCES employees(id),
  created_at timestamptz NOT NULL DEFAULT now(), UNIQUE(company_id,employee_id,month)
);
CREATE TABLE monthly_kpi_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), plan_id uuid NOT NULL REFERENCES monthly_kpi_plans(id), category text NOT NULL,
  target text NOT NULL, weight numeric(5,2) CHECK(weight > 0 AND weight <= 100), salary_impact jsonb NOT NULL DEFAULT '[]'
);
ALTER TABLE tasks ADD CONSTRAINT tasks_kpi_item_fk FOREIGN KEY(monthly_kpi_item_id) REFERENCES monthly_kpi_items(id);
CREATE TABLE weekly_kpi_evidence (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), kpi_item_id uuid NOT NULL REFERENCES monthly_kpi_items(id), task_id uuid NOT NULL UNIQUE REFERENCES tasks(id),
  hr_approved_by uuid REFERENCES employees(id), hr_verified_by uuid REFERENCES employees(id), verified_at timestamptz, created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE attendance_schedules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), company_id uuid NOT NULL REFERENCES companies(id), name text NOT NULL,
  department_id uuid REFERENCES departments(id), employee_id uuid REFERENCES employees(id), weekday smallint NOT NULL CHECK(weekday BETWEEN 0 AND 6),
  starts_at time NOT NULL, ends_at time NOT NULL, grace_minutes integer NOT NULL DEFAULT 0 CHECK(grace_minutes >= 0), status record_status NOT NULL DEFAULT 'active'
);
CREATE TABLE attendance_networks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), company_id uuid NOT NULL REFERENCES companies(id),
  name text NOT NULL DEFAULT 'FRAME MEDIA AGENCY', allowed_cidr cidr NOT NULL,
  status record_status NOT NULL DEFAULT 'active', created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(company_id, allowed_cidr)
);
CREATE TABLE attendance_entries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), employee_id uuid NOT NULL REFERENCES employees(id), work_date date NOT NULL,
  checked_in_at timestamptz, checked_out_at timestamptz, check_in_ip inet, check_out_ip inet,
  late_minutes integer NOT NULL DEFAULT 0 CHECK(late_minutes >= 0), early_departure_minutes integer NOT NULL DEFAULT 0 CHECK(early_departure_minutes >= 0),
  daily_report_missing boolean NOT NULL DEFAULT false, UNIQUE(employee_id, work_date)
);
CREATE TABLE leave_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), employee_id uuid NOT NULL REFERENCES employees(id), leave_type text NOT NULL,
  starts_on date NOT NULL, ends_on date NOT NULL, reason text NOT NULL, approval_request_id uuid REFERENCES approval_requests(id),
  status approval_status NOT NULL DEFAULT 'draft', created_at timestamptz NOT NULL DEFAULT now(), CHECK(ends_on >= starts_on)
);

CREATE TABLE accounts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), company_id uuid NOT NULL REFERENCES companies(id), code text NOT NULL, name text NOT NULL,
  account_type text NOT NULL CHECK(account_type IN ('asset','liability','equity','revenue','expense')), parent_id uuid REFERENCES accounts(id),
  status record_status NOT NULL DEFAULT 'active', UNIQUE(company_id,code)
);
CREATE TABLE journal_entries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), company_id uuid NOT NULL REFERENCES companies(id), reference text NOT NULL,
  entry_date date NOT NULL, description text NOT NULL, status text NOT NULL CHECK(status IN ('draft','posted','reversed')),
  posted_by uuid REFERENCES employees(id), posted_at timestamptz, created_at timestamptz NOT NULL DEFAULT now(), UNIQUE(company_id,reference)
);
CREATE TABLE financial_periods (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), company_id uuid NOT NULL REFERENCES companies(id),
  starts_on date NOT NULL, ends_on date NOT NULL, status text NOT NULL CHECK(status IN ('open','closed')) DEFAULT 'open',
  closed_by uuid REFERENCES employees(id), closed_at timestamptz, UNIQUE(company_id,starts_on,ends_on), CHECK(ends_on>=starts_on)
);
CREATE TABLE journal_lines (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), journal_entry_id uuid NOT NULL REFERENCES journal_entries(id), account_id uuid NOT NULL REFERENCES accounts(id),
  department_id uuid REFERENCES departments(id), customer_id uuid REFERENCES customers(id), debit numeric(14,2) NOT NULL DEFAULT 0 CHECK(debit >= 0),
  credit numeric(14,2) NOT NULL DEFAULT 0 CHECK(credit >= 0), currency char(3) NOT NULL, CHECK((debit=0)<>(credit=0))
);
CREATE TABLE invoices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), company_id uuid NOT NULL REFERENCES companies(id), customer_id uuid NOT NULL REFERENCES customers(id),
  contract_id uuid REFERENCES contracts(id), invoice_number text NOT NULL, issued_on date NOT NULL, due_on date NOT NULL,
  subtotal numeric(14,2) NOT NULL, tax numeric(14,2) NOT NULL DEFAULT 0, total numeric(14,2) GENERATED ALWAYS AS(subtotal+tax) STORED,
  currency char(3) NOT NULL, status payment_status NOT NULL DEFAULT 'draft', journal_entry_id uuid REFERENCES journal_entries(id), UNIQUE(company_id,invoice_number)
);
CREATE TABLE budgets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), company_id uuid NOT NULL REFERENCES companies(id), department_id uuid NOT NULL REFERENCES departments(id),
  period_start date NOT NULL, period_end date NOT NULL, amount numeric(14,2) NOT NULL CHECK(amount >= 0), currency char(3) NOT NULL,
  approval_request_id uuid REFERENCES approval_requests(id), status approval_status NOT NULL DEFAULT 'draft', CHECK(period_end >= period_start)
);
CREATE TABLE payroll_runs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), company_id uuid NOT NULL REFERENCES companies(id), month date NOT NULL,
  approval_request_id uuid REFERENCES approval_requests(id), status payment_status NOT NULL DEFAULT 'draft', total_payable numeric(14,2) NOT NULL DEFAULT 0,
  currency char(3) NOT NULL, payment_reference text, payment_date date, created_at timestamptz NOT NULL DEFAULT now(), UNIQUE(company_id,month)
);
CREATE TABLE payroll_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), payroll_run_id uuid NOT NULL REFERENCES payroll_runs(id), employee_id uuid NOT NULL REFERENCES employees(id),
  base_salary numeric(14,2) NOT NULL, kpi_effect numeric(14,2) NOT NULL DEFAULT 0, commission numeric(14,2) NOT NULL DEFAULT 0,
  allowances numeric(14,2) NOT NULL DEFAULT 0, advances numeric(14,2) NOT NULL DEFAULT 0, deductions numeric(14,2) NOT NULL DEFAULT 0,
  taxes numeric(14,2) NOT NULL DEFAULT 0, payable numeric(14,2) NOT NULL, UNIQUE(payroll_run_id,employee_id)
);

CREATE TABLE suppliers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), company_id uuid NOT NULL REFERENCES companies(id), name text NOT NULL,
  contact text, category text, notes text, status record_status NOT NULL DEFAULT 'active', created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE purchase_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), company_id uuid NOT NULL REFERENCES companies(id), request_number text NOT NULL,
  requested_by uuid NOT NULL REFERENCES employees(id), department_id uuid NOT NULL REFERENCES departments(id), supplier_id uuid REFERENCES suppliers(id),
  description text NOT NULL, amount numeric(14,2) NOT NULL CHECK(amount >= 0), currency char(3) NOT NULL,
  approval_request_id uuid REFERENCES approval_requests(id), status approval_status NOT NULL DEFAULT 'draft', UNIQUE(company_id,request_number)
);
CREATE TABLE assets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), company_id uuid NOT NULL REFERENCES companies(id), asset_number text NOT NULL,
  name text NOT NULL, category text NOT NULL, value numeric(14,2), currency char(3), condition text NOT NULL,
  location text, assigned_employee_id uuid REFERENCES employees(id), status record_status NOT NULL DEFAULT 'active',
  purchased_on date, created_at timestamptz NOT NULL DEFAULT now(), UNIQUE(company_id,asset_number)
);
CREATE TABLE subscriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), company_id uuid NOT NULL REFERENCES companies(id), supplier_id uuid REFERENCES suppliers(id),
  name text NOT NULL, plan text, cost numeric(14,2) NOT NULL CHECK(cost >= 0), currency char(3) NOT NULL, billing_cycle text NOT NULL,
  expires_on date, responsible_department_id uuid REFERENCES departments(id), responsible_employee_id uuid REFERENCES employees(id),
  status record_status NOT NULL DEFAULT 'active'
);

-- Production migration adds trigger functions for balanced journals, active-contract immutability,
-- automatic overdue task failure, KPI locking, and append-only audit enforcement.
