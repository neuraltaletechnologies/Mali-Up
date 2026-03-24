import { FastifyReply, FastifyRequest } from 'fastify';
import bcrypt from 'bcrypt';
import { LoginInput, RegisterInput } from '../schemas/auth.schema.js';

export const registerHandler = async (
  request: FastifyRequest<{ Body: RegisterInput }>,
  reply: FastifyReply
) => {
  const { name, email, password, tenant_id, role } = request.body;

  const existingUser = await request.server.prisma.user.findUnique({
    where: { email },
  });

  if (existingUser) {
    return reply.status(409).send({ message: 'User already exists' });
  }

  const hashedPassword = await bcrypt.hash(password, 10);

  const user = await request.server.prisma.user.create({
    data: {
      name,
      email,
      password: hashedPassword,
      tenant_id,
      role,
    },
  });

  return reply.status(201).send({
    id: user.id,
    email: user.email,
    tenant_id: user.tenant_id,
  });
};

export const loginHandler = async (
  request: FastifyRequest<{ Body: LoginInput }>,
  reply: FastifyReply
) => {
  const { email, password } = request.body;

  const user = await request.server.prisma.user.findUnique({
    where: { email },
  });

  if (!user || user.active === false) {
    return reply.status(401).send({ message: 'Invalid credentials' });
  }

  const isPasswordValid = await bcrypt.compare(password, user.password);

  if (!isPasswordValid) {
    return reply.status(401).send({ message: 'Invalid credentials' });
  }

  const token = request.server.jwt.sign({
    id: user.id,
    email: user.email,
    tenant_id: user.tenant_id,
    role: user.role,
  });

  return reply.status(200).send({
    token,
    user: {
      id: user.id,
      email: user.email,
      name: user.name,
      tenant_id: user.tenant_id,
      role: user.role,
    },
  });
};
