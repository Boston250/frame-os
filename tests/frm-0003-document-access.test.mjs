import assert from "node:assert/strict";
import test from "node:test";
import { readFile } from "node:fs/promises";

test("FRM-0003 receives document permissions even when its HR role was created later",async()=>{const [migration,migrator]=await Promise.all([readFile(new URL("../database/024-grant-frm-0003-document-access.sql",import.meta.url),"utf8"),readFile(new URL("../server/migrate.mjs",import.meta.url),"utf8")]);for(const key of ["FRM-0003","kpi_documents.view","kpi_documents.upload","employee_contracts.view","employee_contracts.upload"])assert.match(migration,new RegExp(key.replace(".","\\.")));assert.match(migrator,/024-grant-frm-0003-document-access\.sql/);});
