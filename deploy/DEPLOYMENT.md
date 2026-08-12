# FRAME OS production deployment

1. Provision an Ubuntu LTS VPS with Docker and a DNS record for the FRAME OS domain.
2. Copy `.env.example` to `.env` and provide strong database/session secrets, SMTP, WhatsApp and backup settings.
3. Place TLS certificate files in `deploy/certs` or replace the Nginx certificate paths with the selected certificate automation.
4. Start PostgreSQL and Redis, then run `npm run db:migrate` and `npm run db:seed` from the application image.
5. Record the generated first Super Admin password once, sign in, and change it immediately.
6. Add the public IP/CIDR of the `FRAME MEDIA AGENCY` office connection to `attendance_networks`.
7. Start the application, API, worker and Nginx services.
8. Verify health, authentication, permissions, attendance restriction, approval chains, PDF/XLSX output and notification delivery.
9. Schedule encrypted PostgreSQL backups to independent storage and perform a restore test before staff onboarding.
10. Enter departments, employees, roles, services, packages, schedules and approval authorities through FRAME OS.

No legacy records are imported. Production begins from an empty business dataset apart from the first Super Admin and required system configuration.
