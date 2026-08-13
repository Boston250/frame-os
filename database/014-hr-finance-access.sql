INSERT INTO role_permissions(role_id,permission_id,scope)
SELECT r.id,p.id,'company'::permission_scope
FROM roles r
JOIN permissions p ON
  p.permission_key LIKE 'expenses.%' OR p.permission_key LIKE 'invoices.%' OR
  p.permission_key LIKE 'payroll.%' OR p.permission_key LIKE 'budgets.%' OR
  p.permission_key LIKE 'accounting.%' OR p.permission_key LIKE 'commissions.%' OR
  p.permission_key IN ('reports.view','reports.export','approvals.view','approvals.approve','approvals.reject')
WHERE lower(r.name) IN ('hr','hr manager','human resources','people & hr')
ON CONFLICT(role_id,permission_id,scope) DO NOTHING;
