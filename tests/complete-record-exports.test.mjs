import assert from "node:assert/strict";
import {readFile} from "node:fs/promises";
import test from "node:test";

test("single-record Excel and PDF exports contain the same complete module record",async()=>{
  const [ui,core,extended]=await Promise.all([
    readFile(new URL("../app/frame-app.tsx",import.meta.url),"utf8"),
    readFile(new URL("../server/index.mjs",import.meta.url),"utf8"),
    readFile(new URL("../server/extended-routes.mjs",import.meta.url),"utf8"),
  ]);
  assert.match(ui,/const reportKeys:Record<ModuleKey,string>/);
  assert.match(ui,/reportKey=\{reportKeys\[active\]\}/);
  assert.match(ui,/createAndDownloadReport\(reportKey,"xlsx",flash,exportFilters\)/);
  assert.match(ui,/createAndDownloadReport\(reportKey,"pdf",flash,exportFilters\)/);
  assert.match(ui,/useServerRecord=\{active==="hr"&&tab===0\}/);
  for(const field of ["Phone","Email","Lead source","Direct manager","Manager score","Salesperson","Payment terms","Purchased on"])assert.match(ui,new RegExp(field));
  for(const column of ["c.address","c.industry","c.contact_name","t.description","t.manager_note"])assert.match(core,new RegExp(column.replace(".","\\.")));
  for(const column of ["ct.payment_terms","ct.reporting_frequency","ct.document_reference","ct.revision"])assert.match(extended,new RegExp(column.replace(".","\\.")));
});
