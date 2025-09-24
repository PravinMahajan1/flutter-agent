import { Router } from 'express';
import { PrismaClient } from '@prisma/client';
import { z } from 'zod';
import { requireRole } from '../users/auth.js';

export const router = Router();
const prisma = new PrismaClient();

const listQuery = z.object({ page: z.coerce.number().int().positive().default(1), pageSize: z.coerce.number().int().positive().max(100).default(20), role: z.string().optional() });
router.get('/users', requireRole(['ADMIN']), async (req, res) => {
  const parsed = listQuery.safeParse(req.query);
  if (!parsed.success) return res.status(400).json(parsed.error.flatten());
  const { page, pageSize, role } = parsed.data;
  const where = { role: role ?? undefined };
  const [total, users] = await Promise.all([
    prisma.user.count({ where }),
    prisma.user.findMany({ where, skip: (page - 1) * pageSize, take: pageSize, orderBy: { createdAt: 'desc' }, select: { id: true, email: true, fullName: true, role: true, createdAt: true } }),
  ]);
  res.json({ total, page, pageSize, users });
});

const updateRoleSchema = z.object({ role: z.enum(['STUDENT', 'TEACHER', 'ADMIN']) });
router.post('/users/:id/role', requireRole(['ADMIN']), async (req, res) => {
  const parsed = updateRoleSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json(parsed.error.flatten());
  const user = await prisma.user.update({ where: { id: req.params.id }, data: { role: parsed.data.role } });
  res.json({ id: user.id, role: user.role });
});