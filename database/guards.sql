-- Database safety guards for FRAME OS.
CREATE OR REPLACE FUNCTION prevent_audit_mutation() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN RAISE EXCEPTION 'audit events are immutable'; END $$;
CREATE TRIGGER audit_no_update BEFORE UPDATE OR DELETE ON audit_events FOR EACH ROW EXECUTE FUNCTION prevent_audit_mutation();

CREATE OR REPLACE FUNCTION prevent_active_contract_mutation() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF OLD.status='active' AND current_setting('app.super_admin',true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'active contracts can only be revised by Super Admin';
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER contract_active_guard BEFORE UPDATE OR DELETE ON contracts FOR EACH ROW EXECUTE FUNCTION prevent_active_contract_mutation();

CREATE OR REPLACE FUNCTION prevent_kpi_lock_mutation() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF OLD.status='locked' THEN RAISE EXCEPTION 'locked KPI plans are immutable'; END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER kpi_lock_guard BEFORE UPDATE OR DELETE ON monthly_kpi_plans FOR EACH ROW EXECUTE FUNCTION prevent_kpi_lock_mutation();

CREATE OR REPLACE FUNCTION validate_balanced_journal() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE debit_total numeric; credit_total numeric;
BEGIN
  IF NEW.status='posted' THEN
    SELECT COALESCE(sum(debit),0),COALESCE(sum(credit),0) INTO debit_total,credit_total FROM journal_lines WHERE journal_entry_id=NEW.id;
    IF debit_total=0 OR debit_total<>credit_total THEN RAISE EXCEPTION 'journal entry must balance before posting'; END IF;
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER journal_balance_guard BEFORE UPDATE OF status ON journal_entries FOR EACH ROW EXECUTE FUNCTION validate_balanced_journal();

CREATE OR REPLACE FUNCTION prevent_closed_period_posting() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF EXISTS(SELECT 1 FROM financial_periods WHERE company_id=NEW.company_id AND NEW.entry_date BETWEEN starts_on AND ends_on AND status='closed') THEN
    RAISE EXCEPTION 'financial period is closed';
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER journal_closed_period_guard BEFORE INSERT OR UPDATE ON journal_entries FOR EACH ROW EXECUTE FUNCTION prevent_closed_period_posting();

CREATE OR REPLACE FUNCTION prevent_business_delete() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN RAISE EXCEPTION 'business records cannot be deleted'; END $$;
CREATE TRIGGER customers_no_delete BEFORE DELETE ON customers FOR EACH ROW EXECUTE FUNCTION prevent_business_delete();
CREATE TRIGGER contracts_no_delete BEFORE DELETE ON contracts FOR EACH ROW EXECUTE FUNCTION prevent_business_delete();
CREATE TRIGGER tasks_no_delete BEFORE DELETE ON tasks FOR EACH ROW EXECUTE FUNCTION prevent_business_delete();
CREATE TRIGGER employees_no_delete BEFORE DELETE ON employees FOR EACH ROW EXECUTE FUNCTION prevent_business_delete();
CREATE TRIGGER invoices_no_delete BEFORE DELETE ON invoices FOR EACH ROW EXECUTE FUNCTION prevent_business_delete();
CREATE TRIGGER assets_no_delete BEFORE DELETE ON assets FOR EACH ROW EXECUTE FUNCTION prevent_business_delete();
