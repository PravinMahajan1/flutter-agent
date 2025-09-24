import { Router } from 'express';
import { PrismaClient } from '@prisma/client';
import { z } from 'zod';

export const router = Router();
const prisma = new PrismaClient();

const analyticsQuery = z.object({
  studentId: z.string().optional(),
  subjectId: z.string().optional(),
  from: z.coerce.date().optional(),
  to: z.coerce.date().optional(),
});

router.get('/attendance', async (req, res) => {
  const parsed = analyticsQuery.safeParse(req.query);
  if (!parsed.success) return res.status(400).json(parsed.error.flatten());
  const { studentId, subjectId, from, to } = parsed.data;
  const sessions = await prisma.attendanceSession.findMany({
    where: { subjectId: subjectId ?? undefined, startsAt: from || to ? { gte: from ?? undefined, lte: to ?? undefined } : undefined },
    include: { attendances: studentId ? { where: { studentId } } : true },
  });
  const data = sessions.map(s => ({
    sessionId: s.id,
    subjectId: s.subjectId,
    type: s.type,
    totalMarked: s.attendances.length,
    startsAt: s.startsAt,
  }));
  res.json({ rows: data });
});

router.get('/attendance.csv', async (req, res) => {
  const parsed = analyticsQuery.safeParse(req.query);
  if (!parsed.success) return res.status(400).json(parsed.error.flatten());
  const { studentId, subjectId, from, to } = parsed.data;
  const sessions = await prisma.attendanceSession.findMany({
    where: { subjectId: subjectId ?? undefined, startsAt: from || to ? { gte: from ?? undefined, lte: to ?? undefined } : undefined },
    include: { attendances: studentId ? { where: { studentId } } : true },
  });
  const header = 'sessionId,subjectId,type,totalMarked,startsAt';
  const lines = sessions.map(s => `${s.id},${s.subjectId},${s.type},${s.attendances.length},${s.startsAt.toISOString()}`);
  const csv = [header, ...lines].join('\n');
  res.setHeader('Content-Type', 'text/csv');
  res.setHeader('Content-Disposition', 'attachment; filename="attendance-analytics.csv"');
  res.send(csv);
});