INSERT INTO permissions(permission_key,description) VALUES
  ('attendance.configure','Configure authorized attendance networks and schedules')
ON CONFLICT(permission_key) DO UPDATE SET description=EXCLUDED.description;

INSERT INTO role_permissions(role_id,permission_id,scope)
SELECT r.id,p.id,'company'::permission_scope
FROM roles r CROSS JOIN permissions p
WHERE r.name='Super Admin' AND p.permission_key='attendance.configure'
ON CONFLICT DO NOTHING;
