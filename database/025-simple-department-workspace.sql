-- Department-first workspace. This keeps the existing FRAME data intact.
CREATE TABLE department_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  department_id uuid NOT NULL REFERENCES departments(id),
  employee_id uuid NOT NULL REFERENCES employees(id),
  report_type text NOT NULL CHECK(report_type IN ('sales_daily','production_company','production_client','marketing_daily')),
  report_date date NOT NULL DEFAULT CURRENT_DATE,
  payload jsonb NOT NULL DEFAULT '{}',
  submitted_at timestamptz NOT NULL DEFAULT now(),
  submitted_on_time boolean NOT NULL DEFAULT false,
  reporting_score numeric(5,2) NOT NULL DEFAULT 7,
  UNIQUE(employee_id,report_type,report_date)
);
CREATE INDEX department_reports_lookup_idx ON department_reports(company_id,department_id,report_date DESC);

CREATE TABLE sales_follow_ups (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), company_id uuid NOT NULL REFERENCES companies(id),
  employee_id uuid NOT NULL REFERENCES employees(id), department_id uuid NOT NULL REFERENCES departments(id),
  company_name text NOT NULL, contact_name text NOT NULL, contact_title text, phone text, service_offer text,
  stage text NOT NULL CHECK(stage IN ('initial','middle','rejected','approved')) DEFAULT 'initial', note text,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX sales_follow_ups_lookup_idx ON sales_follow_ups(company_id,department_id,created_at DESC);

CREATE TABLE department_budget_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), company_id uuid NOT NULL REFERENCES companies(id),
  department_id uuid NOT NULL REFERENCES departments(id), requested_by uuid NOT NULL REFERENCES employees(id),
  amount numeric(14,2) NOT NULL CHECK(amount > 0), reason text NOT NULL,
  status text NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','approved','rejected')),
  decided_by uuid REFERENCES employees(id), decision_note text, decided_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX department_budget_requests_lookup_idx ON department_budget_requests(company_id,created_at DESC);

CREATE TABLE simple_leave_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), company_id uuid NOT NULL REFERENCES companies(id),
  department_id uuid NOT NULL REFERENCES departments(id), employee_id uuid NOT NULL REFERENCES employees(id),
  starts_on date NOT NULL, ends_on date NOT NULL, reason text NOT NULL,
  status text NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','approved','rejected')),
  decided_by uuid REFERENCES employees(id), decision_note text, decided_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(), CHECK(ends_on >= starts_on)
);
CREATE INDEX simple_leave_requests_lookup_idx ON simple_leave_requests(company_id,created_at DESC);

CREATE TABLE department_task_targets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), task_id uuid NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  metric_key text NOT NULL CHECK(metric_key IN ('new_paying_customer','sales_revenue','signed_existing_customer','reporting_time')),
  target numeric(14,2) NOT NULL CHECK(target >= 0), weight numeric(5,2) NOT NULL CHECK(weight >= 0 AND weight <= 100),
  UNIQUE(task_id,metric_key)
);

-- The original data model supports dynamic departments. These four become the operating defaults.
INSERT INTO departments(company_id,name,code)
SELECT c.id,v.name,v.code FROM companies c CROSS JOIN (VALUES ('HR','HR'),('Sales','SAL'),('Marketing','MKT'),('Production','PRO')) v(name,code)
WHERE NOT EXISTS (SELECT 1 FROM departments d WHERE d.company_id=c.id AND lower(d.name)=lower(v.name));

INSERT INTO roles(company_id,name,description)
SELECT c.id,v.name,'FRAME department workspace role' FROM companies c CROSS JOIN (VALUES ('CEO'),('HR'),('Sales Manager'),('Salesperson'),('Marketing'),('Production'),('System Admin')) v(name)
WHERE NOT EXISTS (SELECT 1 FROM roles r WHERE r.company_id=c.id AND lower(r.name)=lower(v.name));
