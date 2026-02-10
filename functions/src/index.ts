import { setGlobalOptions } from "firebase-functions/v2";
import { onRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";

import * as admin from "firebase-admin";
import axios from "axios";
import Busboy from "busboy";
import FormData from "form-data";
import { randomUUID } from "crypto";

admin.initializeApp({
  // ✅ Your actual bucket from Firebase Console
  storageBucket: "futureyou-4124d.firebasestorage.app",
});

/* ---------------- GLOBAL OPTIONS ---------------- */
setGlobalOptions({
  region: "asia-south1",
  maxInstances: 10,
});

/* ---------------- CONFIG ---------------- */
// Swagger: POST /export_pdf_from_files
const WRAPPER_URL =
  "https://medxern-wrapper-714043644019.asia-south1.run.app/export_pdf_from_files";

// Secret Manager secret name
const WRAPPER_SECRET = defineSecret("MEDXERN_WRAPPER_SECRET");

/* ---------------- TYPES ---------------- */
type UploadedFile = {
  filename: string;
  mime: string;
  buffer: Buffer;
};

/* ---------------- HELPERS ---------------- */
async function requireAuth(req: any): Promise<string> {
  const authHeader = req.headers.authorization || "";
  const match = authHeader.match(/^Bearer (.+)$/);
  if (!match) throw { status: 401, message: "Missing Authorization header" };

  const decoded = await admin.auth().verifyIdToken(match[1]);
  return decoded.uid;
}

function assertMultipart(req: any) {
  const ct = (req.headers["content-type"] || "").toString();
  const ctLower = ct.toLowerCase();

  if (!ctLower.startsWith("multipart/form-data")) {
    throw { status: 400, message: "Content-Type must be multipart/form-data" };
  }
  if (!ctLower.includes("boundary=")) {
    throw { status: 400, message: "Missing multipart boundary" };
  }

  // rawBody is required for bb.end(rawBody)
  if (!req.rawBody) {
    throw { status: 400, message: "Missing rawBody in request" };
  }
}

/**
 * Gen-2 hardened multipart parser:
 * - Uses req.rawBody + bb.end(rawBody) instead of req.pipe(bb)
 * - Avoids "Unexpected end of form" from truncated streams
 */
function readMultipartFiles(req: any): Promise<UploadedFile[]> {
  return new Promise((resolve, reject) => {
    try {
      assertMultipart(req);

      const bb = Busboy({
        headers: req.headers,
        limits: {
          files: 10,
          fileSize: 20 * 1024 * 1024, // 20MB per file
        },
      });

      const files: UploadedFile[] = [];
      const filePromises: Promise<void>[] = [];

      bb.on("file", (fieldname, file, info) => {
        // Accept only 'files' field
        if (fieldname !== "files") {
          file.resume();
          return;
        }

        const filename = info?.filename || "upload.pdf";
        const mime = info?.mimeType || "application/pdf";

        const p = new Promise<void>((resFile, rejFile) => {
          const chunks: Buffer[] = [];

          file.on("data", (d: Buffer) => chunks.push(d));

          file.on("limit", () => {
            rejFile({ status: 413, message: `File too large: ${filename}` });
          });

          file.on("error", (e: any) => {
            rejFile({
              status: 400,
              message: `File stream error: ${e?.message || e}`,
            });
          });

          file.on("end", () => {
            files.push({
              filename,
              mime,
              buffer: Buffer.concat(chunks),
            });
            resFile();
          });
        });

        filePromises.push(p);
      });

      bb.on("error", (e: any) => {
        reject({
          status: 400,
          message: `Busboy error: ${e?.message || e}`,
        });
      });

      bb.on("finish", async () => {
        try {
          await Promise.all(filePromises);
          resolve(files);
        } catch (e) {
          reject(e);
        }
      });

      // ✅ KEY FIX: feed busboy from rawBody buffer (NOT streaming pipe)
      bb.end(req.rawBody);
    } catch (e) {
      reject(e);
    }
  });
}

/* ---------------- MAIN FUNCTION ---------------- */
export const processMedicalFiles = onRequest(
  {
    secrets: [WRAPPER_SECRET],
    memory: "1GiB",
    timeoutSeconds: 300,
    cors: true,
  },
  async (req, res) => {
    try {
      if (req.method !== "POST") {
        res.status(405).send("Method Not Allowed");
        return;
      }

      /* 1) Auth */
      const uid = await requireAuth(req);

      /* 2) Parse uploaded PDFs */
      const files = await readMultipartFiles(req);
      if (!files.length) {
        res.status(400).json({
          error: "No files uploaded (field must be 'files')",
        });
        return;
      }

      /* 3) Read Secret */
      const secret = process.env.MEDXERN_WRAPPER_SECRET;
      if (!secret) {
        logger.error(
          "Wrapper secret missing (MEDXERN_WRAPPER_SECRET not in env)"
        );
        res.status(500).json({ error: "Server misconfiguration" });
        return;
      }

      /* 4) Forward to Wrapper */
      const form = new FormData();
      for (const f of files) {
        form.append("files", f.buffer, {
          filename: f.filename,
          contentType: f.mime,
        });
      }

      const wrapperResp = await axios.post<ArrayBuffer>(WRAPPER_URL, form, {
        headers: {
          ...form.getHeaders(),
          // ✅ Must match Swagger
          "x-wrapper-secret": secret,
        },
        responseType: "arraybuffer",
        maxBodyLength: Infinity,
        maxContentLength: Infinity,
        timeout: 300000,
        validateStatus: () => true,
      });

      if (wrapperResp.status < 200 || wrapperResp.status >= 300) {
        logger.error("Wrapper failed", {
          status: wrapperResp.status,
          bytes:
            wrapperResp.data instanceof ArrayBuffer
              ? wrapperResp.data.byteLength
              : -1,
        });

        res.status(502).json({
          error: "Wrapper failed",
          status: wrapperResp.status,
        });
        return;
      }

      const pdfBuffer = Buffer.from(wrapperResp.data);
      if (!pdfBuffer || pdfBuffer.length < 100) {
        res.status(502).json({ error: "Wrapper returned empty/invalid PDF" });
        return;
      }

      /* 5) Save PDF to Firebase Storage (Fix A: download token URL) */
      const bucket = admin.storage().bucket();
      const fileName = `medical_${Date.now()}.pdf`;
      const storagePath = `users/${uid}/medical_outputs/${fileName}`;
      const fileRef = bucket.file(storagePath);

      // ✅ Token avoids IAM signBlob requirement
      const token = randomUUID();

      await fileRef.save(pdfBuffer, {
        contentType: "application/pdf",
        resumable: false,
        metadata: {
          cacheControl: "private, max-age=3600",
          metadata: {
            firebaseStorageDownloadTokens: token,
          },
        },
      });

      const encodedPath = encodeURIComponent(storagePath);
      const downloadUrl = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodedPath}?alt=media&token=${token}`;

      /* 6) Save Firestore timeline entry */
      const docRef = await admin
        .firestore()
        .collection("users")
        .doc(uid)
        .collection("medicalTimeline")
        .add({
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          title: "AI Medical Summary",
          eventType: "document",
          aiProcessed: true,
          sourceDocument: {
            fileUrl: downloadUrl,
            storagePath,
            fileName,
            token, // optional, helpful for debugging
            originalFiles: files.map((f) => ({
              filename: f.filename,
              mime: f.mime,
              bytes: f.buffer.length,
            })),
          },
        });

      /* 7) Return to Flutter */
      res.status(200).json({
        ok: true,
        timelineEventId: docRef.id,
        pdfUrl: downloadUrl,
      });
      return;
    } catch (err: any) {
      logger.error("processMedicalFiles failed", err);
      res.status(err?.status || 500).json({
        error: err?.message || "Internal error",
      });
      return;
    }
  }
);
