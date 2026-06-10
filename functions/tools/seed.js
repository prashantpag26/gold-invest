/**
 * Seed sample data: a handful of investment plans and a default gold rate.
 *
 * Idempotent — plans use fixed document IDs, so re-running updates them in
 * place instead of creating duplicates. The gold rate is only written if one
 * doesn't already exist (so it never clobbers an admin's value).
 *
 * Prereqs (same as set_admin.js):
 *   1. Save a service-account key as `serviceAccountKey.json` at the repo root.
 *   2. cd functions && npm install
 *
 * Usage (from the repo root):
 *   node functions/tools/seed.js                 # seed plans + default rate
 *   node functions/tools/seed.js --rate 9500     # also set the gold rate (₹/g)
 *   node functions/tools/seed.js --force-rate     # overwrite an existing rate
 */
const path = require("path");
const admin = require("firebase-admin");

const keyPath =
  process.env.SERVICE_ACCOUNT ||
  path.resolve(__dirname, "..", "..", "serviceAccountKey.json");

try {
  // eslint-disable-next-line import/no-dynamic-require, global-require
  admin.initializeApp({credential: admin.credential.cert(require(keyPath))});
} catch (e) {
  console.error(`Could not load a service-account key from:\n  ${keyPath}\n`);
  console.error(
    "Download it from Firebase console → Project settings → Service accounts,\n" +
      "save it as serviceAccountKey.json at the repo root, or set\n" +
      "SERVICE_ACCOUNT=/absolute/path/to/key.json"
  );
  process.exit(1);
}

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

// Sample denominations. Monthly amounts are illustrative — adjust to your
// scheme's pricing. durationMonths is the number of payments before redemption.
const SAMPLE_PLANS = [
  {id: "seed_1g", name: "1g Monthly Saver", grams: 1, monthlyAmount: 600, durationMonths: 12},
  {id: "seed_2g", name: "2g Monthly Saver", grams: 2, monthlyAmount: 1200, durationMonths: 12},
  {id: "seed_5g", name: "5g Gold Plan", grams: 5, monthlyAmount: 3000, durationMonths: 12},
  {id: "seed_10g", name: "10g Gold Builder", grams: 10, monthlyAmount: 6000, durationMonths: 12},
];

function parseArgs(argv) {
  const args = {forceRate: false, rate: null};
  for (let i = 2; i < argv.length; i++) {
    if (argv[i] === "--force-rate") args.forceRate = true;
    else if (argv[i] === "--rate") args.rate = Number(argv[++i]);
  }
  return args;
}

async function seedPlans() {
  const batch = db.batch();
  for (const p of SAMPLE_PLANS) {
    batch.set(
      db.doc(`plans/${p.id}`),
      {
        name: p.name,
        grams: p.grams,
        monthlyAmount: p.monthlyAmount,
        durationMonths: p.durationMonths,
        active: true,
        createdAt: FieldValue.serverTimestamp(),
      },
      {merge: true}
    );
  }
  await batch.commit();
  console.log(`✅ Seeded ${SAMPLE_PLANS.length} plans.`);
}

async function seedGoldRate(args) {
  const ref = db.doc("goldRate/current");
  const snap = await ref.get();
  if (snap.exists && !args.forceRate) {
    console.log("ℹ️  Gold rate already exists — leaving it untouched " +
      "(use --force-rate to overwrite).");
    return;
  }
  const pricePerGram = args.rate && args.rate > 0 ? args.rate : 9500; // ₹/g default
  await ref.set(
    {
      pricePerGram,
      currency: "INR",
      source: "manual",
      lockManual: true,
      updatedAt: FieldValue.serverTimestamp(),
      updatedBy: "seed-script",
    },
    {merge: true}
  );
  console.log(`✅ Set gold rate to ₹${pricePerGram}/g (manual, locked).`);
}

(async () => {
  const args = parseArgs(process.argv);
  await seedPlans();
  await seedGoldRate(args);
  console.log("Done.");
  process.exit(0);
})().catch((e) => {
  console.error("Error:", e.message);
  process.exit(1);
});
