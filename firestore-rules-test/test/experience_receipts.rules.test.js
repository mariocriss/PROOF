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

const ALICE = 'aliceUser000000000000000000001';
const BOB = 'bobUser0000000000000000000000001';

/** @type {import('@firebase/rules-unit-testing').RulesTestEnvironment} */
let testEnv;

function authedDb(uid) {
  return testEnv.authenticatedContext(uid).firestore();
}

function unauthedDb() {
  return testEnv.unauthenticatedContext().firestore();
}

function receiptPayload(ownerId, overrides = {}) {
  return {
    ownerId,
    eventType: 'onboarding_completed',
    sourceId: ownerId,
    importance: 'T3',
    status: 'pending',
    schemaVersion: 1,
    createdAt: new Date(),
    ...overrides,
  };
}

describe('experience receipt security rules', () => {
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

  it('owner can create and read own receipts', async () => {
    const alice = authedDb(ALICE);
    const ref = alice.doc(
      `users/${ALICE}/experienceReceipts/onboardingCompleted:${ALICE}`,
    );
    await assertSucceeds(ref.set(receiptPayload(ALICE)));
    await assertSucceeds(ref.get());
  });

  it('owner can get a missing receipt document (claim path)', async () => {
    const alice = authedDb(ALICE);
    await assertSucceeds(
      alice
        .doc(`users/${ALICE}/experienceReceipts/onboardingCompleted:${ALICE}`)
        .get(),
    );
  });

  it('owner can update and delete own receipt', async () => {
    const alice = authedDb(ALICE);
    const ref = alice.doc(`users/${ALICE}/experienceReceipts/evt1`);
    await assertSucceeds(ref.set(receiptPayload(ALICE)));
    await assertSucceeds(ref.update({ status: 'completed' }));
    await assertSucceeds(ref.delete());
  });

  it('owner can list own receipts by status', async () => {
    const alice = authedDb(ALICE);
    await assertSucceeds(
      alice.doc(`users/${ALICE}/experienceReceipts/a`).set(receiptPayload(ALICE)),
    );
    await assertSucceeds(
      alice
        .collection(`users/${ALICE}/experienceReceipts`)
        .where('status', 'in', ['pending', 'presenting', 'failed'])
        .get(),
    );
  });

  it('other user cannot read receipts', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc(`users/${ALICE}/experienceReceipts/evt1`).set(
        receiptPayload(ALICE, { status: 'completed' }),
      );
    });

    const bob = authedDb(BOB);
    await assertFails(bob.doc(`users/${ALICE}/experienceReceipts/evt1`).get());
  });

  it('other user cannot write receipts', async () => {
    const bob = authedDb(BOB);
    await assertFails(
      bob
        .doc(`users/${ALICE}/experienceReceipts/hack`)
        .set(receiptPayload(ALICE)),
    );
    await assertFails(
      bob.doc(`users/${ALICE}/experienceReceipts/hack`).set(receiptPayload(BOB)),
    );
  });

  it('owner cannot create receipt with mismatched ownerId', async () => {
    const alice = authedDb(ALICE);
    await assertFails(
      alice
        .doc(`users/${ALICE}/experienceReceipts/bad`)
        .set(receiptPayload(BOB)),
    );
  });

  it('unauthenticated access denied', async () => {
    const db = unauthedDb();
    await assertFails(
      db
        .doc(`users/${ALICE}/experienceReceipts/x`)
        .set(receiptPayload(ALICE)),
    );
    await assertFails(
      db.doc(`users/${ALICE}/experienceReceipts/x`).get(),
    );
  });

  it('invalid status denied on create', async () => {
    const alice = authedDb(ALICE);
    await assertFails(
      alice
        .doc(`users/${ALICE}/experienceReceipts/badStatus`)
        .set(receiptPayload(ALICE, { status: 'nope' })),
    );
  });

  it('missing required create fields denied', async () => {
    const alice = authedDb(ALICE);
    await assertFails(
      alice.doc(`users/${ALICE}/experienceReceipts/incomplete`).set({
        ownerId: ALICE,
        status: 'pending',
      }),
    );
  });
});
