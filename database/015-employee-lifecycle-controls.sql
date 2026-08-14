ALTER TYPE employee_status ADD VALUE IF NOT EXISTS 'deleted';
INSERT INTO permissions(permission_key,description) VALUES
 ('employees.deactivate','Deactivate employee access while retaining company history'),
 ('employees.delete','Delete an unused employee account while retaining an audit marker')
ON CONFLICT(permission_key) DO UPDATE SET description=EXCLUDED.description;
INSERT INTO role_permissions(role_id,permission_id,scope)
SELECT r.id,p.id,'company'::permission_scope FROM roles r CROSS JOIN permissions p
WHERE p.permission_key IN ('employees.deactivate','employees.delete') AND (lower(r.name) LIKE '%hr%' OR r.name IN ('Super Admin','CEO','General Manager'))
ON CONFLICT(role_id,permission_id,scope) DO NOTHING;
