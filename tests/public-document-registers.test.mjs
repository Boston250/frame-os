import assert from "node:assert/strict";
import test from "node:test";
import { readFile } from "node:fs/promises";

test("all signed-in employees can use KPI and employee contract registers",async()=>{const [api,kpi,contracts,ui]=await Promise.all([readFile(new URL("../server/index.mjs",import.meta.url),"utf8"),readFile(new URL("../server/kpi-document-routes.mjs",import.meta.url),"utf8"),readFile(new URL("../server/employee-contract-routes.mjs",import.meta.url),"utf8"),readFile(new URL("../app/frame-app.tsx",import.meta.url),"utf8")]);assert.match(api,/publicDocumentPermissions/);for(const key of ["kpi_documents.view","kpi_documents.upload","employee_contracts.view","employee_contracts.upload"])assert.match(api,new RegExp(key.replace(".","\\.")));assert.match(kpi,/async function requireAudience\(\)\{\}/);assert.match(contracts,/async function requireAudience\(\)\{\}/);assert.match(ui,/every signed-in employee/);});
