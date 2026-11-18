const assert = require('assert');
const fs = require('fs');
const path = require('path');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const firebase = require('firebase/compat/app');
require('firebase/compat/firestore');

const RULES_PATH = path.resolve(__dirname, '../../firestore.rules');
const ALICE = 'aliceSocialUser000000000000001';
const BOB = 'bobSocialUser00000000000000001';
const CAROL = 'carolSocialUser000000000000001';
const GYM_A = 'gym-a';
const GYM_B = 'gym-b';
const PROOF = 'proof-shared';
const SKILL = 'skill-1';
const RECORDED_AT = new Date('2026-03-01T12:00:00.000Z');
const FieldValue = firebase.firestore.FieldValue;

describe('gym activity security rules', () => {
  /** @type {import('@firebase/rules-unit-testing').RulesTestEnvironment} */
  let env;

  before(async () => {
    env = await initializeTestEnvironment({
      projectId: 'proof-social-activity',
      firestore: {rules: fs.readFileSync(RULES_PATH, 'utf8')},
    });
  });

  after(() => env.cleanup());
  beforeEach(async () => {
    await env.clearFirestore();
    await env.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.collection('gyms').doc(GYM_A).set({
        createdBy: 'owner',
        name: 'Gym A',
      });
      await db.collection('gyms').doc(GYM_B).set({
        createdBy: 'owner',
        name: 'Gym B',
      });
      await seedMember(db, GYM_A, ALICE, 'athlete');
      await seedMember(db, GYM_A, BOB, 'athlete');
      await seedMember(db, GYM_B, CAROL, 'athlete');
      await db.collection('users').doc(ALICE).collection('identity').doc('profile')
        .set({displayName: 'Alice', avatarUrl: '', isPublic: false});
      await db.collection('users').doc(BOB).collection('identity').doc('profile')
        .set({displayName: 'Bob', avatarUrl: '', isPublic: false});
      await db.collection('users').doc(ALICE).collection('skills').doc(SKILL)
        .set({name: '5K', discipline: 'Running'});
      await db.collection('users').doc(ALICE).collection('proofs').doc(PROOF)
        .set({
          userId: ALICE,
          skillId: SKILL,
          result: '20:00',
          unit: 'time',
          recordedAt: RECORDED_AT,
          verificationStatus: 'self_reported',
          variantName: '',
          notes: 'secret personal note',
          mediaUrl: 'https://private.example/photo.jpg',
        });
      await db.collection('relationships').doc('alice_carol').set({
        fromUserId: ALICE,
        toUserId: CAROL,
        type: 'friend',
        status: 'accepted',
      });
      await db.collection('gyms').doc(GYM_B).collection('activity').doc('other')
        .set({
          ...activityData(GYM_B, CAROL, 'other'),
          sharedAt: RECORDED_AT,
        });
    });
  });

  it('lets an athlete share only by matching the private proof', async () => {
    const alice = env.authenticatedContext(ALICE).firestore();
    await assertSucceeds(share(alice, GYM_A));

    const shared = await env.authenticatedContext(BOB).firestore()
      .collection('gyms').doc(GYM_A).collection('activity').doc(PROOF)
      .get();
    assert.equal(shared.exists, true);
    assert.equal(shared.data().notes, undefined);
    assert.equal(shared.data().mediaUrl, undefined);
    assert.equal(shared.data().result, '20:00');
    assert.equal(shared.data().verificationStatus, 'self_reported');
  });

  it('rejects a share that forges coach verification or skips the proof flag', async () => {
    const alice = env.authenticatedContext(ALICE).firestore();
    await assertFails(share(alice, GYM_A, {verificationStatus: 'coach_verified'}));

    const batch = alice.batch();
    batch.set(
      alice.collection('gyms').doc(GYM_A).collection('activity').doc(PROOF),
      activityData(GYM_A, ALICE, PROOF),
    );
    await assertFails(batch.commit());
  });

  it('rejects activity created for someone else', async () => {
    const bob = env.authenticatedContext(BOB).firestore();
    const batch = bob.batch();
    batch.set(
      bob.collection('gyms').doc(GYM_A).collection('activity').doc(PROOF),
      activityData(GYM_A, BOB, PROOF),
    );
    await assertFails(batch.commit());
  });

  it('shows gym activity only to approved members of that gym', async () => {
    await env.withSecurityRulesDisabled(async (context) => {
      await share(context.firestore(), GYM_A);
    });

    const bob = env.authenticatedContext(BOB).firestore();
    const carol = env.authenticatedContext(CAROL).firestore();
    const stranger = env.unauthenticatedContext().firestore();

    await assertSucceeds(
      bob.collection('gyms').doc(GYM_A).collection('activity')
        .where('status', '==', 'active')
        .orderBy('sharedAt', 'desc')
        .get(),
    );
    await assertFails(
      carol.collection('gyms').doc(GYM_A).collection('activity').doc(PROOF).get(),
    );
    await assertFails(
      carol.collection('gyms').doc(GYM_A).collection('activity')
        .where('status', '==', 'active')
        .get(),
    );
    await assertFails(
      env.authenticatedContext(ALICE).firestore()
        .collection('gyms').doc(GYM_B).collection('activity').doc('other')
        .get(),
    );
    await assertFails(stranger.collection('gyms').doc(GYM_A).collection('activity').doc(PROOF).get());
    await assertFails(
      bob.collection('users').doc(ALICE).collection('proofs').doc(PROOF).get(),
    );
  });

  it('lets a gym member like once and then remove that like', async () => {
    await env.withSecurityRulesDisabled(async (context) => {
      await share(context.firestore(), GYM_A);
    });
    const bob = env.authenticatedContext(BOB).firestore();
    const activity = bob.collection('gyms').doc(GYM_A).collection('activity').doc(PROOF);
    const like = activity.collection('likes').doc(BOB);

    await assertSucceeds(bob.runTransaction(async (tx) => {
      tx.update(activity, {likeCount: 1});
      tx.set(like, {userId: BOB, createdAt: FieldValue.serverTimestamp()});
    }));
    await assertFails(bob.runTransaction(async (tx) => {
      tx.update(activity, {likeCount: 2});
      tx.set(like, {userId: BOB, createdAt: FieldValue.serverTimestamp()});
    }));
    await assertFails(bob.runTransaction(async (tx) => {
      tx.update(activity, {likeCount: 9});
    }));
    await assertSucceeds(bob.runTransaction(async (tx) => {
      tx.update(activity, {likeCount: 0});
      tx.delete(like);
    }));
  });

  it('rejects likes from the owner and from another gym', async () => {
    await env.withSecurityRulesDisabled(async (context) => {
      await share(context.firestore(), GYM_A);
    });
    const alice = env.authenticatedContext(ALICE).firestore();
    const carol = env.authenticatedContext(CAROL).firestore();
    await assertFails(alice.runTransaction(async (tx) => {
      const activity = alice.collection('gyms').doc(GYM_A).collection('activity').doc(PROOF);
      tx.update(activity, {likeCount: 1});
      tx.set(activity.collection('likes').doc(ALICE), {
        userId: ALICE,
        createdAt: FieldValue.serverTimestamp(),
      });
    }));
    await assertFails(carol.runTransaction(async (tx) => {
      const activity = carol.collection('gyms').doc(GYM_A).collection('activity').doc(PROOF);
      tx.update(activity, {likeCount: 1});
      tx.set(activity.collection('likes').doc(CAROL), {
        userId: CAROL,
        createdAt: FieldValue.serverTimestamp(),
      });
    }));
  });

  it('accepts a short comment and rejects empty, long, and rapid repeats', async () => {
    await env.withSecurityRulesDisabled(async (context) => {
      await share(context.firestore(), GYM_A);
    });
    const bob = env.authenticatedContext(BOB).firestore();
    await assertSucceeds(comment(bob, 'c1', 'Nice work', 1));
    await assertFails(comment(bob, 'c2', '   ', 2));
    await assertFails(comment(bob, 'c3', 'a'.repeat(301), 2));
    await assertFails(comment(bob, 'c4', 'Too soon', 2));

    const alice = env.authenticatedContext(ALICE).firestore();
    await assertFails(comment(alice, 'own', 'Mine', 2, ALICE, 'Alice'));
    const carol = env.authenticatedContext(CAROL).firestore();
    await assertFails(comment(carol, 'nope', 'Hello', 2, CAROL, 'Carol'));
  });

  it('lets the author delete their comment and nobody else', async () => {
    await env.withSecurityRulesDisabled(async (context) => {
      await share(context.firestore(), GYM_A);
      const db = context.firestore();
      const activity = db.collection('gyms').doc(GYM_A).collection('activity').doc(PROOF);
      await activity.collection('comments').doc('c1').set({
        authorId: BOB,
        text: 'Nice work',
        displayName: 'Bob',
        avatarUrl: '',
        createdAt: RECORDED_AT,
      });
      await activity.update({commentCount: 1, lastCommentId: 'c1'});
    });

    const alice = env.authenticatedContext(ALICE).firestore();
    await assertFails(alice.runTransaction(async (tx) => {
      const activity = alice.collection('gyms').doc(GYM_A).collection('activity').doc(PROOF);
      tx.update(activity, {commentCount: 0, lastCommentId: 'c1'});
      tx.delete(activity.collection('comments').doc('c1'));
    }));

    const bob = env.authenticatedContext(BOB).firestore();
    await assertSucceeds(bob.runTransaction(async (tx) => {
      const activity = bob.collection('gyms').doc(GYM_A).collection('activity').doc(PROOF);
      tx.update(activity, {commentCount: 0, lastCommentId: 'c1'});
      tx.delete(activity.collection('comments').doc('c1'));
    }));
  });

  it('lets the owner delete the post together with likes and comments', async () => {
    await env.withSecurityRulesDisabled(async (context) => {
      await share(context.firestore(), GYM_A);
      const db = context.firestore();
      const activity = db.collection('gyms').doc(GYM_A).collection('activity').doc(PROOF);
      await activity.collection('likes').doc(BOB).set({
        userId: BOB,
        createdAt: RECORDED_AT,
      });
      await activity.collection('comments').doc('c1').set({
        authorId: BOB,
        text: 'Nice work',
        displayName: 'Bob',
        avatarUrl: '',
        createdAt: RECORDED_AT,
      });
      await activity.collection('commentRate').doc(BOB).set({
        userId: BOB,
        lastAt: RECORDED_AT,
      });
      await activity.update({likeCount: 1, commentCount: 1, lastCommentId: 'c1'});
    });

    const alice = env.authenticatedContext(ALICE).firestore();
    const activity = alice.collection('gyms').doc(GYM_A).collection('activity').doc(PROOF);
    await assertSucceeds(activity.collection('comments').get());
    await assertSucceeds(activity.collection('likes').get());
    await assertSucceeds(activity.collection('commentRate').get());

    const batch = alice.batch();
    batch.delete(activity.collection('likes').doc(BOB));
    batch.delete(activity.collection('comments').doc('c1'));
    batch.delete(activity.collection('commentRate').doc(BOB));
    batch.delete(activity);
    await assertSucceeds(batch.commit());

    const bob = env.authenticatedContext(BOB).firestore();
    await assertFails(activity.get());
    await assertFails(
      bob.collection('gyms').doc(GYM_A).collection('activity').doc(PROOF).get(),
    );
  });

  it('removes feed access when the owner deletes the activity', async () => {
    await env.withSecurityRulesDisabled(async (context) => {
      await share(context.firestore(), GYM_A);
    });
    const alice = env.authenticatedContext(ALICE).firestore();
    await assertSucceeds(
      alice.collection('gyms').doc(GYM_A).collection('activity').doc(PROOF).delete(),
    );
    const bob = env.authenticatedContext(BOB).firestore();
    await assertFails(
      bob.collection('gyms').doc(GYM_A).collection('activity').doc(PROOF).get(),
    );
  });
});

function seedMember(db, gymId, userId, type) {
  return db.collection('gymMemberships').doc(`${gymId}_${userId}_${type}`).set({
    gymId,
    userId,
    membershipType: type,
    status: 'approved',
  });
}

function activityData(gymId, athleteId, proofId, overrides = {}) {
  return {
    gymId,
    athleteId,
    proofId,
    skillId: SKILL,
    skillName: '5K',
    discipline: 'Running',
    variantName: '',
    result: '20:00',
    unit: 'time',
    recordedAt: RECORDED_AT,
    verificationStatus: 'self_reported',
    displayName: athleteId === ALICE ? 'Alice' : 'Bob',
    avatarUrl: '',
    status: 'active',
    likeCount: 0,
    commentCount: 0,
    sharedAt: FieldValue.serverTimestamp(),
    lastCommentId: '',
    ...overrides,
  };
}

function share(db, gymId, overrides = {}) {
  const batch = db.batch();
  batch.update(
    db.collection('users').doc(ALICE).collection('proofs').doc(PROOF),
    {sharedWithGymId: gymId},
  );
  batch.set(
    db.collection('gyms').doc(gymId).collection('activity').doc(PROOF),
    activityData(gymId, ALICE, PROOF, overrides),
  );
  return batch.commit();
}

function comment(db, commentId, text, nextCount, authorId = BOB, displayName = 'Bob') {
  const activity = db.collection('gyms').doc(GYM_A).collection('activity').doc(PROOF);
  return db.runTransaction(async (tx) => {
    tx.update(activity, {commentCount: nextCount, lastCommentId: commentId});
    tx.set(activity.collection('comments').doc(commentId), {
      authorId,
      text,
      displayName,
      avatarUrl: '',
      createdAt: FieldValue.serverTimestamp(),
    });
    tx.set(activity.collection('commentRate').doc(authorId), {
      userId: authorId,
      lastAt: FieldValue.serverTimestamp(),
    });
  });
}
