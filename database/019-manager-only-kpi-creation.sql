DELETE FROM role_permissions rp
USING roles r, permissions p
WHERE rp.role_id=r.id
  AND rp.permission_id=p.id
  AND p.permission_key='kpi.create'
  AND lower(r.name) IN ('hr','hr manager','human resources','people & hr');
