-- AlterTable
ALTER TABLE "Attendance" ADD COLUMN "deviceId" TEXT;

-- AlterTable
ALTER TABLE "AttendanceSession" ADD COLUMN "latitude" REAL;
ALTER TABLE "AttendanceSession" ADD COLUMN "longitude" REAL;
ALTER TABLE "AttendanceSession" ADD COLUMN "radiusMeters" INTEGER;

-- AlterTable
ALTER TABLE "User" ADD COLUMN "allowedDeviceId" TEXT;

-- CreateTable
CREATE TABLE "Result" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "studentId" TEXT NOT NULL,
    "subjectId" TEXT NOT NULL,
    "examType" TEXT NOT NULL,
    "marksObtained" REAL NOT NULL,
    "totalMarks" REAL NOT NULL,
    "grade" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "Result_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Result_subjectId_fkey" FOREIGN KEY ("subjectId") REFERENCES "Subject" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
