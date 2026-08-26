ALTER TABLE kpi_documents DROP CONSTRAINT IF EXISTS kpi_documents_file_size_check;
ALTER TABLE kpi_documents ADD CONSTRAINT kpi_documents_file_size_check CHECK (file_size > 0 AND file_size <= 3145728);
