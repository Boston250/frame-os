import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";

test("production login has no demo password and API applies security controls",async()=>{
  const [app,http,server]=await Promise.all([
    readFile(new URL("../app/frame-app.tsx",import.meta.url),"utf8"),
    readFile(new URL("../server/http.mjs",import.meta.url),"utf8"),
    readFile(new URL("../server/index.mjs",import.meta.url),"utf8"),
  ]);
  assert.doesNotMatch(app,/useState\("frame-demo"\)/);
  for(const header of ["content-security-policy","x-content-type-options","x-frame-options","referrer-policy","permissions-policy"])assert.match(http,new RegExp(header));
  assert.match(server,/Too many sign-in attempts/);
  assert.match(server,/loginWindowMs=15\*60\*1000/);
  assert.match(server,/url\.pathname==="\/api\/auth\/login"/);
});
