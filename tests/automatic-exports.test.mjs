import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";

test("Excel and PDF buttons wait for completion and automatically download",async()=>{
  const [app,client,worker]=await Promise.all([
    readFile(new URL("../app/frame-app.tsx",import.meta.url),"utf8"),
    readFile(new URL("../app/api-client.ts",import.meta.url),"utf8"),
    readFile(new URL("../worker/jobs.mjs",import.meta.url),"utf8"),
  ]);
  assert.match(app,/createAndDownloadReport/);
  assert.match(app,/exportRows\("xlsx"\)/);
  assert.match(app,/exportRows\("pdf"\)/);
  assert.match(app,/link\.click\(\)/);
  assert.match(client,/exportStatus/);
  assert.match(client,/exportDownloadUrl/);
  assert.match(worker,/generatePdf/);
  assert.match(worker,/generateXlsx/);
});
