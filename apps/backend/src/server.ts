import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import path from 'node:path';
import fs from 'node:fs';
import rateLimit from 'express-rate-limit';
import { router as authRouter } from './users/auth.js';
import { router as subjectsRouter } from './subjects/index.js';
import { router as attendanceRouter } from './attendance/index.js';
import { router as assignmentsRouter } from './assignments/index.js';
import { router as leavesRouter } from './leaves/index.js';
import { router as activitiesRouter } from './activities/index.js';
import { router as resultsRouter } from './results/index.js';
import { router as analyticsRouter } from './stats/index.js';
import { router as adminRouter } from './admin/index.js';

const app = express();
app.use(cors());
app.use(helmet());
app.use(express.json({ limit: '5mb' }));
app.use(express.urlencoded({ extended: true }));
const limiter = rateLimit({ windowMs: 60_000, max: 120 });
app.use(limiter);

const uploadDir = process.env.UPLOAD_DIR ?? './uploads';
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}
app.use('/uploads', express.static(path.resolve(uploadDir)));

app.get('/health', (_req, res) => {
  res.json({ ok: true });
});

app.use('/api/auth', authRouter);
app.use('/api/subjects', subjectsRouter);
app.use('/api/attendance', attendanceRouter);
app.use('/api/assignments', assignmentsRouter);
app.use('/api/leaves', leavesRouter);
app.use('/api/activities', activitiesRouter);
app.use('/api/results', resultsRouter);
app.use('/api/analytics', analyticsRouter);
app.use('/api/admin', adminRouter);

const port = Number(process.env.PORT ?? 3000);
app.listen(port, () => {
  console.log(`API listening on http://localhost:${port}`);
});

