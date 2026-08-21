import { readFile } from "node:fs/promises";
import pg from "pg";

const { Pool } = pg;
const pool = new Pool({
  connectionString: process.env.DATABASE_MIGRATION_URL ?? process.env.DATABASE_URL,
  max: 1,
  ssl: process.env.DATABASE_SSL === "true" ? { rejectUnauthorized: true } : false,
});

const files=["schema.sql","modules.sql","remaining-modules.sql","guards.sql","005-production-completion.sql","006-administration-controls.sql","007-salesperson-role.sql","008-employee-read-only-tasks.sql","009-employee-onboarding.sql","010-remove-employee-contract.sql","011-hr-employee-management.sql","012-hr-roles-and-exports.sql","013-leave-management.sql","014-hr-finance-access.sql","015-employee-lifecycle-controls.sql","016-deleted-employee-privacy.sql","017-asset-value-visibility.sql","018-kpi-project-plans.sql","019-manager-only-kpi-creation.sql"];
await pool.query("CREATE TABLE IF NOT EXISTS schema_migrations (name text PRIMARY KEY, applied_at timestamptz NOT NULL DEFAULT now())");
for(const name of files){const exists=await pool.query("SELECT 1 FROM schema_migrations WHERE name=$1",[name]);if(exists.rowCount)continue;const sql=await readFile(new URL(`../database/${name}`,import.meta.url),"utf8");const client=await pool.connect();try{await client.query("BEGIN");await client.query(sql);await client.query("INSERT INTO schema_migrations(name) VALUES($1)",[name]);await client.query("COMMIT");console.log(`Applied ${name}`);}catch(error){await client.query("ROLLBACK");throw error;}finally{client.release();}}
await pool.end();
