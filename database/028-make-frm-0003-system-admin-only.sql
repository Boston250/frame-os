-- FRM-0003 is the System Admin account, not an HR employee.
UPDATE employees SET department_id=NULL WHERE employee_number='FRM-0003';
UPDATE employee_roles SET department_id=NULL
WHERE employee_id=(SELECT id FROM employees WHERE employee_number='FRM-0003');

INSERT INTO employee_roles(employee_id,role_id,department_id,assigned_by)
SELECT e.id,r.id,NULL,e.id FROM employees e JOIN roles r ON r.company_id=e.company_id AND r.name='System Admin'
WHERE e.employee_number='FRM-0003'
  AND NOT EXISTS (SELECT 1 FROM employee_roles er JOIN roles existing ON existing.id=er.role_id WHERE er.employee_id=e.id AND existing.name='System Admin' AND er.valid_until IS NULL);
