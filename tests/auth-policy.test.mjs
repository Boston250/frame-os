import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
test("temporary password expiry and mandatory change are server-enforced",async()=>{const [api,http]=await Promise.all([readFile(new URL("../server/index.mjs",import.meta.url),"utf8"),readFile(new URL("../server/http.mjs",import.meta.url),"utf8")]);assert.match(api,/temporaryExpired/);assert.match(api,/Temporary password expired/);assert.match(http,/Password change required/);assert.match(http,/allowPasswordChange/);});
