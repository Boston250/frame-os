INSERT INTO role_permissions(role_id,permission_id,scope)
SELECT r.id,p.id,'company'::permission_scope
FROM roles r
JOIN permissions p ON p.permission_key IN (
  'employees.view','employees.create','employees.edit','employees.reset_password','employees.exit','employees.sensitive','departments.view'
)
WHERE lower(r.name) LIKE '%hr%'
ON CONFLICT(role_id,permission_id,scope) DO NOTHING;

INSERT INTO permissions(permission_key,description) VALUES
  ('employees.assign_role','Assign an existing role to an employee')
ON CONFLICT(permission_key) DO NOTHING;

INSERT INTO role_permissions(role_id,permission_id,scope)
SELECT r.id,p.id,'company'::permission_scope FROM roles r
JOIN permissions p ON p.permission_key='employees.assign_role'
WHERE lower(r.name) LIKE '%hr%'
ON CONFLICT(role_id,permission_id,scope) DO NOTHING;
