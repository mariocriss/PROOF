const assert = require('assert');
const fs = require('fs');
const path = require('path');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');

const RULES_PATH = path.resolve(__dirname, '../../firestore.rules');
const A = 'user_a';
const B = 'user_b';
let env;
const doc = () => `friend_${A}_${B}`;
const db = (uid) => env.authenticatedContext(uid).firestore();
const pending = {type: 'friend', status: 'pending', fromUserId: A, toUserId: B};

async function seed(data) {
  await env.withSecurityRulesDisabled((context) =>
    context.firestore().collection('relationships').doc(doc()).set(data),
  );
}

describe('friend relationship transitions', () => {
  before(async () => {
    env = await initializeTestEnvironment({
      projectId: 'proof-relationship-transitions',
      firestore: {rules: fs.readFileSync(RULES_PATH, 'utf8')},
    });
  });
  after(() => env.cleanup());
  beforeEach(() => env.clearFirestore());

  it('allows only the recipient to accept pending requests', async () => {
    await seed(pending);
    await assertSucceeds(db(B).collection('relationships').doc(doc()).update({
      status: 'accepted',
    }));
    await seed(pending);
    await assertFails(db(A).collection('relationships').doc(doc()).update({
      status: 'accepted',
    }));
  });

  it('allows either accepted participant to block themselves', async () => {
    await seed({...pending, status: 'accepted'});
    await assertSucceeds(db(A).collection('relationships').doc(doc()).update({
      status: 'blocked',
      blockedByUserId: A,
    }));
  });

  it('allows recipient to block while preserving identity fields', async () => {
    await seed({...pending, status: 'accepted'});
    await assertSucceeds(db(B).collection('relationships').doc(doc()).update({
      status: 'blocked',
      blockedByUserId: B,
    }));
  });

  it('denies unrelated users from updating relationships', async () => {
    await seed({...pending, status: 'accepted'});
    await assertFails(
      env.authenticatedContext('outsider').firestore()
        .collection('relationships').doc(doc()).update({status: 'declined'}),
    );
  });

  it('allows blocker to unblock via status transition to declined', async () => {
    await seed({...pending, status: 'blocked', blockedByUserId: B});
    await assertSucceeds(db(B).collection('relationships').doc(doc()).update({
      status: 'declined',
    }));
  });

  it('allows blocker to unblock by deleting the relationship', async () => {
    await seed({...pending, status: 'blocked', blockedByUserId: B});
    await assertSucceeds(
      db(B).collection('relationships').doc(doc()).delete(),
    );
  });

  it('denies blocked participant from deleting the block', async () => {
    await seed({...pending, status: 'blocked', blockedByUserId: B});
    await assertFails(
      db(A).collection('relationships').doc(doc()).delete(),
    );
  });

  it('denies unrelated users from deleting a blocked relationship', async () => {
    await seed({...pending, status: 'blocked', blockedByUserId: B});
    await assertFails(
      env.authenticatedContext('outsider').firestore()
        .collection('relationships').doc(doc()).delete(),
    );
  });

  it('denies blocked participant from transitioning blocked to declined', async () => {
    await seed({...pending, status: 'blocked', blockedByUserId: B});
    await assertFails(db(A).collection('relationships').doc(doc()).update({
      status: 'declined',
    }));
  });
});
