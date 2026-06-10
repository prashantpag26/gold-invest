/**
 * Bootstrap the first admin (or grant/revoke admin later).
 *
 * Custom claims can only be set with the Admin SDK, so this small script runs
 * locally with a service-account key — it does NOT need the Blaze plan or any
 * deployed function.
 *
 * Setup (one time):
 *   1. Firebase console → Project settings → Service accounts → Generate new
 *      private key. Save it as `serviceAccountKey.json` at the repo root
 *      (it's already in .gitignore — never commit it).
 *   2. cd functions && npm install      (installs firebase-admin used below)
 *
 * Usage (run from the repo root):
 *   node functions/tools/set_admin.js admin@example.com          # grant admin
 *   node functions/tools/set_admin.js admin@example.com false    # revoke admin
 *
 * After running, the user must sign out and back in (or the app calls
 * getIdToken(true)) for the new claim to take effect.
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

(async () => {
  const email = process.argv[2];
  const makeAdmin = process.argv[3] !== "false";
  if (!email) {
    console.error("Usage: node functions/tools/set_admin.js <email> [true|false]");
    process.exit(1);
  }
  const user = await admin.auth().getUserByEmail(email);
  await admin.auth().setCustomUserClaims(user.uid, {admin: makeAdmin});
  await admin
    .firestore()
    .doc(`users/${user.uid}`)
    .set(
      {
        role: makeAdmin ? "admin" : "user",
        ...(makeAdmin ? {status: "approved"} : {}),
      },
      {merge: true}
    );
  console.log(
    `✅ ${email} (${user.uid}) admin=${makeAdmin}. ` +
      "Ask them to sign out and back in to refresh the token."
  );
  process.exit(0);
})().catch((e) => {
  console.error("Error:", e.message);
  process.exit(1);
});
