import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
test("all finalized business domains have persistence contracts",async()=>{const sql=await readFile(new URL("../database/remaining-modules.sql",import.meta.url),"utf8");for(const table of ["daily_reports","meetings","disciplinary_cases","job_openings","candidates","employee_exits","client_complaints","client_performance_reports","expense_requests","commission_rules","asset_events","notification_deliveries","outbound_jobs","export_jobs"])assert.match(sql,new RegExp(`CREATE TABLE ${table}`));});
test("database guards protect audit, active contracts, KPI and journals",async()=>{const sql=await readFile(new URL("../database/guards.sql",import.meta.url),"utf8");for(const guard of ["audit_no_update","contract_active_guard","kpi_lock_guard","journal_balance_guard"])assert.match(sql,new RegExp(guard));});
