import assert from "node:assert/strict";
import {readFile} from "node:fs/promises";
import test from "node:test";

test("asset value is visible in lists details forms and exports",async()=>{
  const [api,ui,worker,migration,migrator]=await Promise.all([
    readFile(new URL("../server/extended-routes.mjs",import.meta.url),"utf8"),
    readFile(new URL("../app/frame-app.tsx",import.meta.url),"utf8"),
    readFile(new URL("../worker/jobs.mjs",import.meta.url),"utf8"),
    readFile(new URL("../database/017-asset-value-visibility.sql",import.meta.url),"utf8"),
    readFile(new URL("../server/migrate.mjs",import.meta.url),"utf8"),
  ]);
  assert.match(api,/a\.value/);
  assert.match(api,/COALESCE\(a\.currency,'RWF'\)/);
  assert.match(api,/Asset value must be a valid non-negative amount/);
  assert.match(api,/purchased_on/);
  assert.match(ui,/Asset value \(RWF\)/);
  assert.match(ui,/toLocaleString\("en-RW"\)/);
  assert.match(ui,/Purchased on/);
  assert.match(worker,/asset_number,name,category,value/);
  assert.match(migration,/assets_value_non_negative/);
  assert.match(migrator,/017-asset-value-visibility\.sql/);
});
