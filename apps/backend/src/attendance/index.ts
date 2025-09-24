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
  latitude: z.number().optional(),
  longitude: z.number().optional(),
  radiusMeters: z.number().int().positive().optional(),
});

router.post('/session', requireRole(['TEACHER', 'ADMIN']), async (req, res) => {
  const parsed = sessionSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json(parsed.error.flatten());
  const { subjectId, type, labNumber, batch, durationMinutes, latitude, longitude, radiusMeters } = parsed.data;
  const now = new Date();
  const expires = new Date(now.getTime() + durationMinutes * 60_000);
  const qrToken = crypto.randomUUID();
  const session = await prisma.attendanceSession.create({
    data: { subjectId, type, labNumber, batch, qrToken, startsAt: now, expiresAt: expires, latitude, longitude, radiusMeters },
  });
  res.json({ sessionId: session.id, qrToken: session.qrToken, expiresAt: session.expiresAt });
});

const scanSchema = z.object({ token: z.string().uuid(), deviceId: z.string().optional(), lat: z.number().optional(), lon: z.number().optional() });
router.post('/scan', requireRole(['STUDENT']), async (req: any, res) => {
  const parsed = scanSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json(parsed.error.flatten());
  const { token, deviceId, lat, lon } = parsed.data;
  const session = await prisma.attendanceSession.findUnique({ where: { qrToken: token } });
  if (!session) return res.status(404).json({ message: 'Session not found' });
  if (session.expiresAt.getTime() < Date.now()) return res.status(410).json({ message: 'Session expired' });

  // Device binding: if user has allowedDeviceId, must match; else first device bind
  const user = await prisma.user.findUnique({ where: { id: req.user.sub } });
  if (!user) return res.status(401).json({ message: 'User not found' });
  if (user.allowedDeviceId) {
    if (deviceId && user.allowedDeviceId !== deviceId) return res.status(403).json({ message: 'Device mismatch' });
  } else if (deviceId) {
    await prisma.user.update({ where: { id: user.id }, data: { allowedDeviceId: deviceId } });
  }

  // Geofencing if configured
  if (session.latitude != null && session.longitude != null && session.radiusMeters != null) {
    if (lat == null || lon == null) return res.status(400).json({ message: 'Location required' });
    const distance = haversine(session.latitude, session.longitude, lat, lon);
    if (distance > session.radiusMeters) return res.status(403).json({ message: 'Outside allowed area' });
  }

  try {
    const attendance = await prisma.attendance.create({ data: { sessionId: session.id, studentId: req.user.sub, deviceId } });
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

function haversine(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const toRad = (d: number) => (d * Math.PI) / 180;
  const R = 6371000;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a = Math.sin(dLat / 2) ** 2 + Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

