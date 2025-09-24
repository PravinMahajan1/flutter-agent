import { Router } from 'express';
import { PrismaClient } from '@prisma/client';
import { z } from 'zod';
import { requireRole } from '../users/auth.js';
import { parse } from 'csv-parse/sync';

export const router = Router();
const prisma = new PrismaClient();

const createSchema = z.object({
  studentId: z.string().cuid(),
  subjectId: z.string().cuid(),
  examType: z.string().min(1),
  marksObtained: z.number(),
  totalMarks: z.number(),
  grade: z.string().optional(),
});

router.post('/', requireRole(['TEACHER', 'ADMIN']), async (req, res) => {
  const parsed = createSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json(parsed.error.flatten());
  const result = await prisma.result.create({ data: parsed.data });
  res.json(result);
});

const listQuery = z.object({
  studentId: z.string().optional(),
  subjectId: z.string().optional(),
  page: z.coerce.number().int().positive().default(1),
  pageSize: z.coerce.number().int().positive().max(100).default(20),
});

router.get('/', requireRole(['TEACHER', 'ADMIN', 'STUDENT']), async (req: any, res) => {
  const parsed = listQuery.safeParse(req.query);
  if (!parsed.success) return res.status(400).json(parsed.error.flatten());
  const { studentId, subjectId, page, pageSize } = parsed.data;
  const where = {
    studentId: req.user.role === 'STUDENT' ? req.user.sub : studentId ?? undefined,
    subjectId: subjectId ?? undefined,
  };
  const [total, rows] = await Promise.all([
    prisma.result.count({ where }),
    prisma.result.findMany({ where, skip: (page - 1) * pageSize, take: pageSize, orderBy: { createdAt: 'desc' } }),
  ]);
  res.json({ total, page, pageSize, rows });
});

router.get('/export.csv', requireRole(['TEACHER', 'ADMIN']), async (req, res) => {
  const parsed = listQuery.safeParse(req.query);
  if (!parsed.success) return res.status(400).json(parsed.error.flatten());
  const { studentId, subjectId } = parsed.data;
  const where = { studentId: studentId ?? undefined, subjectId: subjectId ?? undefined };
  const rows = await prisma.result.findMany({ where, orderBy: { createdAt: 'desc' } });
  const header = 'id,studentId,subjectId,examType,marksObtained,totalMarks,grade,createdAt';
  const csv = [header, ...rows.map(r => `${r.id},${r.studentId},${r.subjectId},${r.examType},${r.marksObtained},${r.totalMarks},${r.grade ?? ''},${r.createdAt.toISOString()}`)].join('\n');
  res.setHeader('Content-Type', 'text/csv');
  res.setHeader('Content-Disposition', 'attachment; filename="results.csv"');
  res.send(csv);
});

router.post('/import.csv', requireRole(['TEACHER', 'ADMIN']), async (req, res) => {
  let body = '';
  req.setEncoding('utf8');
  req.on('data', chunk => (body += chunk));
  req.on('end', async () => {
    try {
      const records = parse(body, { columns: true, skip_empty_lines: true });
      const toCreate = [] as any[];
      for (const r of records) {
        const parsed = createSchema.safeParse({
          studentId: r.studentId,
          subjectId: r.subjectId,
          examType: r.examType,
          marksObtained: Number(r.marksObtained),
          totalMarks: Number(r.totalMarks),
          grade: r.grade || undefined,
        });
        if (parsed.success) toCreate.push(parsed.data);
      }
      const created = await prisma.$transaction(toCreate.map(data => prisma.result.create({ data })));
      res.json({ created: created.length });
    } catch (e: any) {
      res.status(400).json({ message: e.message });
    }
  });
});