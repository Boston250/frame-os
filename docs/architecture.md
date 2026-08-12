# FRAME OS architecture

## Architecture decision

FRAME OS starts as a modular monolith. One application is deployed, but business capabilities are isolated behind explicit module boundaries. This reduces operating complexity for a 20+ person company and avoids coupling the domain to page components. Modules can later be extracted without redesigning the data or permissions model.

```text
Browser (desktop / tablet / phone)
  -> Nginx (TLS, rate limits, security headers)
    -> Web application
       -> application services and authorization policy
       -> PostgreSQL (authoritative business data)
       -> Redis (jobs, short-lived cache, rate limits)
       -> worker (deadlines, reminders, exports, email, WhatsApp)
```

## Layers

1. **Presentation** — routes, forms, tables, dashboards and responsive navigation.
2. **Application** — commands and queries such as `ApproveExpense`, `ReassignCustomer` and `ScoreTask`.
3. **Domain** — rules, state transitions, identifiers and invariants independent of the web framework.
4. **Infrastructure** — PostgreSQL repositories, email, WhatsApp, export generation and job processing.

Every mutation follows the same pipeline:

```text
authenticate -> authorize -> validate command -> execute transaction
-> append audit event -> enqueue notifications -> return safe response
```

## Module boundaries

| Module | Owns | Initial delivery |
|---|---|---|
| Identity | accounts, sessions, password policy | Foundation |
| Organization | employees, departments, reporting lines | Foundation |
| Access control | roles, permissions, scoped grants | Foundation |
| Workflow | approval definitions, steps, decisions | Foundation |
| Audit | immutable action history | Foundation |
| CRM | customers, ownership, leads, pipeline | Phase 2 |
| Clients | services, packages, contracts, handovers | Phase 2 |
| Operations | tasks, delivery, calendar, reports | Phase 3 |
| Performance | monthly KPI, weekly evidence, scores | Phase 3 |
| People | attendance, leave, discipline, recruitment | Phase 4 |
| Finance | invoices, payroll, budgets, ledger | Phase 5 |
| Resources | procurement, suppliers, subscriptions, assets | Phase 6 |
| Communications | in-app, email, WhatsApp | Cross-cutting |
| Reporting | dashboards, PDF and Excel exports | Cross-cutting |

Modules may read another module through queries but must mutate it through its public application service. Cross-module writes occur in one transaction or through a durable job.

## Identity and authorization

- Login identifier is the generated employee ID (`FRM-0001`) plus password.
- Passwords use memory-hardened scrypt with per-password random salts; only the encoded password hash is stored.
- Sessions use random opaque tokens in secure, HTTP-only, same-site cookies. Only a token hash is stored server-side.
- Access checks use `resource.action` permissions, for example `contracts.approve`.
- A grant also has a scope: `self`, `assigned`, `department`, or `company`.
- Super Admin bypass is explicit and audited. CEO and General Manager have broad visibility but actions still require their assigned permission.
- Customer access is ownership-based. Reassignment closes the old ownership interval in the same database transaction before opening the new one.

## Data guarantees

- Business records use UUID primary keys and human-readable reference numbers from transaction-safe counters.
- Timestamps are stored in UTC and rendered in the company timezone.
- Money uses decimal amounts plus ISO currency codes; never floating point.
- No business record is hard-deleted. Status and archival fields preserve history.
- Active contracts become immutable. Super Admin corrections create audited revisions.
- Audit events are append-only and contain actor, action, entity, request context and before/after snapshots.
- Financial posting uses balanced journal entries and closed-period protection.

## Workflow engine

Approval requests are reusable records rather than columns repeated across modules. A workflow definition is versioned. When a request starts, its step sequence is copied into an instance so later configuration changes cannot alter active approvals.

Examples:

- Contract: Sales Manager -> General Manager -> Active; CEO notified.
- Monthly KPI plan: Manager -> HR -> General Manager -> CEO -> Active and locked.
- Payroll: HR -> General Manager -> CEO -> Confirmed; Finance records external payment.
- Leave: Manager -> HR -> Approved.

Only the current pending step can be decided. Rejecting terminates or returns the request according to the workflow definition. Every decision is audited.

## Scheduled rules

The worker runs idempotent jobs with retry and dead-letter handling:

- fail overdue unsubmitted tasks at 0%;
- send seven-day contract renewal reminders and client email;
- flag leads with no activity for seven days;
- send subscription expiry reminders;
- materialize notification deliveries;
- generate PDF/Excel exports;
- perform daily backup verification.

Task deadline extensions are limited to three calendar days from the current deadline, require a reason, and are append-only. The rule is enforced by the domain service and database constraint/transaction, not only the interface.

## Production topology

- Ubuntu LTS VPS, Docker Compose for the first production stage.
- Nginx terminates TLS and proxies only to the application.
- PostgreSQL and Redis are not publicly exposed.
- Separate worker process uses the same application image.
- Secrets are provided as runtime environment variables.
- Daily encrypted PostgreSQL backups are copied to independent object storage and restore-tested monthly.
- Health endpoints, structured logs, error tracking and uptime monitoring are required before launch.

## Repository target structure

```text
app/                         routes and UI composition
modules/
  identity/                  domain, application, infrastructure
  organization/
  access-control/
  workflow/
  audit/
  crm/
  clients/
  operations/
  performance/
  people/
  finance/
  resources/
shared/                      errors, ids, money, time, database
worker/                      scheduled and queued job entrypoint
database/                    PostgreSQL schema and migrations
docs/                        decisions and delivery documentation
tests/                       unit, integration, authorization, browser
```
