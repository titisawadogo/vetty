import {createHash} from "node:crypto";

import {initializeApp} from "firebase-admin/app";
import {getFirestore, Timestamp} from "firebase-admin/firestore";
import * as logger from "firebase-functions/logger";
import {defineSecret} from "firebase-functions/params";
import {HttpsError, onCall} from "firebase-functions/v2/https";

initializeApp();

const db = getFirestore();
const geminiApiKey = defineSecret("GEMINI_API_KEY");

const MODEL = "gemini-3.1-flash-lite";
const USER_DAILY_LIMIT = 100;
const IP_FIVE_MINUTE_LIMIT = 100;
const DAY_IN_MS = 24 * 60 * 60 * 1000;
const FIVE_MINUTES_IN_MS = 5 * 60 * 1000;

interface GeminiResponse {
  candidates?: Array<{
    content?: {
      parts?: Array<{text?: string}>;
    };
  }>;
}

interface AiNotes {
  summary: string;
  advice: string;
}

export const generateConsultationNotes = onCall(
  {
    enforceAppCheck: true,
    secrets: [geminiApiKey],
  },
  async (request): Promise<AiNotes> => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Please sign in first.");
    }

    const consultationId = request.data?.consultationId;
    if (typeof consultationId !== "string" || consultationId.trim() === "") {
      throw new HttpsError(
        "invalid-argument",
        "A consultation ID is required."
      );
    }

    const userId = request.auth.uid;
    const consultationRef = db
      .collection("users")
      .doc(userId)
      .collection("consultations")
      .doc(consultationId);
    const consultationSnapshot = await consultationRef.get();

    if (!consultationSnapshot.exists) {
      throw new HttpsError("not-found", "Consultation not found.");
    }

    const consultation = consultationSnapshot.data() ?? {};
    if (consultation.userId !== userId) {
      throw new HttpsError(
        "permission-denied",
        "You cannot access this consultation."
      );
    }

    await checkRateLimits(userId, getClientIp(request.rawRequest));
    await consultationRef.update({aiStatus: "processing"});
    logger.info("🟡 AI note generation started", {consultationId});

    try {
      const aiNotes = await generateAiNotes({
        petName: readString(consultation.petName),
        species: readString(consultation.species),
        age: readString(consultation.age),
        details: readString(consultation.details),
      });

      await consultationRef.update({
        aiStatus: "completed",
        aiNotes,
      });
      logger.info("✅ AI notes generated successfully", {consultationId});

      return aiNotes;
    } catch {
      await consultationRef.update({aiStatus: "failed"});
      logger.error("❌ AI note generation failed", {consultationId});
      throw new HttpsError(
        "internal",
        "AI notes could not be generated. Please try again."
      );
    }
  }
);

/**
 * Applies the per-user and per-IP request limits.
 * @param {string} userId Firebase user ID.
 * @param {string} clientIp Caller IP address.
 */
async function checkRateLimits(userId: string, clientIp: string) {
  const now = Date.now();
  const dayStart = Math.floor(now / DAY_IN_MS) * DAY_IN_MS;
  const ipWindowStart =
    Math.floor(now / FIVE_MINUTES_IN_MS) * FIVE_MINUTES_IN_MS;
  const ipHash = createHash("sha256").update(clientIp).digest("hex");

  const userLimitRef = db.collection("aiRateLimits").doc(`user_${userId}`);
  const ipLimitRef = db.collection("aiRateLimits").doc(`ip_${ipHash}`);

  await db.runTransaction(async (transaction) => {
    const userLimitSnapshot = await transaction.get(userLimitRef);
    const ipLimitSnapshot = await transaction.get(ipLimitRef);

    const userCount = getCurrentCount(userLimitSnapshot.data(), dayStart);
    const ipCount = getCurrentCount(ipLimitSnapshot.data(), ipWindowStart);

    if (userCount >= USER_DAILY_LIMIT) {
      logger.warn("🚫 AI request blocked by daily user limit");
      throw new HttpsError(
        "resource-exhausted",
        "Your daily AI limit has been reached."
      );
    }

    if (ipCount >= IP_FIVE_MINUTE_LIMIT) {
      logger.warn("🚫 AI request blocked by IP rate limit");
      throw new HttpsError(
        "resource-exhausted",
        "Too many requests. Please try again in a few minutes."
      );
    }

    transaction.set(userLimitRef, {
      count: userCount + 1,
      windowStart: dayStart,
      expiresAt: Timestamp.fromMillis(dayStart + DAY_IN_MS),
    });
    transaction.set(ipLimitRef, {
      count: ipCount + 1,
      windowStart: ipWindowStart,
      expiresAt: Timestamp.fromMillis(ipWindowStart + FIVE_MINUTES_IN_MS),
    });
  });
}

/**
 * Returns the count for the active rate-limit window.
 * @param {FirebaseFirestore.DocumentData|undefined} data Counter data.
 * @param {number} windowStart Active window start time.
 * @return {number} Current request count.
 */
function getCurrentCount(
  data: FirebaseFirestore.DocumentData | undefined,
  windowStart: number
): number {
  if (data?.windowStart !== windowStart) {
    return 0;
  }

  return typeof data.count === "number" ? data.count : 0;
}

/**
 * Reads the caller IP supplied by Google Cloud's proxy.
 * @param {object} rawRequest Callable function HTTP request.
 * @return {string} Caller IP address.
 */
function getClientIp(
  rawRequest: {headers: Record<string, unknown>; ip?: string}
) {
  const forwardedFor = rawRequest.headers["x-forwarded-for"];

  if (typeof forwardedFor === "string") {
    return forwardedFor.split(",")[0].trim();
  }

  if (Array.isArray(forwardedFor) && typeof forwardedFor[0] === "string") {
    return forwardedFor[0].split(",")[0].trim();
  }

  return rawRequest.ip ?? "unknown";
}

/**
 * Builds the fixed veterinary prompt from a consultation.
 * @param {object} consultation Consultation fields.
 * @return {string} Gemini prompt.
 */
function getPrompt(consultation: {
  petName: string;
  species: string;
  age: string;
  details: string;
}) {
  return `
You assist veterinary professionals with consultation notes.

Create a concise summary and cautious advice using only the information below.
Do not invent symptoms, test results, diagnoses, or medication instructions.
Clearly state when important information is missing.
The advice is a draft for veterinary review, not a final diagnosis.

Pet name: ${consultation.petName}
Species: ${consultation.species}
Age: ${consultation.age}
Consultation details: ${consultation.details}
`;
}

/**
 * Calls Gemini and validates its structured response.
 * @param {object} consultation Consultation fields.
 */
async function generateAiNotes(consultation: {
  petName: string;
  species: string;
  age: string;
  details: string;
}): Promise<AiNotes> {
  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-goog-api-key": geminiApiKey.value(),
      },
      body: JSON.stringify({
        contents: [
          {
            role: "user",
            parts: [{text: getPrompt(consultation)}],
          },
        ],
        generationConfig: {
          temperature: 0.2,
          maxOutputTokens: 800,
          responseMimeType: "application/json",
          responseJsonSchema: {
            type: "object",
            properties: {
              summary: {type: "string"},
              advice: {type: "string"},
            },
            required: ["summary", "advice"],
            additionalProperties: false,
          },
        },
        safetySettings: [
          {
            category: "HARM_CATEGORY_HARASSMENT",
            threshold: "BLOCK_MEDIUM_AND_ABOVE",
          },
          {
            category: "HARM_CATEGORY_HATE_SPEECH",
            threshold: "BLOCK_MEDIUM_AND_ABOVE",
          },
          {
            category: "HARM_CATEGORY_SEXUALLY_EXPLICIT",
            threshold: "BLOCK_MEDIUM_AND_ABOVE",
          },
          {
            category: "HARM_CATEGORY_DANGEROUS_CONTENT",
            threshold: "BLOCK_MEDIUM_AND_ABOVE",
          },
        ],
      }),
    }
  );

  if (!response.ok) {
    throw new Error(`Gemini returned HTTP ${response.status}.`);
  }

  const responseBody = (await response.json()) as GeminiResponse;
  const responseText = responseBody.candidates?.[0]?.content?.parts
    ?.map((part) => part.text ?? "")
    .join("");

  if (!responseText) {
    throw new Error("Gemini returned no notes.");
  }

  const parsed = JSON.parse(responseText) as Partial<AiNotes>;
  if (typeof parsed.summary !== "string" || typeof parsed.advice !== "string") {
    throw new Error("Gemini returned an invalid response.");
  }

  return {
    summary: parsed.summary.trim(),
    advice: parsed.advice.trim(),
  };
}

/**
 * Converts an unknown Firestore field to a safe string.
 * @param {*} value Firestore value.
 * @return {string} String value or an empty string.
 */
function readString(value: unknown): string {
  return typeof value === "string" ? value : "";
}
