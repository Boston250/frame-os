ALTER TABLE employee_onboarding_profiles
  DROP COLUMN IF EXISTS contract_file_name,
  DROP COLUMN IF EXISTS contract_mime_type,
  DROP COLUMN IF EXISTS contract_document;
