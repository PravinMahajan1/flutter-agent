import { Router } from 'express';
import { PrismaClient } from '@prisma/client';
import multer from 'multer';
import path from 'node:path';
import { z } from 'zod';
import { requireRole } from '../users/auth.js';

const prisma = new PrismaClient();
export const router = Router();

const upload = multer({ dest: process.env.UPLOAD_DIR ?? './uploads' });

const createAssignmentSchema = z.object({
  subjectId: z.string().cuid(),
  title: z.string().min(1),
  description: z.string().optional(),
  dueAt: z.coerce.date(),
});

router.post('/', requireRole(['TEACHER', 'ADMIN']), async (req, res) => {
  const parsed = createAssignmentSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json(parsed.error.flatten());
  const assignment = await prisma.assignment.create({ data: parsed.data });
  res.json(assignment);
});

router.post('/:id/submit', requireRole(['STUDENT']), upload.single('file'), async (req: any, res) => {
  const { id } = req.params;
  if (!req.file) return res.status(400).json({ message: 'File required' });
  const filePath = path.join('/uploads', path.basename(req.file.path));
  try {
    const submission = await prisma.assignmentSubmission.create({ data: { assignmentId: id, studentId: req.user.sub, filePath } });
    res.json(submission);
  } catch (e) {
    return res.status(409).json({ message: 'Already submitted' });
  }
});

router.get('/:id/submissions', requireRole(['TEACHER', 'ADMIN']), async (req, res) => {
  const { id } = req.params;
  const submissions = await prisma.assignmentSubmission.findMany({ where: { assignmentId: id }, include: { student: true } });
  res.json(submissions);
});

