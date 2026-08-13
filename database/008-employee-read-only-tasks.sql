DELETE FROM role_permissions rp USING roles r,permissions p
WHERE rp.role_id=r.id AND rp.permission_id=p.id AND r.name='Employee'
  AND p.permission_key IN ('tasks.create','tasks.edit');

INSERT INTO role_permissions(role_id,permission_id,scope)
SELECT r.id,p.id,'self'::permission_scope FROM roles r
JOIN permissions p ON p.permission_key IN ('tasks.view','kpi.view')
WHERE r.name='Employee' ON CONFLICT DO NOTHING;
