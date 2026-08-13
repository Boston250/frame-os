-- Separate frontline sales access from the standard Employee role.
INSERT INTO roles(company_id,name,description)
SELECT id,'Salesperson','Manages assigned leads, customers, follow-ups, sales tasks and personal commission records'
FROM companies
ON CONFLICT(company_id,name) DO UPDATE SET description=EXCLUDED.description;

INSERT INTO role_permissions(role_id,permission_id,scope)
SELECT r.id,p.id,
  CASE WHEN p.permission_key LIKE 'customers.%' OR p.permission_key LIKE 'contracts.%'
    THEN 'assigned'::permission_scope ELSE 'self'::permission_scope END
FROM roles r
JOIN permissions p ON p.permission_key IN (
  'dashboard.view','customers.view','customers.create','customers.edit',
  'contracts.view','contracts.create','tasks.view','tasks.create','tasks.edit',
  'daily_reports.submit','attendance.view','leave.view','leave.create',
  'commissions.view','search.global'
)
WHERE r.name='Salesperson'
ON CONFLICT DO NOTHING;
