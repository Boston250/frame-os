export interface EmailMessage { to: string; subject: string; html: string; attachmentReferences?: string[]; }
export interface WhatsAppMessage { to: string; template: string; variables: Record<string,string>; }
export interface DeliveryReceipt { providerReference: string; acceptedAt: Date; }
export interface EmailGateway { send(message: EmailMessage): Promise<DeliveryReceipt>; }
export interface WhatsAppGateway { send(message: WhatsAppMessage): Promise<DeliveryReceipt>; }
export interface ExportGenerator { pdf(reportKey: string, input: unknown): Promise<string>; xlsx(reportKey: string, input: unknown): Promise<string>; }
export const importantWhatsAppEvents = new Set(["task.assigned","approval.required","approval.rejected","task.overdue","leave.decided","payroll.status_changed","client.escalated","subscription.expiring","asset_request.decided"]);
