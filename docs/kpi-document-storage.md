# KPI document storage

KPI PDF files are stored outside PostgreSQL at `/var/lib/frame/kpi-documents`. Employee-contract PDFs are stored at `/var/lib/frame/employee-contracts`.

For Coolify production, add persistent storage for `/var/lib/frame`. This keeps KPI PDFs, employee-contract PDFs, and generated exports when the application is rebuilt or redeployed.

The application accepts PDFs only, up to 3 MB each. Database records store the document title, original filename, uploader, upload time, and the secured file reference.
