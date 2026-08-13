import assert from "node:assert/strict";
import {readFile} from "node:fs/promises";
import test from "node:test";

const read=path=>readFile(new URL(path,import.meta.url),"utf8");

test("HR receives complete finance accounting and approval access",async()=>{
  const migration=await read("../database/014-hr-finance-access.sql");
  for(const area of ["expenses","invoices","payroll","budgets","accounting","commissions"])assert.match(migration,new RegExp(`${area}\\.%`));
  for(const permission of ["reports.view","reports.export","approvals.view","approvals.approve","approvals.reject"])assert.ok(migration.includes(permission));
});

test("all approval workflows use deployed canonical role names",async()=>{
  const workflow=await read("../server/workflow-routes.mjs");
  assert.doesNotMatch(workflow,/ref:"HR"/);
  assert.match(workflow,/ref:"HR Manager"/);
  assert.match(workflow,/ref:"Finance"/);
});

test("live secondary tabs derive their real columns instead of employee placeholders",async()=>{
  const ui=await read("../app/frame-app.tsx");
  assert.match(ui,/const columns=rows\.length\?Object\.keys/);
  assert.match(ui,/column\.startsWith\("_"\)/);
});
