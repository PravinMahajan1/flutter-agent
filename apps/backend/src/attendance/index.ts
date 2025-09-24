import { Router } from 'express';
import { PrismaClient } from '@prisma/client';
import { z } from 'zod';
import crypto from 'node:crypto';
import { requireRole } from '../users/auth.js';

const prisma = new PrismaClient();
export const router = Router();

const sessionSchema = z.object({
  subjectId: z.string().cuid(),
  type: z.enum(['lecture', 'lab', 'library']),
  labNumber: z.number().int().positive().optional(),
  batch: z.string().optional(),
  durationMinutes: z.number().int().positive().max(240),
});

router.post('/session', requireRole(['TEACHER', 'ADMIN']), async (req, res) => {
  const parsed = sessionSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json(parsed.error.flatten());
  const { subjectId, type, labNumber, batch, durationMinutes } = parsed.data;
  const now = new Date();
  const expires = new Date(now.getTime() + durationMinutes * 60_000);
  const qrToken = crypto.randomUUID();
  const session = await prisma.attendanceSession.create({
    data: { subjectId, type, labNumber, batch, qrToken, startsAt: now, expiresAt: expires },
  });
  res.json({ sessionId: session.id, qrToken: session.qrToken, expiresAt: session.expiresAt });
});

const scanSchema = z.object({ token: z.string().uuid() });
router.post('/scan', requireRole(['STUDENT']), async (req: any, res) => {
  const parsed = scanSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json(parsed.error.flatten());
  const { token } = parsed.data;
  const session = await prisma.attendanceSession.findUnique({ where: { qrToken: token } });
  if (!session) return res.status(404).json({ message: 'Session not found' });
  if (session.expiresAt.getTime() < Date.now()) return res.status(410).json({ message: 'Session expired' });
  try {
    const attendance = await prisma.attendance.create({ data: { sessionId: session.id, studentId: req.user.sub } });
    res.json(attendance);
  } catch (e: any) {
    return res.status(409).json({ message: 'Already marked' });
  }
});

router.get('/session/:id/export', requireRole(['TEACHER', 'ADMIN']), async (req, res) => {
  const { id } = req.params;
  const rows = await prisma.attendance.findMany({
    where: { sessionId: id },
    include: { student: true, session: { include: { subject: true } } },
  });
  const csv = [
    'studentId,studentName,email,subject,sessionType,markedAt',
    ...rows.map(r => `${r.studentId},${JSON.stringify(r.student.fullName)},${r.student.email},${JSON.stringify(r.session.subject.name)},${r.session.type},${r.markedAt.toISOString()}`),
  ].join('\n');
  res.setHeader('Content-Type', 'text/csv');
  res.setHeader('Content-Disposition', 'attachment; filename="attendance.csv"');
  res.send(csv);
});

