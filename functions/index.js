const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onCall } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
admin.initializeApp();

// 1. ස්වයංක්‍රීයව දින 150කට පසු පණිවිඩ යැවීම
exports.scheduledBloodDonationReminder = onSchedule("every 24 hours", async (event) => {
    const db = admin.firestore();
    const now = new Date();
    const fiveMonthsAgo = new Date();
    fiveMonthsAgo.setDate(now.getDate() - 150);
    const snapshot = await db.collection("donors")
        .where("lastDonationDate", "<=", fiveMonthsAgo)
        .get();
    if (snapshot.empty) {
        console.log("No donors found to remind.");
        return null;
    }
    const promises = [];
    snapshot.forEach((doc) => {
        const donor = doc.data();
        if (donor.fcmToken && typeof donor.fcmToken === 'string' && donor.fcmToken.trim() !== '') {
            const message = {
                notification: {
                    title: "ලේ දන් දීමේ කාලය පැමිණ ඇත!",
                    body: `ඔබේ ලේ වර්ගයට (${donor.bloodGroup || 'N/A'}) අලුතින් ලේ අවශ්‍යතාවයක් පවතී. කරුණාකර අපව සම්බන්ධ කරගන්න.`
                },
                token: donor.fcmToken
            };
            promises.push(admin.messaging().send(message));
        }
    });
    return Promise.all(promises);
});

// 2. Admin Panel එකෙන් ලේ වර්ගය අනුව සමූහ වශයෙන් පණිවිඩ යැවීම (Group Notification)
exports.sendGroupNotification = onCall(async (request) => {
    try {
        const { bloodType, messageContent } = request.data;
        const db = admin.firestore();

        const fiveMonthsAgo = new Date();
        fiveMonthsAgo.setDate(fiveMonthsAgo.getDate() - 150);

        // මාස 6කට වඩා පරණ donors (lastDonationDate field එක තියෙන, 150+ days පරණ)
        const oldDonorsSnapshot = await db.collection("donors")
            .where("bloodGroup", "==", bloodType)
            .where("lastDonationDate", "<=", fiveMonthsAgo)
            .get();

        // එම bloodGroup එකේ සියලුම donors (අලුතින් register වුණු අය filter කරගන්න)
        const allDonorsSnapshot = await db.collection("donors")
            .where("bloodGroup", "==", bloodType)
            .get();

        // lastDonationDate field එකම නැති donors (අලුතින් register වුණු අය)
        const newDonorsDocs = allDonorsSnapshot.docs.filter(doc => !doc.data().lastDonationDate);

        const allDocs = [...oldDonorsSnapshot.docs, ...newDonorsDocs];

        if (allDocs.length === 0) {
            return { success: false, message: "මෙම ලේ වර්ගයට අදාළව දැනුම් දිය යුතු දායකයින් නැත." };
        }

        const promises = [];
        const seenTokens = new Set();

        allDocs.forEach((doc) => {
            const donor = doc.data();
            if (donor.fcmToken && typeof donor.fcmToken === 'string' && donor.fcmToken.trim() !== '' && !seenTokens.has(donor.fcmToken)) {
                seenTokens.add(donor.fcmToken);
                const message = {
                    notification: {
                        title: "හදිසි ලේ අවශ්‍යතාවයක්!",
                        body: messageContent
                    },
                    token: donor.fcmToken
                };
                promises.push(admin.messaging().send(message));
            }
        });

        if (promises.length === 0) {
            return { success: false, message: "මෙම ලේ වර්ගයට අදාළ දායකයින් සිටී, ඒත් notification token නැත." };
        }

        const results = await Promise.allSettled(promises);
        const successCount = results.filter(r => r.status === 'fulfilled').length;

        return { success: true, count: successCount };
    } catch (error) {
        console.error("sendGroupNotification error:", error);
        throw new Error(error.message || "Unknown error occurred");
    }
});