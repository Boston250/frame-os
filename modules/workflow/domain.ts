export type ApprovalDecision = "approve" | "reject" | "return";
export type ApprovalState = "draft" | "pending" | "approved" | "rejected" | "returned" | "cancelled";

export interface ApprovalStep { position: number; authority: string; status: "waiting" | "pending" | "approved" | "rejected" | "returned"; }
export interface ApprovalRequest { state: ApprovalState; currentStep: number; steps: ApprovalStep[]; }

export function decideApproval(request: ApprovalRequest, actorAuthority: string, decision: ApprovalDecision): ApprovalRequest {
  if (request.state !== "pending") throw new Error("Only pending approvals can be decided");
  const step = request.steps.find(item => item.position === request.currentStep);
  if (!step || step.status !== "pending") throw new Error("Current approval step is invalid");
  if (step.authority !== actorAuthority) throw new Error("Actor is not the current approval authority");
  const steps = request.steps.map(item => item.position === step.position ? { ...item, status: decision === "approve" ? "approved" as const : decision === "reject" ? "rejected" as const : "returned" as const } : item);
  if (decision === "reject") return { ...request, state: "rejected", steps };
  if (decision === "return") return { ...request, state: "returned", steps };
  const next = steps.find(item => item.position > step.position && item.status === "waiting");
  if (!next) return { ...request, state: "approved", steps };
  return { ...request, currentStep: next.position, steps: steps.map(item => item.position === next.position ? { ...item, status: "pending" as const } : item) };
}

export function extendDeadline(current: Date, proposed: Date): void {
  const difference = proposed.getTime() - current.getTime();
  if (difference <= 0) throw new Error("Deadline extension must move forward");
  if (difference > 3 * 24 * 60 * 60 * 1000) throw new Error("Deadline extension cannot exceed three days");
}

export function failOverdueTask(deadline: Date, submittedAt: Date | null, now: Date) {
  return !submittedAt && now.getTime() > deadline.getTime() ? { status: "failed" as const, managerScore: 0, failedAt: now } : null;
}
