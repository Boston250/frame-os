import test from "node:test";
import assert from "node:assert/strict";
import { hashPassword, verifyPassword } from "../server/security.mjs";

test("hashes and verifies production-strength passwords",async()=>{
  const password="FrameOS-test-password-2026";
  const encoded=await hashPassword(password);
  assert.match(encoded,/^scrypt\$32768\$8\$1\$/);
  assert.equal(await verifyPassword(password,encoded),true);
  assert.equal(await verifyPassword("wrong-password-value",encoded),false);
});
