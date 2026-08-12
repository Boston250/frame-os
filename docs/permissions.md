# Permission model

## Permission format

A permission is `resource.action` plus one scope:

- `self` — own employee-linked records;
- `assigned` — records currently assigned to the actor;
- `department` — records within departments the actor manages;
- `company` — company-wide records.

Initial actions are `view`, `create`, `edit`, `approve`, `reject`, `export`, `assign`, `reassign`, `archive`, and `configure`. Modules may add narrow actions such as `contracts.terminate`.

## Initial role intent

| Role | Visibility | Mutation limits |
|---|---|---|
| Super Admin | Company | Explicit technical/business bypass; all use audited |
| CEO | Company | Acts only through granted permissions; final approvals where specified |
| General Manager | Company | Broad view; no implicit CEO-only or Super Admin-only action |
| Department Manager | Department | Manages assigned departments and direct reports |
| HR | People/performance company scope | HR workflow steps; no unrelated finance or CRM mutation |
| Finance | Finance company scope | Finance workflow steps and posting rights by assignment |
| Sales Manager | Sales department and assigned clients | Pipeline, reassignment and first contract approval |
| Employee | Self and assigned | Own submissions, assigned customers/tasks and requests |

Roles are templates, not hard-coded conditionals. Users receive role assignments and optional narrow grants. Denials and record-scope checks are evaluated server-side for both page queries and commands.

## Non-negotiable rules

- Customer access ends immediately when ownership is reassigned.
- Active contracts cannot be edited or terminated except through Super Admin commands.
- Only CEO and General Manager configure standard services/packages.
- Only current approval-step assignees can decide a request.
- Export requires the same view scope plus an explicit export permission.
- Normal users cannot modify audit events.
- General Manager activity is visible in the dedicated CEO feed.
