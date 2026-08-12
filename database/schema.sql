-- FRAME OS foundation schema (PostgreSQL 16+)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TYPE record_status AS ENUM ('active','inactive','archived');
CREATE TYPE employee_status AS ENUM ('invited','active','suspended','exited');
CREATE TYPE approval_status AS ENUM ('draft','pending','approved','rejected','cancelled');
CREATE TYPE step_status AS ENUM ('waiting','pending','approved','rejected','skipped');
CREATE TYPE permission_scope AS ENUM ('self','assigned','department','company');

CREATE TABLE companies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  code text NOT NULL UNIQUE,
  country_code char(2) NOT NULL DEFAULT 'RW',
  timezone text NOT NULL DEFAULT 'Africa/Kigali',
  base_currency char(3) NOT NULL DEFAULT 'RWF',
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE reference_counters (
  company_id uuid NOT NULL REFERENCES companies(id),
  namespace text NOT NULL,
  next_value bigint NOT NULL CHECK (next_value > 0),
  PRIMARY KEY (company_id, namespace)
);

CREATE TABLE departments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  parent_id uuid REFERENCES departments(id),
  name text NOT NULL,
  code text NOT NULL,
  status record_status NOT NULL DEFAULT 'active',
  archived_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (company_id, code)
);

CREATE TABLE employees (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  employee_number text NOT NULL,
  department_id uuid REFERENCES departments(id),
  manager_id uuid REFERENCES employees(id),
  first_name text NOT NULL,
  last_name text NOT NULL,
  work_email text NOT NULL,
  phone text,
  job_title text NOT NULL,
  custom_fields jsonb NOT NULL DEFAULT '{}',
  hired_on date,
  exited_on date,
  status employee_status NOT NULL DEFAULT 'invited',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (company_id, employee_number),
  UNIQUE (company_id, work_email),
  CHECK (manager_id IS NULL OR manager_id <> id)
);

CREATE TABLE user_accounts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id uuid NOT NULL UNIQUE REFERENCES employees(id),
  password_hash text NOT NULL,
  password_changed_at timestamptz NOT NULL DEFAULT now(),
  must_change_password boolean NOT NULL DEFAULT true,
  temporary_password_expires_at timestamptz,
  failed_login_count integer NOT NULL DEFAULT 0 CHECK (failed_login_count >= 0),
  locked_until timestamptz,
  disabled_at timestamptz,
  last_login_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id uuid NOT NULL REFERENCES user_accounts(id),
  token_hash bytea NOT NULL UNIQUE,
  expires_at timestamptz NOT NULL,
  revoked_at timestamptz,
  ip_address inet,
  user_agent text,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX sessions_account_active_idx ON sessions (account_id, expires_at) WHERE revoked_at IS NULL;

CREATE TABLE roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  name text NOT NULL,
  description text,
  is_system boolean NOT NULL DEFAULT false,
  status record_status NOT NULL DEFAULT 'active',
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (company_id, name)
);

CREATE TABLE permissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  permission_key text NOT NULL UNIQUE CHECK (permission_key ~ '^[a-z][a-z0-9_-]*\.[a-z][a-z0-9_-]*$'),
  description text NOT NULL
);

CREATE TABLE role_permissions (
  role_id uuid NOT NULL REFERENCES roles(id),
  permission_id uuid NOT NULL REFERENCES permissions(id),
  scope permission_scope NOT NULL,
  PRIMARY KEY (role_id, permission_id, scope)
);

CREATE TABLE employee_roles (
  employee_id uuid NOT NULL REFERENCES employees(id),
  role_id uuid NOT NULL REFERENCES roles(id),
  department_id uuid REFERENCES departments(id),
  valid_from timestamptz NOT NULL DEFAULT now(),
  valid_until timestamptz,
  assigned_by uuid NOT NULL REFERENCES employees(id),
  PRIMARY KEY (employee_id, role_id, valid_from),
  CHECK (valid_until IS NULL OR valid_until > valid_from)
);

CREATE TABLE workflow_definitions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  workflow_key text NOT NULL,
  name text NOT NULL,
  version integer NOT NULL CHECK (version > 0),
  definition jsonb NOT NULL,
  status record_status NOT NULL DEFAULT 'active',
  created_by uuid NOT NULL REFERENCES employees(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (company_id, workflow_key, version)
);

CREATE TABLE approval_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  workflow_definition_id uuid NOT NULL REFERENCES workflow_definitions(id),
  entity_type text NOT NULL,
  entity_id uuid NOT NULL,
  title text NOT NULL,
  requested_by uuid NOT NULL REFERENCES employees(id),
  current_step integer NOT NULL DEFAULT 1 CHECK (current_step > 0),
  status approval_status NOT NULL DEFAULT 'draft',
  submitted_at timestamptz,
  decided_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (entity_type, entity_id, workflow_definition_id)
);

CREATE TABLE approval_steps (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id uuid NOT NULL REFERENCES approval_requests(id),
  step_number integer NOT NULL CHECK (step_number > 0),
  assignee_type text NOT NULL CHECK (assignee_type IN ('employee','role','manager','department_role')),
  assignee_ref text NOT NULL,
  status step_status NOT NULL DEFAULT 'waiting',
  decided_by uuid REFERENCES employees(id),
  decision_note text,
  decided_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (request_id, step_number)
);

CREATE TABLE audit_events (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  company_id uuid NOT NULL REFERENCES companies(id),
  actor_employee_id uuid REFERENCES employees(id),
  action text NOT NULL,
  module text NOT NULL,
  entity_type text NOT NULL,
  entity_id text NOT NULL,
  before_data jsonb,
  after_data jsonb,
  request_id uuid NOT NULL,
  ip_address inet,
  user_agent text,
  occurred_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX audit_entity_idx ON audit_events (company_id, entity_type, entity_id, occurred_at DESC);
CREATE INDEX audit_actor_idx ON audit_events (company_id, actor_employee_id, occurred_at DESC);

CREATE TABLE notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  recipient_id uuid NOT NULL REFERENCES employees(id),
  type text NOT NULL,
  title text NOT NULL,
  body text NOT NULL,
  entity_type text,
  entity_id uuid,
  priority text NOT NULL DEFAULT 'normal' CHECK (priority IN ('normal','high','urgent')),
  read_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX notifications_inbox_idx ON notifications (recipient_id, created_at DESC) WHERE read_at IS NULL;

-- Audit history is append-only for the application role.
-- Production migrations grant INSERT/SELECT only and revoke UPDATE/DELETE.
