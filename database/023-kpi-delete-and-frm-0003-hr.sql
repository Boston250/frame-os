INSERT INTO permissions(permission_key,description) VALUES
  ('kpi_documents.delete','Delete KPI PDF documents')
ON CONFLICT(permission_key) DO UPDATE SET description=EXCLUDED.description;

INSERT INTO role_permissions(role_id,permission_id,scope)
SELECT r.id,p.id,'company'::permission_scope
FROM roles r
JOIN permissions p ON p.permission_key='kpi_documents.delete'
WHERE r.name='Super Admin'
   OR lower(r.name)='general manager'
   OR lower(r.name) IN ('hr','hr manager','human resources','people & hr')
ON CONFLICT DO NOTHING;

INSERT INTO employee_roles(employee_id,role_id,department_id,assigned_by)
SELECT target.id,hr_role.id,target.department_id,COALESCE(admin.id,target.id)
FROM employees target
JOIN LATERAL (
  SELECT r.id
  FROM roles r
  WHERE r.company_id=target.company_id
    AND r.status='active'
    AND lower(r.name) IN ('hr','hr manager','human resources','people & hr')
  ORDER BY CASE lower(r.name) WHEN 'hr' THEN 0 WHEN 'hr manager' THEN 1 ELSE 2 END
  LIMIT 1
) hr_role ON true
LEFT JOIN employees admin ON admin.company_id=target.company_id AND admin.employee_number='FRM-0001' AND admin.status='active'
WHERE target.employee_number='FRM-0003'
  AND target.status='active'
  AND NOT EXISTS (
    SELECT 1 FROM employee_roles er
    WHERE er.employee_id=target.id
      AND er.role_id=hr_role.id
      AND er.valid_until IS NULL
  );
