ALTER TABLE monthly_kpi_plans
  ADD COLUMN IF NOT EXISTS starts_on date,
  ADD COLUMN IF NOT EXISTS ends_on date;

ALTER TABLE monthly_kpi_plans
  DROP CONSTRAINT IF EXISTS monthly_kpi_plan_dates_check;

ALTER TABLE monthly_kpi_plans
  ADD CONSTRAINT monthly_kpi_plan_dates_check CHECK (starts_on IS NULL OR ends_on IS NULL OR ends_on >= starts_on);
