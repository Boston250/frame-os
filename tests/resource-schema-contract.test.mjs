import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

test("generic resource definitions reference real tables and columns",async()=>{const [routes,...sqlParts]=await Promise.all([readFile(new URL("../server/resource-routes.mjs",import.meta.url),"utf8"),...['schema.sql','modules.sql','remaining-modules.sql'].map(name=>readFile(new URL(`../database/${name}`,import.meta.url),"utf8"))]);const sql=sqlParts.join("\n");const tablePattern=/(\w+):\{table:"([^"]+)"[^}]*columns:\[([^\]]+)\]/g;for(const match of routes.matchAll(tablePattern)){const [,key,table,columnsText]=match;const tableBlock=sql.match(new RegExp(`CREATE TABLE ${table} \\(([\\s\\S]*?)\\n\\);`));assert.ok(tableBlock,`${key} uses missing table ${table}`);const columns=[...columnsText.matchAll(/"([^"]+)"/g)].map(item=>item[1]);for(const column of columns)assert.match(tableBlock[1],new RegExp(`\\b${column}\\b`),`${key}.${column} is absent from ${table}`);}});
