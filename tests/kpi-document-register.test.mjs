import assert from "node:assert/strict";
import test from "node:test";
import { readFile } from "node:fs/promises";

const root=new URL("../",import.meta.url);
const read=path=>readFile(new URL(path,root),"utf8");

test("KPI document register has restricted PDF upload, viewing, and download support",async()=>{
  const [migration,limitMigration,routes,client,ui]=await Promise.all([read("database/020-kpi-document-register.sql"),read("database/021-kpi-document-max-3mb.sql"),read("server/kpi-document-routes.mjs"),read("app/api-client.ts"),read("app/frame-app.tsx")]);
  assert.match(migration,/CREATE TABLE IF NOT EXISTS kpi_documents/);
  assert.match(migration,/3145728/);
  assert.match(limitMigration,/3145728/);
  assert.match(migration,/'kpi_documents\.view'/);
  assert.match(migration,/'kpi_documents\.upload'/);
  assert.match(migration,/general manager/i);
  assert.match(routes,/maximumPdfBytes=3\*1024\*1024/);
  assert.match(routes,/%PDF-/);
  assert.match(routes,/\(view\|download\)/);
  assert.match(client,/kpiDocuments/);
  assert.match(client,/uploadKpiDocument/);
  assert.match(ui,/function KpiDocumentsPage/);
  assert.match(ui,/Upload KPI PDF/);
  assert.match(ui,/kpi_documents\.view/);
});
