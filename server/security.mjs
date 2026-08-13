import { createHash, randomBytes, scrypt as scryptCallback, timingSafeEqual } from "node:crypto";
import { promisify } from "node:util";
const scrypt = promisify(scryptCallback);
const scryptOptions={N:32768,r:8,p:1,maxmem:64*1024*1024};

export async function hashPassword(password) {
  if (password.length < 12) throw Object.assign(new Error("Password must contain at least 12 characters"),{status:400});
  const salt=randomBytes(16); const derived=await scrypt(password,salt,64,scryptOptions);
  return `scrypt$32768$8$1$${salt.toString("base64")}$${Buffer.from(derived).toString("base64")}`;
}
export async function verifyPassword(password, encoded) {
  const [kind,n,r,p,salt,digest]=encoded.split("$"); if(kind!=="scrypt") return false;
  const derived=await scrypt(password,Buffer.from(salt,"base64"),64,{N:Number(n),r:Number(r),p:Number(p),maxmem:64*1024*1024});
  return timingSafeEqual(Buffer.from(digest,"base64"),Buffer.from(derived));
}
export function newSessionToken(){return randomBytes(32).toString("base64url")}
export function tokenHash(token){return createHash("sha256").update(token).digest()}
export function temporaryPassword(){return `${randomBytes(8).toString("base64url")}!9aF`}
export function sessionCookie(token,maxAge=3600){return `__Host-frame_session=${token}; Path=/; HttpOnly; Secure; SameSite=Lax; Max-Age=${maxAge}`}
export function clearSessionCookie(){return "__Host-frame_session=; Path=/; HttpOnly; Secure; SameSite=Lax; Max-Age=0"}
