import assert from "node:assert/strict";
import test from "node:test";

// Mirror critical portable domain rules at the public boundary.
function extendDeadline(current, proposed) {
  const difference = proposed - current;
  if (difference <= 0) throw new Error("forward");
  if (difference > 259200000) throw new Error("three days");
}
function failOverdue(deadline, submission, now) { return !submission && now > deadline ? { status: "failed", score: 0 } : null; }

test("task deadline extension permits no more than three days", () => {
  const deadline = new Date("2026-08-12T12:00:00Z");
  assert.doesNotThrow(() => extendDeadline(deadline, new Date("2026-08-15T12:00:00Z")));
  assert.throws(() => extendDeadline(deadline, new Date("2026-08-15T12:00:01Z")), /three days/);
});

test("unsubmitted overdue task fails with zero", () => {
  const result = failOverdue(new Date("2026-08-12T12:00:00Z"), null, new Date("2026-08-12T12:00:01Z"));
  assert.deepEqual(result, { status: "failed", score: 0 });
});
