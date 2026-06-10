/**
 * Cloud Functions for the Gold Investment app.
 *
 *  Callables (admin-only):
 *   • approveUser / rejectUser  — verify registrations
 *   • setAdminClaim             — grant/revoke the admin custom claim
 *   • recordPayment             — record an installment (transactional)
 *   • refreshGoldRateNow        — fetch the live rate on demand
 *
 *  Scheduled:
 *   • refreshGoldRate           — pull the spot price every 6 hours
 *   • recomputeDeliveries       — nightly: extend delivery dates for misses
 *
 * Deploying functions requires the Blaze plan. The app also works without them
 * (client-side paths) except for the automatic gold-rate fetch.
 */
import {onCall, HttpsError, CallableRequest} from "firebase-functions/v2/https";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {
  onDocumentCreated,
  onDocumentUpdated,
} from "firebase-functions/v2/firestore";
import {defineSecret} from "firebase-functions/params";
import {logger} from "firebase-functions";
import * as admin from "firebase-admin";

import {computeProgress} from "./delivery";

admin.initializeApp();
const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;
const Timestamp = admin.firestore.Timestamp;

/** External gold-price API key — set with `firebase functions:secrets:set GOLD_API_KEY`. */
const goldApiKey = defineSecret("GOLD_API_KEY");

const GRAMS_PER_TROY_OUNCE = 31.1034768;

// ── Helpers ──────────────────────────────────────────────────────────────────
function assertAdmin(request: CallableRequest): string {
  if (!request.auth || request.auth.token.admin !== true) {
    throw new HttpsError("permission-denied", "Admin privileges are required.");
  }
  return request.auth.uid;
}

function requireString(value: unknown, field: string): string {
  if (typeof value !== "string" || value.length === 0) {
    throw new HttpsError("invalid-argument", `${field} is required.`);
  }
  return value;
}

// ── User verification ─────────────────────────────────────────────────────────
export const approveUser = onCall(async (request) => {
  const adminUid = assertAdmin(request);
  const uid = requireString(request.data?.uid, "uid");
  await db.doc(`users/${uid}`).update({
    status: "approved",
    approvedBy: adminUid,
    approvedAt: FieldValue.serverTimestamp(),
  });
  return {ok: true};
});

export const rejectUser = onCall(async (request) => {
  const adminUid = assertAdmin(request);
  const uid = requireString(request.data?.uid, "uid");
  await db.doc(`users/${uid}`).update({
    status: "rejected",
    approvedBy: adminUid,
    approvedAt: FieldValue.serverTimestamp(),
  });
  return {ok: true};
});

// ── Admin role management ───────────────────────────────────────────────────────
export const setAdminClaim = onCall(async (request) => {
  assertAdmin(request);
  const uid = requireString(request.data?.uid, "uid");
  const makeAdmin = request.data?.admin === true;
  await admin.auth().setCustomUserClaims(uid, {admin: makeAdmin});
  await db.doc(`users/${uid}`).set(
    {role: makeAdmin ? "admin" : "user"},
    {merge: true}
  );
  return {ok: true, admin: makeAdmin};
});

// ── Record a payment (transactional, server-enforced) ──────────────────────────
export const recordPayment = onCall(async (request) => {
  const adminUid = assertAdmin(request);
  const enrollmentId = requireString(request.data?.enrollmentId, "enrollmentId");
  const amount = request.data?.amount;
  if (typeof amount !== "number" || !Number.isFinite(amount) || amount <= 0) {
    throw new HttpsError("invalid-argument", "A positive amount is required.");
  }
  const note = typeof request.data?.note === "string" ? request.data.note : null;
  const rawRate = request.data?.goldRateAtPayment;
  const goldRate =
    typeof rawRate === "number" && Number.isFinite(rawRate) && rawRate > 0 ?
      rawRate :
      null;

  // Optional admin-selected payment date (ISO string); defaults to now.
  // Honouring it keeps this in parity with the client-side recordPayment path.
  let paidDate: admin.firestore.Timestamp | admin.firestore.FieldValue =
    FieldValue.serverTimestamp();
  const rawPaidDate = request.data?.paidDate;
  if (typeof rawPaidDate === "string") {
    const parsed = new Date(rawPaidDate);
    if (Number.isNaN(parsed.getTime())) {
      throw new HttpsError("invalid-argument", "paidDate is not a valid date.");
    }
    paidDate = Timestamp.fromDate(parsed);
  }

  const enrollmentRef = db.collection("enrollments").doc(enrollmentId);

  const cycle = await db.runTransaction(async (tx) => {
    const snap = await tx.get(enrollmentRef);
    if (!snap.exists) {
      throw new HttpsError("not-found", "Enrollment not found.");
    }
    const e = snap.data()!;
    const duration = (e.durationMonths as number) ?? 12;
    const paymentsMade = (e.paymentsMade as number) ?? 0;
    if (paymentsMade >= duration) {
      throw new HttpsError(
        "failed-precondition",
        "All installments are already paid for this plan."
      );
    }

    const newPaymentsMade = paymentsMade + 1;
    const startTs = e.startDate as admin.firestore.Timestamp | undefined;
    if (!startTs || typeof startTs.toDate !== "function") {
      throw new HttpsError(
        "failed-precondition",
        "Enrollment is missing a valid start date."
      );
    }
    const start = startTs.toDate();
    const progress = computeProgress(start, newPaymentsMade, new Date(), duration);

    const paymentRef = enrollmentRef.collection("payments").doc();
    tx.set(paymentRef, {
      enrollmentId,
      amount,
      cycle: newPaymentsMade,
      paidDate,
      recordedBy: adminUid,
      method: "cash",
      ...(note ? {note} : {}),
      ...(goldRate !== null ? {goldRateAtPayment: goldRate} : {}),
      createdAt: FieldValue.serverTimestamp(),
    });
    tx.update(enrollmentRef, {
      paymentsMade: newPaymentsMade,
      missedMonths: progress.missedMonths,
      projectedDeliveryDate: Timestamp.fromDate(progress.projectedDeliveryDate),
      status: progress.isComplete ? "completed" : "active",
      lastPaymentAt: FieldValue.serverTimestamp(),
    });
    return newPaymentsMade;
  });

  return {ok: true, cycle};
});

// ── Gold rate ──────────────────────────────────────────────────────────────────
async function fetchAndStoreGoldRate(
  apiKey: string,
  updatedBy: string
): Promise<number | null> {
  const currentRef = db.doc("goldRate/current");
  const currentSnap = await currentRef.get();
  if (currentSnap.exists && currentSnap.data()?.lockManual === true) {
    logger.info("Gold rate is locked to manual; skipping API fetch.");
    return null;
  }

  // GoldAPI.io — returns price per gram (24k) and per troy ounce.
  const res = await fetch("https://www.goldapi.io/api/XAU/INR", {
    headers: {"x-access-token": apiKey, "Content-Type": "application/json"},
  });
  if (!res.ok) {
    throw new Error(`Gold API responded ${res.status} ${res.statusText}`);
  }
  const data = (await res.json()) as Record<string, number>;
  const pricePerGram =
    typeof data.price_gram_24k === "number" ?
      data.price_gram_24k :
      data.price / GRAMS_PER_TROY_OUNCE;

  // Guard against a malformed/changed API response (missing fields => NaN),
  // which the Admin SDK would otherwise reject mid-write.
  if (!Number.isFinite(pricePerGram) || pricePerGram <= 0) {
    throw new Error(`Gold API returned no usable price (got ${pricePerGram}).`);
  }

  const payload = {
    pricePerGram,
    currency: "INR",
    source: "api",
    lockManual: false,
    updatedAt: FieldValue.serverTimestamp(),
    updatedBy,
  };
  await currentRef.set(payload, {merge: true});
  await currentRef.collection("history").add(payload);
  logger.info(`Gold rate updated from API: ₹${pricePerGram}/g`);
  return pricePerGram;
}

export const refreshGoldRate = onSchedule(
  {schedule: "every 6 hours", secrets: [goldApiKey]},
  async () => {
    try {
      await fetchAndStoreGoldRate(goldApiKey.value(), "scheduler");
    } catch (err) {
      logger.error("Scheduled gold-rate fetch failed", err);
    }
  }
);

export const refreshGoldRateNow = onCall(
  {secrets: [goldApiKey]},
  async (request) => {
    const adminUid = assertAdmin(request);
    const price = await fetchAndStoreGoldRate(goldApiKey.value(), adminUid);
    return {ok: true, pricePerGram: price};
  }
);

// ── Nightly delivery-date recompute ─────────────────────────────────────────────
export const recomputeDeliveries = onSchedule("every day 02:00", async () => {
  const snap = await db
    .collection("enrollments")
    .where("status", "==", "active")
    .get();
  const now = new Date();
  let batch = db.batch();
  let pending = 0;
  let updated = 0;

  for (const doc of snap.docs) {
    const e = doc.data();
    const duration = (e.durationMonths as number) ?? 12;
    const startTs = e.startDate as admin.firestore.Timestamp | undefined;
    if (!startTs || typeof startTs.toDate !== "function") {
      // Skip a malformed doc rather than aborting the whole nightly batch.
      logger.warn(`Skipping enrollment ${doc.id}: missing/invalid startDate.`);
      continue;
    }
    const start = startTs.toDate();
    const progress = computeProgress(
      start,
      (e.paymentsMade as number) ?? 0,
      now,
      duration
    );
    if (progress.missedMonths !== ((e.missedMonths as number) ?? 0)) {
      batch.update(doc.ref, {
        missedMonths: progress.missedMonths,
        projectedDeliveryDate: Timestamp.fromDate(
          progress.projectedDeliveryDate
        ),
      });
      pending++;
      updated++;
      if (pending >= 400) {
        await batch.commit();
        batch = db.batch();
        pending = 0;
      }
    }
  }
  if (pending > 0) await batch.commit();
  logger.info(`recomputeDeliveries updated ${updated} enrollment(s).`);
});

// ── Push notifications (FCM) ─────────────────────────────────────────────────
// Sent via Firestore triggers so they fire no matter how the write happened
// (client-side path or callable). FCM data values must be strings.
async function notifyUser(
  uid: string,
  notification: {title: string; body: string},
  data: Record<string, string> = {}
): Promise<void> {
  const userSnap = await db.doc(`users/${uid}`).get();
  const token = userSnap.get("fcmToken") as string | undefined;
  if (!token) {
    logger.info(`No FCM token for ${uid}; skipping push.`);
    return;
  }
  try {
    await admin.messaging().send({
      token,
      notification,
      data,
      android: {priority: "high", notification: {sound: "default"}},
      apns: {payload: {aps: {sound: "default"}}},
    });
  } catch (err: unknown) {
    const code = (err as {code?: string})?.code;
    if (
      code === "messaging/registration-token-not-registered" ||
      code === "messaging/invalid-registration-token"
    ) {
      // Token is stale — clear it so we stop trying.
      await db.doc(`users/${uid}`).update({
        fcmToken: admin.firestore.FieldValue.delete(),
      });
      logger.info(`Removed stale FCM token for ${uid}.`);
    } else {
      logger.error(`Push to ${uid} failed`, err);
    }
  }
}

/** Notify a user when their account is approved or rejected. */
export const onUserStatusChanged = onDocumentUpdated(
  "users/{uid}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after || before.status === after.status) return;

    if (after.status === "approved") {
      await notifyUser(event.params.uid, {
        title: "Account approved 🎉",
        body: "You're verified — start a gold savings plan now.",
      }, {type: "approval"});
    } else if (after.status === "rejected") {
      await notifyUser(event.params.uid, {
        title: "Account update",
        body: "Your registration was not approved. Please contact the admin.",
      }, {type: "rejection"});
    }
  }
);

/** Notify a user when the admin records one of their installments. */
export const onPaymentRecorded = onDocumentCreated(
  "enrollments/{enrollmentId}/payments/{paymentId}",
  async (event) => {
    const payment = event.data?.data();
    if (!payment) return;
    const enrollmentId = event.params.enrollmentId;
    const enrollmentSnap = await db.doc(`enrollments/${enrollmentId}`).get();
    if (!enrollmentSnap.exists) return;
    const e = enrollmentSnap.data()!;

    const cycle = (payment.cycle as number) ?? 0;
    const duration = (e.durationMonths as number) ?? 12;
    const planName = (e.planName as string) ?? "your plan";
    const complete = cycle >= duration;

    await notifyUser(
      e.userId as string,
      {
        title: complete ? "Final payment recorded 🥳" : "Payment received ✅",
        body: complete ?
          `All ${duration} payments done for ${planName} — your coin is ready!` :
          `Installment ${cycle} of ${duration} recorded for ${planName}.`,
      },
      {type: "payment", enrollmentId, cycle: String(cycle)}
    );
  }
);

/** Notify a user when their gold coin is delivered. */
export const onCoinDelivered = onDocumentCreated(
  "deliveries/{id}",
  async (event) => {
    const d = event.data?.data();
    if (!d) return;
    await notifyUser(
      d.userId as string,
      {
        title: "Gold coin delivered 🥇",
        body: `Your ${d.grams}g gold coin has been delivered. Congratulations!`,
      },
      {type: "delivery", deliveryId: event.params.id}
    );
  }
);
