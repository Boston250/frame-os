import assert from "node:assert/strict";
import {readFile} from "node:fs/promises";
import test from "node:test";

test("production UI uses current dates routes and live module totals",async()=>{
  const ui=await readFile(new URL("../app/frame-app.tsx",import.meta.url),"utf8");
  assert.match(ui,/Intl\.DateTimeFormat\("en-RW"/);
  assert.match(ui,/window\.location\.hash\.slice\(1\)/);
  assert.match(ui,/Total records<\/small><strong>\{rows\.length\}/);
  assert.doesNotMatch(ui,/Tuesday, 12 August/);
  assert.doesNotMatch(ui,/data\.rows\.length \* 14/);
  assert.match(ui,/report\|expense\|invoice\|budget\|accounting\|commission/);
});
