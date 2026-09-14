-- User-authorized clean start: retain organization setup and FRM-0003 only.
DO $$
DECLARE names text;
BEGIN
  SELECT string_agg(format('%I.%I',schemaname,tablename), ', ' ORDER BY tablename)
    INTO names
  FROM pg_tables
  WHERE schemaname='public'
    AND tablename NOT IN ('schema_migrations','companies','departments','roles','permissions','role_permissions','employees','employee_roles','user_accounts');
  IF names IS NOT NULL THEN EXECUTE 'TRUNCATE TABLE ' || names || ' RESTART IDENTITY'; END IF;
END $$;

DELETE FROM employee_roles WHERE employee_id NOT IN (SELECT id FROM employees WHERE employee_number='FRM-0003');
DELETE FROM user_accounts WHERE employee_id NOT IN (SELECT id FROM employees WHERE employee_number='FRM-0003');
DELETE FROM employees WHERE employee_number<>'FRM-0003';
