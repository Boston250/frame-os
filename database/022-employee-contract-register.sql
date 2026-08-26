CREATE TABLE IF NOT EXISTS employee_contract_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  employee_id uuid NOT NULL REFERENCES employees(id),
  title text NOT NULL CHECK (length(trim(title)) BETWEEN 1 AND 180),
  expires_on date NOT NULL,
  original_filename text NOT NULL,
  stored_filename text NOT NULL UNIQUE,
  mime_type text NOT NULL DEFAULT 'application/pdf' CHECK (mime_type = 'application/pdf'),
  file_size integer NOT NULL CHECK (file_size > 0 AND file_size <= 3145728),
  uploaded_by uuid NOT NULL REFERENCES employees(id),
  entered_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS employee_contract_documents_company_entered_at_idx ON employee_contract_documents(company_id, entered_at DESC);
CREATE INDEX IF NOT EXISTS employee_contract_documents_employee_idx ON employee_contract_documents(employee_id);

INSERT INTO permissions(permission_key,description) VALUES
  ('employee_contracts.view','View employee contract PDFs'),
  ('employee_contracts.upload','Upload employee contract PDFs')
ON CONFLICT(permission_key) DO UPDATE SET description=EXCLUDED.description;

INSERT INTO role_permissions(role_id,permission_id,scope)
SELECT r.id,p.id,'company'::permission_scope
FROM roles r
JOIN permissions p ON p.permission_key IN ('employee_contracts.view','employee_contracts.upload')
WHERE r.name='Super Admin'
   OR lower(r.name)='general manager'
   OR lower(r.name) IN ('hr','hr manager','human resources','people & hr')
ON CONFLICT DO NOTHING;
