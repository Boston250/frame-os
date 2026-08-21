UPDATE assets SET currency='RWF' WHERE currency IS NULL;
ALTER TABLE assets ALTER COLUMN currency SET DEFAULT 'RWF';
ALTER TABLE assets ALTER COLUMN currency SET NOT NULL;

ALTER TABLE assets DROP CONSTRAINT IF EXISTS assets_value_non_negative;
ALTER TABLE assets ADD CONSTRAINT assets_value_non_negative
  CHECK(value IS NULL OR value >= 0) NOT VALID;
