import assert from "node:assert/strict";
import {readFile} from "node:fs/promises";
import test from "node:test";

test("deleted employee profiles and history are visible only to Super Admin",async()=>{
  const [migration,lifecycle,core,admin,profile,ui,api,worker]=await Promise.all([
    readFile(new URL("../database/016-deleted-employee-privacy.sql",import.meta.url),"utf8"),
    readFile(new URL("../server/employee-lifecycle-routes.mjs",import.meta.url),"utf8"),
    readFile(new URL("../server/index.mjs",import.meta.url),"utf8"),
    readFile(new URL("../server/admin-routes.mjs",import.meta.url),"utf8"),
    readFile(new URL("../server/employee-profile-routes.mjs",import.meta.url),"utf8"),
    readFile(new URL("../app/frame-app.tsx",import.meta.url),"utf8"),
    readFile(new URL("../app/api-client.ts",import.meta.url),"utf8"),
    readFile(new URL("../worker/jobs.mjs",import.meta.url),"utf8"),
  ]);
  assert.match(migration,/deleted_employee_archive/);
  assert.match(migration,/r\.name='Super Admin'/);
  assert.doesNotMatch(migration,/r\.name IN \([^)]*HR/);
  assert.match(lifecycle,/employees\.deleted\.view/);
  assert.match(lifecycle,/profile_snapshot/);
  assert.match(lifecycle,/\/history/);
  assert.match(core,/e\.status<>'deleted'/);
  assert.match(admin,/status<>'deleted'/);
  assert.match(admin,/deleted_employee_archive/);
  assert.match(profile,/e\.status<>'deleted'/);
  assert.match(worker,/status<>'deleted'/);
  assert.match(worker,/deleted_employee_archive/);
  assert.match(ui,/permissions\.includes\("employees\.deleted\.view"\)/);
  assert.match(ui,/Deleted archive/);
  assert.match(api,/deletedEmployees/);
  assert.match(api,/deletedEmployeeHistory/);
});
