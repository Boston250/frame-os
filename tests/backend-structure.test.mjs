import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

test("production API protects foundation resources",async()=>{const api=await readFile(new URL("../server/index.mjs",import.meta.url),"utf8");const normalized=api.replaceAll("\\","");for(const route of ["/api/auth/login","/api/auth/logout","/api/me","/api/departments","/api/employees","/api/approvals"])assert.ok(normalized.includes(route));for(const control of ["requireSession","requirePermission","audit","transaction"])assert.match(api,new RegExp(control));assert.match(api,/greatest\(next_value,/);assert.match(api,/max\(substring\(employee_number/);});
test("deployment separates web API worker and data services",async()=>{const compose=await readFile(new URL("../deploy/docker-compose.yml",import.meta.url),"utf8");for(const service of ["app:","api:","worker:","postgres:","redis:","nginx:"])assert.match(compose,new RegExp(`\\n  ${service}`));});
