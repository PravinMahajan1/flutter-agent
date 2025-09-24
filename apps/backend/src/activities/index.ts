import { Router } from 'express';
import { PrismaClient } from '@prisma/client';
import multer from 'multer';
import path from 'node:path';
import { z } from 'zod';
import { requireRole } from '../users/auth.js';

const prisma = new PrismaClient();
export const router = Router();

const createSchema = z.object({
  title: z.string().min(1),
  description: z.string().optional(),
  certificateEnabled: z.boolean().default(false),
});

const upload = multer({ dest: process.env.UPLOAD_DIR ?? './uploads' });

router.post('/', requireRole(['TEACHER', 'ADMIN']), async (req, res) => {
  const parsed = createSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json(parsed.error.flatten());
  const activity = await prisma.activity.create({ data: parsed.data });
  res.json(activity);
});

router.post('/:id/join', requireRole(['STUDENT']), async (req: any, res) => {
  const { id } = req.params;
  try {
    const participant = await prisma.activityParticipant.create({ data: { activityId: id, userId: req.user.sub } });
    res.json(participant);
  } catch (e) {
    res.status(409).json({ message: 'Already joined' });
  }
});

router.get('/:id/certificate', requireRole(['STUDENT', 'TEACHER', 'ADMIN']), async (req: any, res) => {
  const { id } = req.params;
  const ap = await prisma.activityParticipant.findFirst({ where: { activityId: id, userId: req.user.sub } });
  if (!ap || !ap.certificatePath) return res.status(404).json({ message: 'Certificate not available' });
  res.json({ url: ap.certificatePath });
});

router.post('/:id/certificate', requireRole(['TEACHER', 'ADMIN']), upload.single('file'), async (req, res) => {
  const { id } = req.params;
  if (!req.file) return res.status(400).json({ message: 'File required' });
  const { userId } = req.body as { userId?: string };
  if (!userId) return res.status(400).json({ message: 'userId required' });
  const filePath = path.join('/uploads', path.basename(req.file.path));
  const updated = await prisma.activityParticipant.update({
    where: { activityId_userId: { activityId: id, userId } },
    data: { certificatePath: filePath },
  });
  res.json(updated);
});

