const assert = require("node:assert/strict");
const test = require("node:test");

const {
  isRateLimitReached,
  parseAiNotes,
} = require("../lib/helpers.js");

test("parses a valid Gemini response", () => {
  const notes = parseAiNotes(
    JSON.stringify({summary: " Healthy pet ", advice: " Monitor appetite "})
  );

  assert.deepEqual(notes, {
    summary: "Healthy pet",
    advice: "Monitor appetite",
  });
});

test("rejects an invalid Gemini response", () => {
  assert.throws(
    () => parseAiNotes(JSON.stringify({summary: "Missing advice"})),
    /invalid response/
  );
});

test("blocks request 101", () => {
  assert.equal(isRateLimitReached(99, 100), false);
  assert.equal(isRateLimitReached(100, 100), true);
});
