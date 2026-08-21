import test from "node:test";
import assert from "node:assert/strict";
import {readFile} from "node:fs/promises";

test("KPI creation is restricted to non-HR managers and Super Admin",async()=>{
  const [http,index,migration,migrator,css]=await Promise.all([
    readFile(new URL("../server/http.mjs",import.meta.url),"utf8"),
    readFile(new URL("../server/index.mjs",import.meta.url),"utf8"),
    readFile(new URL("../database/019-manager-only-kpi-creation.sql",import.meta.url),"utf8"),
    readFile(new URL("../server/migrate.mjs",import.meta.url),"utf8"),
    readFile(new URL("../app/globals.css",import.meta.url),"utf8"),
  ]);
  assert.match(http,/key==="kpi\.create"&&!await isKpiManager/);
  assert.match(http,/r\.name='Super Admin'/);
  assert.match(http,/lower\(r\.name\) LIKE '%manager%'/);
  assert.match(http,/lower\(r\.name\) NOT LIKE '%hr%'/);
  assert.match(index,/key!=="kpi\.create"\|\|eligible/);
  assert.match(migration,/p\.permission_key='kpi\.create'/);
  assert.match(migration,/hr manager/);
  assert.match(migrator,/019-manager-only-kpi-creation\.sql/);
  assert.match(css,/\.kpi-items-head>button\{order:3/);
  assert.match(css,/\.kpi-row:not\(\.kpi-row-heading\)\{order:2/);
});
