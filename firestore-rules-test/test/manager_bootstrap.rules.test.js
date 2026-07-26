const fs = require('fs');
const path = require('path');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');

const RULES_PATH = path.resolve(__dirname, '../../firestore.rules');
const OWNER = 'gym_owner';
const ATTACKER = 'attacker_uid';
const GYM = 'gym_owned_by_owner';

describe('manager bootstrap security', () => {
  /** @type {import('@firebase/rules-unit-testing').RulesTestEnvironment} */
  let env;

  before(async () => {
    env = await initializeTestEnvironment({
      projectId: 'proof-manager-bootstrap',
      firestore: {rules: fs.readFileSync(RULES_PATH, 'utf8')},
    });
  });

  after(() => env.cleanup());
  beforeEach(() => env.clearFirestore());

  it('allows gym creator to bootstrap own manager membership', async () => {
    await env.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('gyms').doc(GYM).set({
        createdBy: OWNER,
        name: 'Test Gym',
      });
    });

    const id = `${GYM}_${OWNER}_manager`;
    await assertSucceeds(
      env.authenticatedContext(OWNER).firestore()
        .collection('gymMemberships').doc(id).set({
          gymId: GYM,
          userId: OWNER,
          membershipType: 'manager',
          status: 'approved',
        }),
    );
  });

  it('denies becoming manager of another users gym', async () => {
    await env.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('gyms').doc(GYM).set({
        createdBy: OWNER,
        name: 'Test Gym',
      });
    });

    const id = `${GYM}_${ATTACKER}_manager`;
    await assertFails(
      env.authenticatedContext(ATTACKER).firestore()
        .collection('gymMemberships').doc(id).set({
          gymId: GYM,
          userId: ATTACKER,
          membershipType: 'manager',
          status: 'approved',
        }),
    );
  });
});
