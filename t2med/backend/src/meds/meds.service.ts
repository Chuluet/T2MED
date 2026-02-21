import { Injectable } from '@nestjs/common';
import * as admin from 'firebase-admin';

@Injectable()
export class MedsService {
  private db = admin.firestore();

  // ==================== CRUD de medicamentos ====================

  async createMed(userId: string, data: any) {
    const medRef = await this.db
      .collection('users')
      .doc(userId)
      .collection('medicamentos')
      .add({
        ...data,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    return { id: medRef.id, message: 'Medicamento creado correctamente' };
  }

  async getMeds(userId: string) {
    const snapshot = await this.db
      .collection('users')
      .doc(userId)
      .collection('medicamentos')
      .orderBy('createdAt', 'desc')
      .get();
    return snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
    }));
  }

  async updateMed(userId: string, medId: string, data: any) {
    await this.db
      .collection('users')
      .doc(userId)
      .collection('medicamentos')
      .doc(medId)
      .update(data);
    return { message: 'Medicamento actualizado correctamente' };
  }

  async deleteMed(userId: string, medId: string) {
    await this.db
      .collection('users')
      .doc(userId)
      .collection('medicamentos')
      .doc(medId)
      .delete();
    return { message: 'Medicamento eliminado correctamente' };
  }

  // ==================== Gestión de tomas (historial global) ====================

  async registrarToma(
    userId: string,
    medId: string,
    nombreMedicamento: string,
    estado: string,
    fechaStr: string,        // formato 'YYYY-MM-DD'
    horaProgramada: string,   // hora del medicamento
  ) {
    const historialRef = this.db
      .collection('users')
      .doc(userId)
      .collection('tomasHistorial')
      .doc(); // ID automático

    const data = {
      medicamentoId: medId,
      nombreMedicamento,
      estado,
      fecha: admin.firestore.Timestamp.fromDate(new Date()), // momento de la acción
      fechaStr,
      horaProgramada,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    await historialRef.set(data);
    return { message: 'Toma registrada correctamente' };
  }

  async obtenerTomaDelDia(userId: string, medId: string, fechaStr: string) {
    const snapshot = await this.db
      .collection('users')
      .doc(userId)
      .collection('tomasHistorial')
      .where('medicamentoId', '==', medId)
      .where('fechaStr', '==', fechaStr)
      .limit(1)
      .get();

    if (snapshot.empty) return null;
    return { id: snapshot.docs[0].id, ...snapshot.docs[0].data() };
  }

  async obtenerHistorial(userId: string) {
    const snapshot = await this.db
      .collection('users')
      .doc(userId)
      .collection('tomasHistorial')
      .orderBy('fecha', 'desc')
      .get();

    return snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
    }));
  }
}