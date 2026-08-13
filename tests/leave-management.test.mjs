import test from "node:test";
import assert from "node:assert/strict";
import {readFile} from "node:fs/promises";

const read=path=>readFile(new URL(path,import.meta.url),"utf8");

test("leave requests have balances, validation and two-step approval",async()=>{
  const [migration,routes,workflow,ui,api]=await Promise.all([
    read("../database/013-leave-management.sql"),read("../server/extended-routes.mjs"),read("../server/workflow-routes.mjs"),read("../app/frame-app.tsx"),read("../app/api-client.ts")
  ]);
  assert.match(migration,/CREATE TABLE IF NOT EXISTS leave_balances/);
  assert.match(routes,/overlap an existing leave request/);
  assert.match(routes,/generate_series/);
  assert.match(workflow,/HR Manager/);
  assert.match(workflow,/approval_request_id=\$2/);
  assert.match(ui,/Submit for approval/);
  assert.match(api,/submitLeave/);
});
