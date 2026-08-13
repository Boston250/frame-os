CREATE TABLE IF NOT EXISTS employee_onboarding_profiles (
  employee_id uuid PRIMARY KEY REFERENCES employees(id),
  legal_name text NOT NULL,
  date_of_birth date NOT NULL,
  national_id text NOT NULL,
  home_address text NOT NULL,
  personal_email text NOT NULL,
  personal_phone text NOT NULL,
  emergency_contact_name text NOT NULL,
  emergency_contact_relationship text NOT NULL,
  emergency_contact_phone text NOT NULL,
  probation_end_date date NOT NULL,
  base_salary numeric(14,2) NOT NULL CHECK(base_salary >= 0),
  bank_name text NOT NULL,
  bank_account_name text NOT NULL,
  bank_account_number text NOT NULL,
  contract_file_name text NOT NULL,
  contract_mime_type text NOT NULL,
  contract_document bytea NOT NULL,
  issued_assets text NOT NULL,
  recorded_by uuid NOT NULL REFERENCES employees(id),
  recorded_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS employee_onboarding_national_id_idx ON employee_onboarding_profiles(national_id);

INSERT INTO permissions(permission_key,description) VALUES
  ('employees.sensitive','View employee identity, bank and contract records')
ON CONFLICT(permission_key) DO NOTHING;

INSERT INTO role_permissions(role_id,permission_id,scope)
SELECT r.id,p.id,'company'::permission_scope
FROM roles r
JOIN permissions p ON p.permission_key='employees.sensitive'
WHERE r.name IN ('Super Admin','CEO','General Manager','HR Manager')
ON CONFLICT(role_id,permission_id,scope) DO NOTHING;
