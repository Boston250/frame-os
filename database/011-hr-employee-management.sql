INSERT INTO role_permissions(role_id,permission_id,scope)
SELECT r.id,p.id,'company'::permission_scope
FROM roles r
JOIN permissions p ON p.permission_key IN (
  'employees.view','employees.create','employees.edit','employees.reset_password','employees.exit','employees.sensitive','departments.view'
)
WHERE lower(r.name) LIKE '%hr%'
ON CONFLICT(role_id,permission_id,scope) DO NOTHING;
