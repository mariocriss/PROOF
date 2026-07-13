const assert = require('assert');
const fs = require('fs');
const path = require('path');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');

const PROJECT_ID = 'proof-e913a-rules-test';
const RULES_PATH = path.resolve(__dirname, '../../firestore.rules');

const MARIO = 'Cavmfa7J7IPsPVcmPl3RS6FGaTK2';
const CHRIS = 'jUdMRBFI8EOFzbnsYnQnFSdNDEj2';
const THIRD = 'thirdUserNotInvolved00000000001';

/** @type {import('@firebase/rules-unit-testing').RulesTestEnvironment} */
let testEnv;

function authedDb(uid) {
  return testEnv.authenticatedContext(uid).firestore();
}

function friendDocId(userA, userB) {
  return userA < userB
    ? `friend_${userA}_${userB}`
    : `friend_${userB}_${userA}`;
}

async function seedWithRulesDisabled(dataById) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    for (const [id, data] of Object.entries(dataById)) {
      await db.collection('relationships').doc(id).set(data);
    }
  });
}

describe('relationships security rules', () => {
  before(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: PROJECT_ID,
      firestore: {
        rules: fs.readFileSync(RULES_PATH, 'utf8'),
      },
    });
  });

  after(async () => {
    await testEnv.cleanup();
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
  });

  it('allows Mario to create a pending friend request to Chris', async () => {
    const marioDb = authedDb(MARIO);
    const docId = friendDocId(MARIO, CHRIS);

    await assertSucceeds(
      marioDb.collection('relationships').doc(docId).set({
        type: 'friend',
        status: 'pending',
        fromUserId: MARIO,
        toUserId: CHRIS,
        createdAt: new Date().toISOString(),
      }),
    );
  });

  it('denies reading a relationship doc that does not exist', async () => {
    const marioDb = authedDb(MARIO);
    const docId = friendDocId(MARIO, CHRIS);

    await assertFails(marioDb.collection('relationships').doc(docId).get());
  });

  it('allows participant-scoped queries used by the app', async () => {
    const marioDb = authedDb(MARIO);
    const docId = friendDocId(MARIO, CHRIS);

    await seedWithRulesDisabled({
      [docId]: {
        type: 'friend',
        status: 'pending',
        fromUserId: MARIO,
        toUserId: CHRIS,
        createdAt: new Date().toISOString(),
      },
      friend_other: {
        type: 'friend',
        status: 'accepted',
        fromUserId: CHRIS,
        toUserId: THIRD,
        createdAt: new Date().toISOString(),
      },
    });

    const sent = await assertSucceeds(
      marioDb
        .collection('relationships')
        .where('type', '==', 'friend')
        .where('fromUserId', '==', MARIO)
        .get(),
    );
    assert.strictEqual(sent.size, 1);
    assert.strictEqual(sent.docs[0].id, docId);

    const received = await assertSucceeds(
      marioDb
        .collection('relationships')
        .where('type', '==', 'friend')
        .where('toUserId', '==', MARIO)
        .get(),
    );
    assert.strictEqual(received.size, 0);
  });

  it('denies unsafe whereIn queries that can return unreadable docs', async () => {
    const marioDb = authedDb(MARIO);

    await seedWithRulesDisabled({
      friend_chris_third: {
        type: 'friend',
        status: 'accepted',
        fromUserId: CHRIS,
        toUserId: THIRD,
        createdAt: new Date().toISOString(),
      },
    });

    await assertFails(
      marioDb
        .collection('relationships')
        .where('type', '==', 'friend')
        .where('fromUserId', 'in', [MARIO, CHRIS])
        .get(),
    );
  });

  it('requires handle ownership on create', async () => {
    const marioDb = authedDb(MARIO);

    await assertFails(
      marioDb.collection('handles').doc('stolen-handle').set({
        userId: CHRIS,
      }),
    );

    await assertSucceeds(
      marioDb.collection('handles').doc('mario-handle').set({
        userId: MARIO,
      }),
    );
  });
});
