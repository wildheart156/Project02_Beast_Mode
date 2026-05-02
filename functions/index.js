const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendNotificationPush = onDocumentCreated(
  "Users/{userId}/Notifications/{notificationId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      logger.warn("Notification trigger fired without snapshot data.");
      return;
    }

    const userId = event.params.userId;
    const notification = snapshot.data() || {};
    const tokensSnapshot = await admin
      .firestore()
      .collection("Users")
      .doc(userId)
      .collection("FcmTokens")
      .get();

    const tokens = tokensSnapshot.docs
      .map((doc) => doc.id)
      .filter((token) => typeof token === "string" && token.length > 0);

    if (tokens.length === 0) {
      logger.info("No FCM tokens found for user.", { userId });
      return;
    }

    const title = buildTitle(notification);
    const body = buildBody(notification);

    const message = {
      tokens,
      notification: {
        title,
        body,
      },
      data: {
        route: "notifications",
        notificationId: event.params.notificationId,
        type: String(notification.type || ""),
        message: String(notification.message || body),
      },
      android: {
        priority: "high",
        notification: {
          channelId: "beast_mode_alerts",
          defaultSound: true,
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
          },
        },
      },
    };

    const response = await admin.messaging().sendEachForMulticast(message);
    const invalidTokenDeletes = [];

    response.responses.forEach((result, index) => {
      if (result.success) {
        return;
      }

      logger.error("Failed to send push notification.", {
        userId,
        token: tokens[index],
        error: result.error,
      });

      const code = result.error?.code || "";
      if (
        code === "messaging/invalid-registration-token" ||
        code === "messaging/registration-token-not-registered"
      ) {
        invalidTokenDeletes.push(
          admin
            .firestore()
            .collection("Users")
            .doc(userId)
            .collection("FcmTokens")
            .doc(tokens[index])
            .delete(),
        );
      }
    });

    await Promise.all(invalidTokenDeletes);
  },
);

function buildTitle(notification) {
  switch (notification.type) {
    case "workout":
      return "Workout logged";
    case "reminder":
      return "Workout reminder";
    case "progress":
      return "Progress update";
    default:
      return "Beast Mode alert";
  }
}

function buildBody(notification) {
  if (typeof notification.message === "string" && notification.message.trim()) {
    return notification.message.trim();
  }

  switch (notification.type) {
    case "workout":
      return "Your workout was saved successfully.";
    case "reminder":
      return "You have not worked out yet today. Stay consistent.";
    case "progress":
      return "You have a new progress update waiting.";
    default:
      return "Open Beast Mode to view your latest alert.";
  }
}
