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
    // 🔽 Restar 1 del inventario
const inventarioRef = this.db
  .collection('users')
  .doc(userId)
  .collection('inventario')
  .doc(medId);

const inventarioDoc = await inventarioRef.get();

if (inventarioDoc.exists) {
  await inventarioRef.update({
    cantidad: admin.firestore.FieldValue.increment(-1),
  });
}
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

  // ==================== INVENTARIO ====================

async createInventoryItem(userId: string, data: any) {
  const { medId, ...rest } = data;

  await this.db
    .collection('users')
    .doc(userId)
    .collection('inventario')
    .doc(medId) // 👈 usamos el mismo ID del medicamento
    .set({
      ...rest,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

  return { message: 'Inventario creado correctamente' };
}

async getInventory(userId: string) {
  const snapshot = await this.db
    .collection('users')
    .doc(userId)
    .collection('inventario')
    .orderBy('createdAt', 'desc')
    .get();

  return snapshot.docs.map(doc => ({
    id: doc.id,
    ...doc.data(),
  }));
}

async updateInventoryItem(userId: string, itemId: string, data: any) {
  await this.db
    .collection('users')
    .doc(userId)
    .collection('inventario')
    .doc(itemId)
    .update(data);

  return { message: 'Inventario actualizado correctamente' };
}

async deleteInventoryItem(userId: string, itemId: string) {
  await this.db
    .collection('users')
    .doc(userId)
    .collection('inventario')
    .doc(itemId)
    .delete();

  return { message: 'Item eliminado del inventario' };
}
}