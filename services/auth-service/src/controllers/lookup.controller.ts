import { FastifyReply, FastifyRequest } from 'fastify';
import { LookupInput } from '../schemas/auth.schema.js';

export const lookupHandler = async (
  request: FastifyRequest<{ Body: LookupInput }>,
  reply: FastifyReply
) => {
  const { phone } = request.body;
  const db = request.server.firestore;

  try {
    // Run independent lookups in parallel for better performance
    const [userSnap, inviteSnap, memberSnap] = await Promise.all([
      db.collection('users').where('phone', '==', phone).limit(1).get(),
      db.collection('pendingInvites')
        .where('phoneNumber', '==', phone)
        .where('status', '==', 'pending')
        .limit(1)
        .get(),
      db.collectionGroup('team_members').where('phone', '==', phone).limit(1).get(),
    ]);

    // 1. Process Returning User
    if (!userSnap.empty) {
      const userDoc = userSnap.docs[0];
      const userData = userDoc.data();
      const userId = userDoc.id;

      // Get business details
      const bizSnap = await db
        .collection('businesses')
        .where('ownerId', '==', userId)
        .limit(1)
        .get();

      let business = null;
      if (!bizSnap.empty) {
        const biz = bizSnap.docs[0].data();
        business = {
          id: bizSnap.docs[0].id,
          name: biz.businessName || '',
          type: biz.businessType || '',
        };
      }

      return reply.status(200).send({
        type: 'RETURNING_USER',
        user: {
          id: userId,
          name: userData.name || '',
          phone: userData.phone || phone,
          city: userData.city || '',
          role: userData.role || '',
        },
        business,
      });
    }

    // 2. Process Pending Invite
    if (!inviteSnap.empty) {
      const invite = inviteSnap.docs[0].data();
      return reply.status(200).send({
        type: 'TEAM_MEMBER_PENDING',
        invite: {
          id: inviteSnap.docs[0].id,
          memberId: invite.memberId || '',
          name: invite.fullName || '',
          role: invite.role || '',
          businessName: invite.businessName || '',
          ownerUid: invite.ownerUid || '',
          businessId: invite.businessId || '',
        },
      });
    }

    // 3. Process Legacy Team Member
    if (!memberSnap.empty) {
      const memberDoc = memberSnap.docs[0];
      const memberData = memberDoc.data();
      const pathSegments = memberDoc.ref.path.split('/');
      const ownerUid = pathSegments[1] || '';
      const bizId = pathSegments[3] || '';

      let businessName = '';
      if (ownerUid && bizId) {
        // Fetch business name
        const bizDoc = await db
          .collection('tenants')
          .doc(ownerUid)
          .collection('businesses')
          .doc(bizId)
          .get();
        businessName = bizDoc.data()?.businessName || '';
      }

      return reply.status(200).send({
        type: 'TEAM_MEMBER_PENDING',
        invite: {
          id: memberDoc.id,
          memberId: memberDoc.id,
          name: memberData.name || '',
          role: memberData.role || '',
          businessName,
          ownerUid,
          businessId: bizId,
        },
      });
    }

    return reply.status(200).send({ type: 'NEW_USER' });
  } catch (error) {
    request.log.error(error);
    return reply.status(500).send({ message: 'Internal server error during lookup' });
  }
};
