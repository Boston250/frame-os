INSERT INTO permissions(permission_key,description) VALUES
  ('kpi_documents.view','View KPI PDF documents'),
  ('kpi_documents.upload','Upload KPI PDF documents'),
  ('kpi_documents.delete','Delete KPI PDF documents'),
  ('employee_contracts.view','View employee contract PDFs'),
  ('employee_contracts.upload','Upload employee contract PDFs')
ON CONFLICT(permission_key) DO UPDATE SET description=EXCLUDED.description;

INSERT INTO role_permissions(role_id,permission_id,scope)
SELECT er.role_id,p.id,'company'::permission_scope
FROM employee_roles er
JOIN employees e ON e.id=er.employee_id
JOIN permissions p ON p.permission_key IN (
  'kpi_documents.view','kpi_documents.upload','kpi_documents.delete',
  'employee_contracts.view','employee_contracts.upload'
)
WHERE e.employee_number='FRM-0003'
  AND e.status='active'
  AND er.valid_from<=now()
  AND (er.valid_until IS NULL OR er.valid_until>now())
ON CONFLICT DO NOTHING;
