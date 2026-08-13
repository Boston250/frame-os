# Implementation plan — solution coverage complete

## Delivery principles

Each phase ends with a usable, tested vertical slice. Authorization, audit logging, mobile behavior and export restrictions are acceptance criteria, not later cleanup work.

All planned phases now have implemented interface coverage, schema contracts and workflow architecture. Remaining work is production activation with company data, infrastructure and provider credentials.

## Phase 0 — Foundation design (completed)

- Consolidate requirements and domain vocabulary.
- Establish module boundaries and dependency rules.
- Define foundation PostgreSQL schema.
- Define permission scopes and reusable workflow engine.
- Build responsive application shell and command-center prototype.
- Record deployment and backup topology.

**Exit gate:** architecture and dashboard information hierarchy approved.

## Phase 1 — Secure foundation

- Employee ID/password login, password reset and session revocation.
- Employee profiles, departments and manager reporting lines.
- Role editor, granular permissions and scoped assignments.
- Approval Center with versioned workflow definitions.
- Append-only audit log and CEO General Manager activity feed.
- Notification inbox and global search authorization skeleton.
- Seed Super Admin, CEO, General Manager and standard departments.

**Exit gate:** an administrator can onboard an employee, grant scoped access, submit and decide a sample approval, and inspect every action in the audit log.

## Phase 2 — Revenue lifecycle

- CRM, duplicate matching and customer ownership history.
- Custom sales pipelines, stages, activities and follow-ups.
- Service/package catalog and special-package approval.
- Contract creation and Sales Manager -> General Manager activation.
- Operations handover and renewal reminders.

**Exit gate:** a lead can move from creation to an immutable active contract with ownership, approvals, handover and audit history intact.

## Phase 3 — Delivery and performance

- Tasks, personal tasks and service delivery calendar.
- Submission, review, correction and revision history.
- Automatic overdue failure at 0% and maximum three-day extensions.
- Monthly KPI plans and salary-impact bands.
- Weekly KPI evidence, manager scoring and HR verification.
- Manual final monthly KPI approval and lock.
- Meetings, daily reports and relevant calendar views.

**Exit gate:** one employee completes a full monthly performance cycle with traceable task evidence and locked approvals.

## Phase 4 — People operations

- Authorized-network attendance, schedules, shifts and lateness.
- Leave, discipline, recruitment, hiring conversion and employee exit.
- Access disablement with retained history.

**Exit gate:** HR can manage the employee lifecycle without deleting historical records.

## Phase 5 — Finance and payroll

- Invoices, receivables, payables, expenses and budgets.
- Payroll calculation, configurable commissions and payment recording.
- Chart of accounts, journals, ledger, periods and financial statements.
- Department and client profitability.

**Exit gate:** a closed test period balances, reports reconcile, and approval restrictions pass independent review.

## Phase 6 — Resources and reporting

- Procurement, suppliers, subscriptions and expiry alerts.
- Assets, assignment, checkout/return, maintenance, damage and loss.
- Client complaints, baselines and periodic performance reports.
- Permission-controlled Excel and PDF exports.
- Email and high-priority WhatsApp delivery with retry history.

**Exit gate:** all finalized requirements have an owner, an acceptance test and production monitoring.

## Test strategy

- Unit tests for domain rules and state transitions.
- Integration tests against PostgreSQL for transactions, constraints and repositories.
- Authorization matrix tests for every protected command and query.
- Workflow tests for ordering, rejection, stale decisions and locked records.
- Browser tests for critical desktop and phone journeys.
- Security tests for session handling, rate limits, audit tampering and export access.
- Accounting reconciliation and payroll fixtures verified by Finance/HR stakeholders.

## Completed development backlog

1. Create PostgreSQL migration from `database/schema.sql`.
2. Implement employee ID generation and account/session repositories.
3. Implement `resource.action + scope` authorization policy.
4. Implement organization and employee administration screens.
5. Implement workflow definitions, instances, steps and decisions.
6. Wrap every mutation with the audit-event transaction helper.
7. Connect command-center metrics to server-side queries.
8. Add automated permission and audit integrity tests.
