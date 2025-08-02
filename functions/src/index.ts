import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

const MAX_ACTIONS_PER_MINUTE = 50;
const WINDOW_MS = 60 * 1000;

export const rateLimitedAction = functions.https.onCall(async (data: any, context) => {
  const clientId = data?.clientId;
  if (!clientId || typeof clientId !== "string") {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Missing or invalid 'clientId'."
    );
  }

  const now = Date.now();
  const oneMinuteAgo = now - WINDOW_MS;

  const clientRef = admin.firestore().collection("rate_limits").doc(clientId);
  const snapshot = await clientRef.get();
  let actions: number[] = [];

  if (snapshot.exists) {
    actions = snapshot.data()?.actions || [];
    actions = actions.filter((timestamp) => timestamp > oneMinuteAgo);
  }

  if (actions.length >= MAX_ACTIONS_PER_MINUTE) {
    throw new functions.https.HttpsError(
      "resource-exhausted",
      "Rate limit exceeded. Please try again later."
    );
  }

  actions.push(now);
  await clientRef.set({ actions });

  return { success: true, message: "Action allowed." };
});
