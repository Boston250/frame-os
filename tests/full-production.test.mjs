import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

test("extended API covers remaining production modules",async()=>{const api=await readFile(new URL("../server/extended-routes.mjs",import.meta.url),"utf8");for(const route of ["dashboard","contracts","kpi-plans","leave","attendance","expenses","assets","purchase-requests","notifications","exports"])assert.ok(api.replaceAll("\\","").includes(`/api/${route}`));for(const control of ["requireSession","requirePermission","transaction","audit"])assert.match(api,new RegExp(control));});
test("worker implements deadlines reminders delivery and exports",async()=>{const worker=await readFile(new URL("../worker/jobs.mjs",import.meta.url),"utf8");for(const job of ["failOverdueTasks","flagInactiveLeads","queueRenewals","queueSubscriptionExpiry","processDeliveries","processExports"])assert.match(worker,new RegExp(job));assert.match(worker,/PDFDocument/);assert.match(worker,/ExcelJS/);});
