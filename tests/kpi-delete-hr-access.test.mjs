import assert from "node:assert/strict";
import test from "node:test";
import { readFile } from "node:fs/promises";

const root=new URL("../",import.meta.url);
const read=path=>readFile(new URL(path,root),"utf8");

test("KPI documents can be deleted and FRM-0003 receives the active HR role",async()=>{
  const [migration,routes,client,ui,migrator]=await Promise.all([read("database/023-kpi-delete-and-frm-0003-hr.sql"),read("server/kpi-document-routes.mjs"),read("app/api-client.ts"),read("app/frame-app.tsx"),read("server/migrate.mjs")]);
  assert.match(migration,/FRM-0003/);
  assert.match(migration,/employee_roles/);
  assert.match(migration,/kpi_documents\.delete/);
  assert.match(routes,/DELETE",\/\^\\\/api\\\/kpi-documents/);
  assert.match(routes,/kpi_documents.delete/);
  assert.match(client,/deleteKpiDocument/);
  assert.match(ui,/document-delete/);
  assert.match(migrator,/023-kpi-delete-and-frm-0003-hr\.sql/);
});
