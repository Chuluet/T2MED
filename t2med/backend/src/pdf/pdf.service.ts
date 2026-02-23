import { Injectable } from '@nestjs/common';
import * as admin from 'firebase-admin';
import PDFDocument from 'pdfkit';
import fetch from 'node-fetch';
import { PassThrough } from 'stream';

@Injectable()
export class PdfService {
  private db = admin.firestore();
  private cloudFunctionUrl = 'https://us-central1-t2med-9a1a5.cloudfunctions.net/sendEmail';

  async generateAndSendPdf(userId: string, email: string) {
    const historialSnapshot = await this.db
      .collection('users')
      .doc(userId)
      .collection('tomasHistorial')
      .orderBy('fecha', 'desc')
      .get();

    const tomas = historialSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
    }));

    const pdfBuffer = await this.generatePdfBuffer(tomas);
    const pdfBase64 = pdfBuffer.toString('base64');
    await this.callCloudFunction(email, pdfBase64);
    return { message: 'PDF enviado correctamente' };
  }

  private async generatePdfBuffer(tomas: any[]): Promise<Buffer> {
    return new Promise((resolve) => {
      const doc = new PDFDocument({ size: 'A4', margin: 40 });
      const stream = new PassThrough();
      const buffers: Buffer[] = [];

      doc.pipe(stream);
      stream.on('data', buffers.push.bind(buffers));

      doc.fontSize(24).font('Helvetica-Bold').text('Historial de Tomas', { align: 'left' });

      doc.fontSize(12).font('Helvetica').text(`Generado el: ${new Date().toLocaleDateString('es-ES')}`, { align: 'right' });
      doc.moveDown(2);

      const tableTop = doc.y;
      const colWidths = [140, 90, 85, 80, 120];

      const headers = ['Medicamento', 'Fecha', 'Hora de Toma', 'Estado', 'Hora Programada'];

      doc.rect(32, tableTop, doc.page.width - 64, 20).fill('#D3D3D3').fillColor('black');

      doc.fontSize(10).font('Helvetica-Bold');

      let x = 32;
      headers.forEach((header, i) => {
        doc.text(header, x + 5, tableTop + 5, { width: colWidths[i] });
        x += colWidths[i];
      });
      let y = tableTop + 25;
      doc.font('Helvetica').fontSize(10);

      tomas.forEach((toma) => {
        const fecha = toma.fecha?.toDate ? toma.fecha.toDate() : new Date(toma.fecha);
        const fechaStr = fecha.toLocaleDateString('es-ES');
        const horaStr = fecha.toLocaleTimeString('es-ES', { hour: '2-digit', minute: '2-digit' });

        const row = [
          toma.nombreMedicamento || 'Medicamento',
          fechaStr,
          horaStr,
          toma.estado || 'Pendiente',
          toma.horaProgramada || 'N/A'
        ];

        x = 32;

        row.forEach((cell, i) => {
          doc.text(cell, x + 5, y, { width: colWidths[i] });
          x += colWidths[i];
        });
        y += 20;
      });

      doc.end();

      stream.on('end', () => {
        resolve(Buffer.concat(buffers));
      });
    });
  }

  private async callCloudFunction(email: string, pdfBase64: string) {
    const payload = {
      data: {
        to: email,
        pdfBase64: pdfBase64,
        subject: 'Historial de Tomas de Medicamentos',
        body: 'Adjunto encontrarás tu historial de tomas de medicamentos.',
      },
    };
    try {
      const response = await fetch(this.cloudFunctionUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`Error en Cloud Function: ${response.status} - ${errorText}`);
      }
    } catch (error) {
      console.error('Error calling cloud function:', error);
      throw new Error('No se pudo enviar el correo. Intente más tarde.');
    }
  }
}