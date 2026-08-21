import test from "node:test";
import assert from "node:assert/strict";
import {readFile} from "node:fs/promises";

test("KPI plans assign active employees, project dates and weighted task rows",async()=>{
  const [app,api,routes,migration,migrator]=await Promise.all([
    readFile(new URL("../app/frame-app.tsx",import.meta.url),"utf8"),
    readFile(new URL("../app/api-client.ts",import.meta.url),"utf8"),
    readFile(new URL("../server/extended-routes.mjs",import.meta.url),"utf8"),
    readFile(new URL("../database/018-kpi-project-plans.sql",import.meta.url),"utf8"),
    readFile(new URL("../server/migrate.mjs",import.meta.url),"utf8"),
  ]);
  assert.match(app,/function KpiPlanDrawer/);
  assert.match(app,/Select available employee/);
  assert.match(app,/Project start date/);
  assert.match(app,/Project end date/);
  assert.match(app,/Add row/);
  assert.match(app,/Total rate/);
  assert.match(app,/total KPI rate must equal 100%/i);
  assert.match(api,/kpiAssignees/);
  assert.match(routes,/api\\\/kpi-assignees/);
  assert.match(routes,/INSERT INTO monthly_kpi_items/);
  assert.match(routes,/total KPI rate must equal 100%/i);
  assert.match(routes,/employee\.department_id!==s\.department_id/);
  assert.match(migration,/starts_on date/);
  assert.match(migration,/ends_on date/);
  assert.match(migrator,/018-kpi-project-plans\.sql/);
});
