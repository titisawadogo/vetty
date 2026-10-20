export interface AiNotes {
  summary: string;
  advice: string;
}

interface CounterData {
  count?: unknown;
  windowStart?: unknown;
}

/**
 * Returns the count for the active rate-limit window.
 * @param {CounterData|undefined} data Counter data.
 * @param {number} windowStart Active window start time.
 * @return {number} Current request count.
 */
export function getCurrentCount(
  data: CounterData | undefined,
  windowStart: number
): number {
  if (data?.windowStart !== windowStart) {
    return 0;
  }

  return typeof data.count === "number" ? data.count : 0;
}

/**
 * Checks whether another request must be blocked.
 * @param {number} count Current request count.
 * @param {number} limit Maximum allowed request count.
 * @return {boolean} Whether the limit has been reached.
 */
export function isRateLimitReached(count: number, limit: number): boolean {
  return count >= limit;
}

/**
 * Validates and converts Gemini JSON into AI notes.
 * @param {string} responseText Gemini JSON response.
 * @return {AiNotes} Validated AI notes.
 */
export function parseAiNotes(responseText: string): AiNotes {
  const parsed = JSON.parse(responseText) as Partial<AiNotes>;

  if (typeof parsed.summary !== "string" || typeof parsed.advice !== "string") {
    throw new Error("Gemini returned an invalid response.");
  }

  return {
    summary: parsed.summary.trim(),
    advice: parsed.advice.trim(),
  };
}
