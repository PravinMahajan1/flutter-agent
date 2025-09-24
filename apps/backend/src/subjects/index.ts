import { Router } from 'express';
import { PrismaClient } from '@prisma/client';
import { z } from 'zod';
import { requireRole } from '../users/auth.js';

const prisma = new PrismaClient();
export const router = Router();

const subjectSchema = z.object({
  name: z.string().min(1),
  code: z.string().min(1),
  academicYear: z.string().min(1),
  division: z.string().min(1),
  teacherId: z.string().cuid().optional(),
});

router.post('/', requireRole(['TEACHER', 'ADMIN']), async (req, res) => {
  const parsed = subjectSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json(parsed.error.flatten());
  const subject = await prisma.subject.create({ data: parsed.data });
  res.json(subject);
});

router.get('/', async (_req, res) => {
  const subjects = await prisma.subject.findMany({ include: { teacher: true } });
  res.json(subjects);
});

