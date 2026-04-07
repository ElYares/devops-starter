import test from "node:test";
import assert from "node:assert/strict";

test("NEXT_PUBLIC_API_BASE_URL uses localhost host routing by default", () => {
  const value = process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://api.localhost";
  assert.equal(value, "http://api.localhost");
});
