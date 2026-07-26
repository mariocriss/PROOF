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
const CAROL = 'carolUser000000000000000000001';

/** @type {import('@firebase/rules-unit-testing').RulesTestEnvironment} */
let testEnv;

function authedDb(uid) {
  return testEnv.authenticatedContext(uid).firestore();
}

function unauthDb() {
  return testEnv.unauthenticatedContext().firestore();
}

describe('account deletion security rules', () => {
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

  it('users cannot delete another user private profile data', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc(`users/${ALICE}`).set({ email: 'a@example.com' });
      await db.doc(`users/${ALICE}/identity/profile`).set({
        handle: 'alice',
        isPublic: false,
      });
      await db.doc(`users/${ALICE}/skills/s1`).set({ name: 'Pull-ups' });
      await db.doc(`users/${ALICE}/proofs/p1`).set({
        skillId: 's1',
        coachId: BOB,
      });
    });

    const bob = authedDb(BOB);
    await assertFails(bob.doc(`users/${ALICE}`).delete());
    await assertFails(bob.doc(`users/${ALICE}/identity/profile`).delete());
    await assertFails(bob.doc(`users/${ALICE}/skills/s1`).delete());
    await assertFails(bob.doc(`users/${ALICE}/proofs/p1`).delete());
  });

  it('users can delete the exact documents required for their own deletion', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc(`users/${ALICE}`).set({
        email: 'a@example.com',
        managedGymIds: ['gym1'],
      });
      await db.doc(`users/${ALICE}/identity/profile`).set({
        handle: 'alice',
        isPublic: true,
      });
      await db.doc(`users/${ALICE}/skills/s1`).set({ name: 'Squat' });
      await db.doc(`users/${ALICE}/proofs/p1`).set({ skillId: 's1' });
      await db.doc(`users/${ALICE}/timeline/t1`).set({ type: 'skill_created' });
      await db.doc(`handles/alice`).set({ userId: ALICE });
      await db.doc(`publicProfiles/${ALICE}`).set({ handle: 'alice' });
      await db.doc(`coachProfiles/${ALICE}`).set({
        userId: ALICE,
        handle: 'alicecoach',
      });
      await db.doc(`handles/alicecoach`).set({ userId: ALICE });
      await db.doc(`relationships/friend_${ALICE}_${BOB}`).set({
        type: 'friend',
        status: 'accepted',
        fromUserId: ALICE,
        toUserId: BOB,
      });
      await db.doc(`gyms/gym1`).set({
        createdBy: ALICE,
        handle: 'alicegym',
        name: 'Alice Gym',
      });
      await db.doc(`gymHandles/alicegym`).set({ gymId: 'gym1' });
      await db.doc(`gymMemberships/gym1_${ALICE}_manager`).set({
        gymId: 'gym1',
        userId: ALICE,
        membershipType: 'manager',
        status: 'approved',
      });
      await db.doc(`gymMemberships/gym1_${BOB}_athlete`).set({
        gymId: 'gym1',
        userId: BOB,
        membershipType: 'athlete',
        status: 'approved',
      });
      await db.doc(`verificationRequests/vr1`).set({
        athleteId: ALICE,
        coachId: BOB,
        gymId: 'gym1',
        status: 'pending',
      });
      await db.doc(`userReports/r1`).set({
        reporterUserId: ALICE,
        reportedUserId: BOB,
        reason: 'spam',
      });
    });

    const alice = authedDb(ALICE);

    await assertSucceeds(alice.doc(`handles/alice`).delete());
    await assertSucceeds(alice.doc(`handles/alicecoach`).delete());
    await assertSucceeds(
      alice.doc(`relationships/friend_${ALICE}_${BOB}`).delete(),
    );
    await assertSucceeds(alice.doc(`verificationRequests/vr1`).delete());
    await assertSucceeds(alice.doc(`userReports/r1`).delete());
    await assertSucceeds(alice.doc(`coachProfiles/${ALICE}`).delete());
    await assertSucceeds(
      alice.doc(`gymMemberships/gym1_${ALICE}_manager`).delete(),
    );
    // Creator may remove other members when closing the gym.
    await assertSucceeds(
      alice.doc(`gymMemberships/gym1_${BOB}_athlete`).delete(),
    );
    await assertSucceeds(alice.doc(`gymHandles/alicegym`).delete());
    await assertSucceeds(alice.doc(`gyms/gym1`).delete());
    await assertSucceeds(alice.doc(`users/${ALICE}/skills/s1`).delete());
    await assertSucceeds(alice.doc(`users/${ALICE}/proofs/p1`).delete());
    await assertSucceeds(alice.doc(`users/${ALICE}/timeline/t1`).delete());
    await assertSucceeds(alice.doc(`users/${ALICE}/identity/profile`).delete());
    await assertSucceeds(alice.doc(`publicProfiles/${ALICE}`).delete());
    await assertSucceeds(alice.doc(`users/${ALICE}`).delete());
  });

  it('reporters cannot delete other users reports', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc(`userReports/bobReport`).set({
        reporterUserId: BOB,
        reportedUserId: CAROL,
        reason: 'harassment',
      });
    });

    const alice = authedDb(ALICE);
    await assertFails(alice.doc(`userReports/bobReport`).delete());
  });

  it('reported users cannot delete reports about themselves', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc(`userReports/aboutAlice`).set({
        reporterUserId: BOB,
        reportedUserId: ALICE,
        reason: 'spam',
      });
    });

    const alice = authedDb(ALICE);
    await assertFails(alice.doc(`userReports/aboutAlice`).delete());
  });

  it('athletes and coaches cannot delete unrelated verification requests', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc(`verificationRequests/other`).set({
        athleteId: BOB,
        coachId: CAROL,
        gymId: 'gymX',
        status: 'pending',
      });
    });

    const alice = authedDb(ALICE);
    await assertFails(alice.doc(`verificationRequests/other`).delete());
  });

  it('coach can delete verification requests they are assigned to', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc(`verificationRequests/assigned`).set({
        athleteId: ALICE,
        coachId: BOB,
        gymId: 'gym1',
        status: 'pending',
      });
    });

    const bob = authedDb(BOB);
    await assertSucceeds(bob.doc(`verificationRequests/assigned`).delete());
  });

  it('unauthorized users cannot delete gym memberships of others', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc(`gyms/gym2`).set({
        createdBy: BOB,
        handle: 'bobgym',
      });
      await db.doc(`gymMemberships/gym2_${BOB}_athlete`).set({
        gymId: 'gym2',
        userId: BOB,
        membershipType: 'athlete',
        status: 'approved',
      });
    });

    const alice = authedDb(ALICE);
    await assertFails(
      alice.doc(`gymMemberships/gym2_${BOB}_athlete`).delete(),
    );
  });

  it('unauthenticated users cannot trigger cleanup deletes', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc(`users/${ALICE}`).set({ email: 'a@example.com' });
      await db.doc(`handles/alice`).set({ userId: ALICE });
      await db.doc(`verificationRequests/vr1`).set({
        athleteId: ALICE,
        coachId: BOB,
        gymId: 'gym1',
        status: 'pending',
      });
      await db.doc(`userReports/r1`).set({
        reporterUserId: ALICE,
        reportedUserId: BOB,
        reason: 'spam',
      });
    });

    const guest = unauthDb();
    await assertFails(guest.doc(`users/${ALICE}`).delete());
    await assertFails(guest.doc(`handles/alice`).delete());
    await assertFails(guest.doc(`verificationRequests/vr1`).delete());
    await assertFails(guest.doc(`userReports/r1`).delete());
  });

  it('reported user can anonymize handle on retained reports about them', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc(`userReports/aboutAlice`).set({
        reporterUserId: BOB,
        reportedUserId: ALICE,
        reportedHandle: 'alice',
        reason: 'spam',
        details: '',
        createdAt: new Date('2026-01-01T00:00:00.000Z'),
        reportedAccountDeleted: false,
      });
    });

    const alice = authedDb(ALICE);
    await assertSucceeds(
      alice.doc(`userReports/aboutAlice`).update({
        reportedHandle: '[deleted]',
        reportedAccountDeleted: true,
      }),
    );
  });

  it('reported user cannot change report reason or reporter during anonymization', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc(`userReports/aboutAlice2`).set({
        reporterUserId: BOB,
        reportedUserId: ALICE,
        reportedHandle: 'alice',
        reason: 'spam',
        details: '',
        createdAt: new Date('2026-01-01T00:00:00.000Z'),
      });
    });

    const alice = authedDb(ALICE);
    await assertFails(
      alice.doc(`userReports/aboutAlice2`).update({
        reportedHandle: '[deleted]',
        reportedAccountDeleted: true,
        reason: 'harassment',
      }),
    );
  });

  it('coach can anonymize athlete proofs they verified without deleting them', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc(`users/${ALICE}/identity/profile`).set({
        handle: 'alice',
        isPublic: true,
      });
      await db.doc(`users/${ALICE}/proofs/pCoach`).set({
        userId: ALICE,
        skillId: 's1',
        title: 'Squat',
        result: '100',
        unit: 'kg',
        proofSource: 'coach',
        verificationStatus: 'coach_verified',
        coachId: BOB,
        requestedCoachId: BOB,
        verifiedByCoachId: BOB,
        coachAccountDeleted: false,
      });
    });

    const bob = authedDb(BOB);
    await assertSucceeds(
      bob.doc(`users/${ALICE}/proofs/pCoach`).update({
        coachId: null,
        requestedCoachId: null,
        verifiedByCoachId: null,
        coachAccountDeleted: true,
        verificationStatus: 'coach_verified',
        proofSource: 'coach',
      }),
    );
  });

  it('unrelated users cannot anonymize coach references on proofs', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc(`users/${ALICE}/proofs/pOther`).set({
        userId: ALICE,
        skillId: 's1',
        title: 'Squat',
        result: '100',
        unit: 'kg',
        proofSource: 'coach',
        verificationStatus: 'coach_verified',
        coachId: BOB,
        requestedCoachId: BOB,
        verifiedByCoachId: BOB,
        coachAccountDeleted: false,
      });
    });

    const carol = authedDb(CAROL);
    await assertFails(
      carol.doc(`users/${ALICE}/proofs/pOther`).update({
        coachId: null,
        requestedCoachId: null,
        verifiedByCoachId: null,
        coachAccountDeleted: true,
      }),
    );
  });
});
