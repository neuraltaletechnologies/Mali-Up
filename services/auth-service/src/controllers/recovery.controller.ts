import { FastifyReply, FastifyRequest } from 'fastify';
import { RecoveryInput } from '../schemas/auth.schema.js';

export const recoveryHandler = async (
  request: FastifyRequest<{ Body: RecoveryInput }>,
  reply: FastifyReply
) => {
  const { phone } = request.body;
  const db = request.server.firestore;

  try {
    // Start the lookup
    const userSnapPromise = db
      .collection('users')
      .where('phone', '==', phone)
      .limit(1)
      .get();

    // Do other things while waiting if necessary...
    const userSnap = await userSnapPromise;

    if (userSnap.empty) {
      // For security, don't reveal if user exists or not
      return reply.status(200).send({ 
        message: 'If an account exists for this number, a recovery email has been sent.' 
      });
    }

    const userData = userSnap.docs[0].data();
    const realEmail = userData.email as string;
    
    // Obscure the email for display
    const obscuredEmail = realEmail.replace(/^(.)(.*)(@.*)$/, (_, a, b, c) => a + '*'.repeat(b.length) + c);

    return reply.status(200).send({
      message: 'Recovery email sent.',
      email: obscuredEmail,
    });
  } catch (error) {
    request.log.error(error);
    return reply.status(500).send({ message: 'Internal server error during recovery' });
  }
};
