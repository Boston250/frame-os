INSERT INTO permissions(permission_key,description) VALUES
  ('employees.assign_role','Assign an existing non-administrator role to an employee')
ON CONFLICT(permission_key) DO UPDATE SET description=EXCLUDED.description;

INSERT INTO role_permissions(role_id,permission_id,scope)
SELECT r.id,p.id,'company'::permission_scope
FROM roles r
JOIN permissions p ON p.permission_key IN ('employees.assign_role','reports.export')
WHERE lower(r.name) LIKE '%hr%'
ON CONFLICT(role_id,permission_id,scope) DO NOTHING;
