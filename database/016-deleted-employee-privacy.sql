CREATE TABLE IF NOT EXISTS deleted_employee_archive (
  employee_id uuid PRIMARY KEY REFERENCES employees(id),
  company_id uuid NOT NULL REFERENCES companies(id),
  employee_number text NOT NULL,
  profile_snapshot jsonb NOT NULL,
  deleted_by uuid REFERENCES employees(id),
  deleted_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS deleted_employee_archive_company_idx
  ON deleted_employee_archive(company_id, deleted_at DESC);

INSERT INTO permissions(permission_key,description) VALUES
  ('employees.deleted.view','View deleted employee profiles and their historical audit records')
ON CONFLICT(permission_key) DO UPDATE SET description=EXCLUDED.description;

INSERT INTO role_permissions(role_id,permission_id,scope)
SELECT r.id,p.id,'company'::permission_scope
FROM roles r
JOIN permissions p ON p.permission_key='employees.deleted.view'
WHERE r.name='Super Admin'
ON CONFLICT(role_id,permission_id,scope) DO NOTHING;

INSERT INTO deleted_employee_archive(employee_id,company_id,employee_number,profile_snapshot,deleted_by,deleted_at)
SELECT e.id,e.company_id,e.employee_number,
       jsonb_build_object('employee',COALESCE(a.before_data,to_jsonb(e)),'profile',to_jsonb(o)),
       a.actor_employee_id,COALESCE(a.occurred_at,e.updated_at)
FROM employees e
LEFT JOIN employee_onboarding_profiles o ON o.employee_id=e.id
LEFT JOIN LATERAL (
  SELECT before_data,actor_employee_id,occurred_at
  FROM audit_events
  WHERE company_id=e.company_id AND entity_type='employee' AND entity_id=e.id::text AND action='employees.delete'
  ORDER BY occurred_at DESC LIMIT 1
) a ON true
WHERE e.status='deleted'
ON CONFLICT(employee_id) DO NOTHING;
