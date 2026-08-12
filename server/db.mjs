import pg from "pg";

const { Pool } = pg;
export const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: Number(process.env.DATABASE_POOL_SIZE ?? 10),
  idleTimeoutMillis: 30_000,
  connectionTimeoutMillis: 5_000,
  ssl: process.env.DATABASE_SSL === "true" ? { rejectUnauthorized: true } : false,
});

export async function transaction(work) {
  const client = await pool.connect();
  try { await client.query("BEGIN"); const result = await work(client); await client.query("COMMIT"); return result; }
  catch (error) { await client.query("ROLLBACK"); throw error; }
  finally { client.release(); }
}

export async function audit(client, { companyId, actorId, action, module, entityType, entityId, before=null, after=null, requestId, ip, userAgent }) {
  await client.query(`INSERT INTO audit_events(company_id,actor_employee_id,action,module,entity_type,entity_id,before_data,after_data,request_id,ip_address,user_agent)
    VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)`, [companyId,actorId,action,module,entityType,String(entityId),before,after,requestId,ip||null,userAgent||null]);
}
