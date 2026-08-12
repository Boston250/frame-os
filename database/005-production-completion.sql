-- Forward-only production completion migration for existing FRAME OS installations.
ALTER TABLE export_jobs ADD COLUMN IF NOT EXISTS completed_at timestamptz;

CREATE TABLE IF NOT EXISTS asset_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), company_id uuid NOT NULL REFERENCES companies(id), employee_id uuid NOT NULL REFERENCES employees(id),
  asset_id uuid REFERENCES assets(id), request_type text NOT NULL CHECK(request_type IN ('equipment','repair','replacement','return')),
  description text NOT NULL, needed_by date, approval_request_id uuid REFERENCES approval_requests(id),
  status approval_status NOT NULL DEFAULT 'draft', created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS asset_requests_company_status_idx ON asset_requests(company_id,status,created_at DESC);

CREATE OR REPLACE FUNCTION frame_apply_approval_rejection() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.status='rejected' AND OLD.status IS DISTINCT FROM NEW.status THEN
    CASE NEW.entity_type
      WHEN 'contract' THEN UPDATE contracts SET status='rejected' WHERE id=NEW.entity_id;
      WHEN 'monthly_kpi_plan' THEN UPDATE monthly_kpi_plans SET status='rejected' WHERE id=NEW.entity_id;
      WHEN 'monthly_kpi_final' THEN UPDATE monthly_kpi_plans SET status='active',locked_at=NULL WHERE id=NEW.entity_id;
      WHEN 'leave_request' THEN UPDATE leave_requests SET status='rejected' WHERE id=NEW.entity_id;
      WHEN 'expense_request' THEN UPDATE expense_requests SET status='rejected' WHERE id=NEW.entity_id;
      WHEN 'budget' THEN UPDATE budgets SET status='rejected' WHERE id=NEW.entity_id;
      WHEN 'payroll_run' THEN UPDATE payroll_runs SET status='rejected' WHERE id=NEW.entity_id;
      WHEN 'purchase_request' THEN UPDATE purchase_requests SET status='rejected' WHERE id=NEW.entity_id;
      WHEN 'asset_request' THEN UPDATE asset_requests SET status='rejected' WHERE id=NEW.entity_id;
      WHEN 'special_package' THEN UPDATE packages SET status='inactive' WHERE id=NEW.entity_id;
      WHEN 'job_opening' THEN UPDATE job_openings SET status='draft' WHERE id=NEW.entity_id;
      ELSE NULL;
    END CASE;
    INSERT INTO notifications(company_id,recipient_id,type,title,body,entity_type,entity_id,priority)
    VALUES(NEW.company_id,NEW.requested_by,'approval_rejected','Request rejected',NEW.title,NEW.entity_type,NEW.entity_id,'high');
  END IF;
  RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS approval_rejection_outcome ON approval_requests;
CREATE TRIGGER approval_rejection_outcome AFTER UPDATE OF status ON approval_requests FOR EACH ROW EXECUTE FUNCTION frame_apply_approval_rejection();

CREATE OR REPLACE FUNCTION frame_notify_approval_authority() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE request_record approval_requests%ROWTYPE;
BEGIN
  IF NEW.status='pending' AND (TG_OP='INSERT' OR OLD.status IS DISTINCT FROM NEW.status) THEN
    SELECT * INTO request_record FROM approval_requests WHERE id=NEW.request_id;
    IF NEW.assignee_type='employee' THEN
      INSERT INTO notifications(company_id,recipient_id,type,title,body,entity_type,entity_id,priority)
      VALUES(request_record.company_id,NEW.assignee_ref::uuid,'approval_required','Approval required',request_record.title,request_record.entity_type,request_record.entity_id,'high');
    ELSIF NEW.assignee_type='manager' THEN
      INSERT INTO notifications(company_id,recipient_id,type,title,body,entity_type,entity_id,priority)
      SELECT request_record.company_id,e.manager_id,'approval_required','Approval required',request_record.title,request_record.entity_type,request_record.entity_id,'high'
      FROM employees e WHERE e.id=request_record.requested_by AND e.manager_id IS NOT NULL;
    ELSIF NEW.assignee_type='role' THEN
      INSERT INTO notifications(company_id,recipient_id,type,title,body,entity_type,entity_id,priority)
      SELECT DISTINCT request_record.company_id,er.employee_id,'approval_required','Approval required',request_record.title,request_record.entity_type,request_record.entity_id,'high'
      FROM employee_roles er JOIN roles r ON r.id=er.role_id JOIN employees e ON e.id=er.employee_id
      WHERE e.company_id=request_record.company_id AND r.name=NEW.assignee_ref AND er.valid_from<=now() AND (er.valid_until IS NULL OR er.valid_until>now());
    END IF;
  END IF;
  RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS approval_authority_notification ON approval_steps;
CREATE TRIGGER approval_authority_notification AFTER INSERT OR UPDATE OF status ON approval_steps FOR EACH ROW EXECUTE FUNCTION frame_notify_approval_authority();
