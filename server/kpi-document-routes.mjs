import { randomUUID } from "node:crypto";
import { createReadStream } from "node:fs";
import { mkdir, stat, unlink, writeFile } from "node:fs/promises";
import path from "node:path";
import { audit, pool, transaction } from "./db.mjs";
import { jsonBody, requestContext, requirePermission, requireSession, send } from "./http.mjs";

const maximumPdfBytes=3*1024*1024;
const maximumRequestBytes=21*1024*1024;
const permittedRoleSql=`(r.name='Super Admin' OR lower(r.name)='general manager' OR lower(r.name) IN ('hr','hr manager','human resources','people & hr'))`;

function documentDirectory(){return process.env.KPI_DOCUMENT_DIRECTORY||"/var/lib/frame/kpi-documents";}
function safeFileName(value){return path.basename(String(value||"kpi-document.pdf")).replace(/[^a-zA-Z0-9._-]/g,"_").replace(/^\.+/,"")||"kpi-document.pdf";}
function audienceError(){return Object.assign(new Error("KPI documents are limited to General Manager, HR, and Super Admin"),{status:403});}
async function requireAudience(session,permission){
  await requirePermission(session.employee_id,permission,["company"]);
  const {rowCount}=await pool.query(`SELECT 1 FROM employee_roles er JOIN roles r ON r.id=er.role_id WHERE er.employee_id=$1 AND er.valid_from<=now() AND (er.valid_until IS NULL OR er.valid_until>now()) AND ${permittedRoleSql} LIMIT 1`,[session.employee_id]);
  if(!rowCount)throw audienceError();
}
function sendPdf(res,file,disposition){
  res.writeHead(200,{"content-type":"application/pdf","content-length":String(file.size),"content-disposition":`${disposition}; filename="${safeFileName(file.original_filename)}"`,"cache-control":"private, no-store","x-content-type-options":"nosniff","x-frame-options":"DENY","referrer-policy":"no-referrer"});
  createReadStream(file.path).on("error",()=>{if(!res.headersSent)send(res,404,{error:"Document file not found"});else res.destroy();}).pipe(res);
}

export function registerKpiDocumentRoutes(route){
  route("GET",/^\/api\/kpi-documents$/,async(req,res)=>{const session=await requireSession(req);await requireAudience(session,"kpi_documents.view");const {rows}=await pool.query(`SELECT d.id,d.title,d.original_filename,d.file_size,d.uploaded_at,concat(e.first_name,' ',e.last_name) uploaded_by FROM kpi_documents d JOIN employees e ON e.id=d.uploaded_by WHERE d.company_id=$1 ORDER BY d.uploaded_at DESC`,[session.company_id]);send(res,200,{data:rows});});
  route("POST",/^\/api\/kpi-documents$/,async(req,res)=>{const session=await requireSession(req);await requireAudience(session,"kpi_documents.upload");const body=await jsonBody(req,maximumRequestBytes);const title=String(body.title??"").trim();const originalFilename=safeFileName(body.fileName);if(!title||title.length>180)throw Object.assign(new Error("Document title must be between 1 and 180 characters"),{status:400});if(!/\.pdf$/i.test(originalFilename))throw Object.assign(new Error("Upload a PDF file"),{status:400});const encoded=String(body.contentBase64??"").replace(/\s/g,"");if(!encoded||!/^[A-Za-z0-9+/]*={0,2}$/.test(encoded))throw Object.assign(new Error("Invalid PDF upload"),{status:400});const bytes=Buffer.from(encoded,"base64");if(!bytes.length||bytes.length>maximumPdfBytes||bytes.subarray(0,5).toString("ascii")!=="%PDF-")throw Object.assign(new Error("Upload a valid PDF of 3 MB or less"),{status:400});const directory=documentDirectory();await mkdir(directory,{recursive:true});const storedFilename=`${randomUUID()}.pdf`;const storedPath=path.join(directory,storedFilename);await writeFile(storedPath,bytes,{mode:0o640});const context=requestContext(req);try{const document=await transaction(async client=>{const {rows}=await client.query(`INSERT INTO kpi_documents(company_id,title,original_filename,stored_filename,mime_type,file_size,uploaded_by) VALUES($1,$2,$3,$4,'application/pdf',$5,$6) RETURNING id,title,original_filename,file_size,uploaded_at`,[session.company_id,title,originalFilename,storedFilename,bytes.length,session.employee_id]);await audit(client,{companyId:session.company_id,actorId:session.employee_id,action:"kpi_documents.upload",module:"performance",entityType:"kpi_document",entityId:rows[0].id,after:{title,originalFilename,fileSize:bytes.length},requestId:context.requestId,ip:context.ip,userAgent:context.userAgent});return rows[0];});send(res,201,{data:document});}catch(error){await unlink(storedPath).catch(()=>{});throw error;}});
  route("GET",/^\/api\/kpi-documents\/([0-9a-f-]+)\/(view|download)$/,async(req,res,match)=>{const session=await requireSession(req);await requireAudience(session,"kpi_documents.view");const {rows}=await pool.query("SELECT original_filename,stored_filename FROM kpi_documents WHERE id=$1 AND company_id=$2",[match[1],session.company_id]);if(!rows[0])throw Object.assign(new Error("KPI document not found"),{status:404});const directory=path.resolve(documentDirectory());const filePath=path.resolve(directory,rows[0].stored_filename);if(!filePath.startsWith(`${directory}${path.sep}`))throw Object.assign(new Error("KPI document not found"),{status:404});let fileStats;try{fileStats=await stat(filePath);}catch{throw Object.assign(new Error("Document file not found"),{status:404});}sendPdf(res,{...rows[0],path:filePath,size:fileStats.size},match[2]==="download"?"attachment":"inline");});
}
