-- FRAME OS has four operating departments and six access roles.
INSERT INTO roles(company_id,name,description)
SELECT c.id,v.name,v.description FROM companies c CROSS JOIN (VALUES
  ('HR','Human Resources'),('Sales Manager','Sales leadership'),('Salesperson','Sales employee'),
  ('Marketing','Marketing employee'),('Production','Production employee'),('CEO','Chief Executive Officer'),('System Admin','Full system administration')
) v(name,description)
WHERE NOT EXISTS (SELECT 1 FROM roles r WHERE r.company_id=c.id AND r.name=v.name);

INSERT INTO role_permissions(role_id,permission_id,scope)
SELECT r.id,p.id,'company'::permission_scope FROM roles r JOIN permissions p ON true
WHERE r.name IN ('System Admin','Super Admin')
ON CONFLICT DO NOTHING;

UPDATE employees SET department_id=(SELECT d.id FROM departments d WHERE d.company_id=employees.company_id AND d.code='HR' LIMIT 1)
WHERE employee_number='FRM-0003';

INSERT INTO employee_roles(employee_id,role_id,department_id,assigned_by)
SELECT e.id,r.id,e.department_id,e.id FROM employees e JOIN roles r ON r.company_id=e.company_id AND r.name='System Admin'
WHERE e.employee_number='FRM-0003'
  AND NOT EXISTS (SELECT 1 FROM employee_roles er JOIN roles existing ON existing.id=er.role_id WHERE er.employee_id=e.id AND existing.name='System Admin' AND er.valid_until IS NULL);
