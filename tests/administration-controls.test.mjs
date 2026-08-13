import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { PGlite } from "@electric-sql/pglite";
import { pgcrypto } from "@electric-sql/pglite/contrib/pgcrypto";

test("production administration exposes roles permissions networks and schedules",async()=>{
  const [routes,client,app,migrator]=await Promise.all([
    readFile(new URL("../server/admin-routes.mjs",import.meta.url),"utf8"),
    readFile(new URL("../app/api-client.ts",import.meta.url),"utf8"),
    readFile(new URL("../app/frame-app.tsx",import.meta.url),"utf8"),
    readFile(new URL("../server/migrate.mjs",import.meta.url),"utf8"),
  ]);
  for(const endpoint of ["permissions","attendance-networks","attendance-schedules"])assert.match(routes,new RegExp(endpoint));
  for(const control of ["attendanceNetworks","attendanceSchedules","assignRole","createRole"])assert.match(client,new RegExp(control));
  for(const title of ["Authorize office network","Create attendance schedule","Assign role to employee"])assert.match(app,new RegExp(title));
  assert.match(migrator,/006-administration-controls\.sql/);
});

test("administration migration grants attendance configuration to Super Admin",async()=>{
  const db=new PGlite({extensions:{pgcrypto}});
  for(const name of ["schema.sql","modules.sql","remaining-modules.sql","guards.sql","005-production-completion.sql","006-administration-controls.sql"])await db.exec(await readFile(new URL(`../database/${name}`,import.meta.url),"utf8"));
  const permission=await db.query("SELECT permission_key FROM permissions WHERE permission_key='attendance.configure'");
  assert.equal(permission.rows.length,1);
  await db.close();
});
