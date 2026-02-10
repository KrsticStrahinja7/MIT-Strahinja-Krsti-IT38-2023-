const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { DateTime } = require('luxon');

admin.initializeApp();

function todayDateString(tz) {
  return DateTime.now().setZone(tz).toFormat('yyyy-LL-dd');
}

async function sendRaceDayNotification({ dateStr, tz }) {
  const db = admin.firestore();

  const racesSnap = await db
    .collection('races')
    .where('date', '==', dateStr)
    .get();

  if (racesSnap.empty) {
    return { sent: false, date: dateStr, races: [] };
  }

  const races = racesSnap.docs.map((d) => {
    const data = d.data() || {};
    return {
      id: d.id,
      name: data.name || d.id,
      date: data.date || dateStr,
      city: data.city || '',
      country: data.country || '',
    };
  });

  const title = 'Danas je trka';
  const raceNames = races.map((r) => r.name);
  const body =
    raceNames.length === 1
      ? `${raceNames[0]}`
      : `Trke danas: ${raceNames.join(', ')}`;

  const message = {
    topic: 'race-day',
    notification: {
      title,
      body,
    },
    data: {
      type: 'race_day',
      date: dateStr,
      tz,
      raceIds: JSON.stringify(races.map((r) => r.id)),
    },
  };

  const resp = await admin.messaging().send(message);
  return { sent: true, date: dateStr, races, messageId: resp };
}

// Scheduled every day at 09:00 in Europe/Belgrade.
exports.notifyRaceDay = functions
  .region('europe-west1')
  .pubsub.schedule('0 9 * * *')
  .timeZone('Europe/Belgrade')
  .onRun(async () => {
    const tz = 'Europe/Belgrade';
    const dateStr = todayDateString(tz);
    const res = await sendRaceDayNotification({ dateStr, tz });
    functions.logger.info('notifyRaceDay result', res);
    return null;
  });

// Manual trigger for testing (GET /notifyRaceDayTest?date=YYYY-MM-DD)
exports.notifyRaceDayTest = functions
  .region('europe-west1')
  .https.onRequest(async (req, res) => {
    try {
      const tz = 'Europe/Belgrade';
      const dateStr = (req.query.date || '').toString().trim() || todayDateString(tz);
      const result = await sendRaceDayNotification({ dateStr, tz });
      res.status(200).json(result);
    } catch (e) {
      functions.logger.error(e);
      res.status(500).json({ error: e?.message || String(e) });
    }
  });
