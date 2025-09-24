import { Router } from 'express';
import { PrismaClient } from '@prisma/client';
import multer from 'multer';
import path from 'node:path';
import { z } from 'zod';
import { requireRole } from '../users/auth.js';

const prisma = new PrismaClient();
export const router = Router();
const upload = multer({ dest: process.env.UPLOAD_DIR ?? './uploads' });

const leaveSchema = z.object({
  fromDate: z.coerce.date(),
  toDate: z.coerce.date(),
  reason: z.string().min(1),
});

router.post('/', requireRole(['STUDENT']), upload.single('attachment'), async (req: any, res) => {
  const parsed = leaveSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json(parsed.error.flatten());
  const attachmentPath = req.file ? path.join('/uploads', path.basename(req.file.path)) : null;
  const leave = await prisma.leaveApplication.create({
    data: { ...parsed.data, studentId: req.user.sub, attachmentPath: attachmentPath ?? undefined },
  });
  res.json(leave);
});

router.get('/', requireRole(['STUDENT', 'TEACHER', 'ADMIN']), async (req: any, res) => {
  if (req.user.role === 'STUDENT') {
    const mine = await prisma.leaveApplication.findMany({ where: { studentId: req.user.sub } });
    return res.json(mine);
  }
  const all = await prisma.leaveApplication.findMany({ include: { student: true } });
  res.json(all);
});

const reviewSchema = z.object({ status: z.enum(['PENDING', 'APPROVED', 'REJECTED']) });
router.post('/:id/review', requireRole(['TEACHER', 'ADMIN']), async (req: any, res) => {
  const { id } = req.params;
  const parsed = reviewSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json(parsed.error.flatten());
  const updated = await prisma.leaveApplication.update({
    where: { id },
    data: { status: parsed.data.status, reviewedBy: { connect: { id: req.user.sub } }, reviewedAt: new Date() },
  });
  res.json(updated);
});

