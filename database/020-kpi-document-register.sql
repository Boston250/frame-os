CREATE TABLE IF NOT EXISTS kpi_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  title text NOT NULL CHECK (length(trim(title)) BETWEEN 1 AND 180),
  original_filename text NOT NULL,
  stored_filename text NOT NULL UNIQUE,
  mime_type text NOT NULL DEFAULT 'application/pdf' CHECK (mime_type = 'application/pdf'),
  file_size integer NOT NULL CHECK (file_size > 0 AND file_size <= 3145728),
  uploaded_by uuid NOT NULL REFERENCES employees(id),
  uploaded_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS kpi_documents_company_uploaded_at_idx ON kpi_documents(company_id, uploaded_at DESC);

INSERT INTO permissions(permission_key,description) VALUES
  ('kpi_documents.view','View KPI PDF documents'),
  ('kpi_documents.upload','Upload KPI PDF documents')
ON CONFLICT(permission_key) DO UPDATE SET description=EXCLUDED.description;

INSERT INTO role_permissions(role_id,permission_id,scope)
SELECT r.id,p.id,'company'::permission_scope
FROM roles r
JOIN permissions p ON p.permission_key IN ('kpi_documents.view','kpi_documents.upload')
WHERE r.name='Super Admin'
   OR lower(r.name)='general manager'
   OR lower(r.name) IN ('hr','hr manager','human resources','people & hr')
ON CONFLICT DO NOTHING;
