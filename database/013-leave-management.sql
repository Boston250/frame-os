CREATE TABLE IF NOT EXISTS leave_policies (
  company_id uuid NOT NULL REFERENCES companies(id), leave_type text NOT NULL,
  annual_days numeric(6,2) NOT NULL DEFAULT 0 CHECK(annual_days >= 0),
  requires_balance boolean NOT NULL DEFAULT true, status record_status NOT NULL DEFAULT 'active',
  PRIMARY KEY(company_id,leave_type)
);
CREATE TABLE IF NOT EXISTS leave_balances (
  employee_id uuid NOT NULL REFERENCES employees(id), leave_type text NOT NULL, balance_year integer NOT NULL,
  entitled_days numeric(6,2) NOT NULL DEFAULT 0 CHECK(entitled_days >= 0), carried_days numeric(6,2) NOT NULL DEFAULT 0 CHECK(carried_days >= 0),
  reserved_days numeric(6,2) NOT NULL DEFAULT 0 CHECK(reserved_days >= 0), used_days numeric(6,2) NOT NULL DEFAULT 0 CHECK(used_days >= 0),
  updated_at timestamptz NOT NULL DEFAULT now(), PRIMARY KEY(employee_id,leave_type,balance_year)
);
ALTER TABLE leave_requests ADD COLUMN IF NOT EXISTS total_days numeric(6,2) NOT NULL DEFAULT 0;
ALTER TABLE leave_requests ADD COLUMN IF NOT EXISTS submitted_at timestamptz;
ALTER TABLE leave_requests ADD COLUMN IF NOT EXISTS decided_at timestamptz;
INSERT INTO leave_policies(company_id,leave_type,annual_days,requires_balance)
SELECT id,v.leave_type,v.days,v.requires_balance FROM companies CROSS JOIN (VALUES ('annual',18::numeric,true),('sick',10::numeric,true),('unpaid',0::numeric,false)) v(leave_type,days,requires_balance)
ON CONFLICT(company_id,leave_type) DO NOTHING;
INSERT INTO permissions(permission_key,description) VALUES ('leave.manage','Manage company leave balances and records') ON CONFLICT(permission_key) DO UPDATE SET description=EXCLUDED.description;
INSERT INTO role_permissions(role_id,permission_id,scope)
SELECT r.id,p.id,'company'::permission_scope FROM roles r CROSS JOIN permissions p WHERE p.permission_key='leave.manage' AND (lower(r.name) LIKE '%hr%' OR r.name IN ('Super Admin','CEO','General Manager'))
ON CONFLICT(role_id,permission_id,scope) DO NOTHING;

CREATE OR REPLACE FUNCTION release_rejected_leave_balance() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF OLD.status='pending' AND NEW.status IN ('rejected','cancelled') THEN
    UPDATE leave_balances SET reserved_days=GREATEST(0,reserved_days-NEW.total_days),updated_at=now()
    WHERE employee_id=NEW.employee_id AND leave_type=NEW.leave_type AND balance_year=extract(year FROM NEW.starts_on)::integer;
    NEW.decided_at=now();
  END IF;
  RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS leave_balance_release_trigger ON leave_requests;
CREATE TRIGGER leave_balance_release_trigger BEFORE UPDATE OF status ON leave_requests FOR EACH ROW EXECUTE FUNCTION release_rejected_leave_balance();
