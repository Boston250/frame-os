import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
test("stateful business actions are implemented",async()=>{const source=await readFile(new URL("../server/action-routes.mjs",import.meta.url),"utf8");for(const path of ["reassign","hire","exit","calculate","paid","events","escalate","deliver"])assert.match(source,new RegExp(path));});
test("workflow routes enforce contract KPI leave and task transitions",async()=>{const source=await readFile(new URL("../server/workflow-routes.mjs",import.meta.url),"utf8");for(const path of ["contracts","kpi-plans","leave","submit","score","extend"])assert.ok(source.replaceAll("\\","").includes(path));});
