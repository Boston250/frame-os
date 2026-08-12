# FRAME OS

Internal business operations system for FRAME Media Agency. It includes the responsive staff interface, authenticated application API, PostgreSQL business data, approval automation, background notifications and exports, audit controls, and the VPS deployment package.

## Production scope

The current implementation covers:

- employee identity and account lifecycle;
- dynamic departments, roles and granular permissions;
- approval inbox and reusable approval chains;
- immutable audit history;
- responsive application shell and executive dashboard;
- PostgreSQL persistence for CRM, contracts, operations, KPI, attendance, HR, finance, payroll, procurement, assets, recruitment and reporting;
- live module and tab data when `NEXT_PUBLIC_FRAME_API_MODE=live`;
- PDF/Excel exports, email/WhatsApp delivery jobs, backups and restore verification.

## Documents

- `docs/architecture.md` — application structure, security, deployment and module map
- `docs/implementation-plan.md` — delivery phases, acceptance gates and priorities
- `docs/permissions.md` — authorization model and initial role matrix
- `docs/coverage.md` — weighted module coverage and remaining launch gates
- `database/schema.sql` — PostgreSQL foundation schema

## Local commands

```bash
npm install
npm run dev
npm run build
```

## Deployment target

Production is designed for a VPS/cloud server using containerized services: application, PostgreSQL, Redis, background worker and Nginx. Daily encrypted database backups are retained outside the VPS.
