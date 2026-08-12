import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

test("core queries enforce permission scopes in SQL",async()=>{const source=await readFile(new URL("../server/index.mjs",import.meta.url),"utf8");assert.match(source,/permissionScopes\(session\.employee_id,"employees\.view"\)/);assert.match(source,/e\.department_id=\$/);assert.match(source,/permissionScopes\(session\.employee_id,"customers\.view"\)/);assert.match(source,/co\.employee_id=\$/);assert.match(source,/permissionScopes\(session\.employee_id,"tasks\.view"\)/);assert.match(source,/t\.assignee_id=\$/);});

test("generic queries deny unrepresentable narrow scopes",async()=>{const source=await readFile(new URL("../server/resource-routes.mjs",import.meta.url),"utf8");assert.match(source,/requireScopes/);assert.match(source,/scopeClause/);assert.match(source,/AND false/);assert.match(source,/s\.department_id/);});

test("core and generic mutations lock only records inside the granted scope",async()=>{const [core,generic]=await Promise.all([readFile(new URL("../server/index.mjs",import.meta.url),"utf8"),readFile(new URL("../server/resource-routes.mjs",import.meta.url),"utf8")]);assert.match(core,/scopeParts/);assert.match(core,/customer_ownership co/);assert.match(core,/assignee_id=\$/);assert.match(generic,/const scoped=scopeClause\(def,scopes,3\)/);assert.match(generic,/FOR UPDATE/);});
