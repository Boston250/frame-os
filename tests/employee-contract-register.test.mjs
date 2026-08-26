import assert from "node:assert/strict";
import test from "node:test";
import { readFile } from "node:fs/promises";

const root=new URL("../",import.meta.url);
const read=path=>readFile(new URL(path,root),"utf8");

test("employee contract register restricts PDF contracts and records expiry and entry date",async()=>{
  const [migration,routes,client,ui,migrator]=await Promise.all([read("database/022-employee-contract-register.sql"),read("server/employee-contract-routes.mjs"),read("app/api-client.ts"),read("app/frame-app.tsx"),read("server/migrate.mjs")]);
  assert.match(migration,/employee_contract_documents/);
  assert.match(migration,/expires_on date NOT NULL/);
  assert.match(migration,/entered_at timestamptz NOT NULL DEFAULT now\(\)/);
  assert.match(migration,/employee_contracts\.view/);
  assert.match(migration,/employee_contracts\.upload/);
  assert.match(routes,/maximumPdfBytes=3\*1024\*1024/);
  assert.match(routes,/%PDF-/);
  assert.match(routes,/available-employees/);
  assert.match(client,/uploadEmployeeContract/);
  assert.match(ui,/EmployeeContractsPage/);
  assert.match(ui,/EmployeeContractUploadDrawer/);
  assert.match(migrator,/022-employee-contract-register\.sql/);
});
