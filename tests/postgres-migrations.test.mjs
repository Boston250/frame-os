import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import { PGlite } from "@electric-sql/pglite";
import { pgcrypto } from "@electric-sql/pglite/contrib/pgcrypto";

test("all FRAME OS migrations execute on PostgreSQL",{timeout:120000},async()=>{const db=new PGlite({extensions:{pgcrypto}});for(const name of ["schema.sql","modules.sql","remaining-modules.sql","guards.sql","005-production-completion.sql"]){const sql=await readFile(new URL(`../database/${name}`,import.meta.url),"utf8");await db.exec(sql);}const tables=await db.query("SELECT count(*)::int count FROM information_schema.tables WHERE table_schema='public'");assert.ok(tables.rows[0].count>=50);const triggers=await db.query("SELECT count(*)::int count FROM information_schema.triggers WHERE trigger_schema='public'");assert.ok(triggers.rows[0].count>=10);await db.close();});
