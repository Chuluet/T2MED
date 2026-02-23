import { Injectable } from '@nestjs/common';
import * as admin from 'firebase-admin';
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class MedsService {
  private db = admin.firestore();
  constructor(
  private readonly notificationsService: NotificationsService,
) {}

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
    fechaStr: string,        
    horaProgramada: string,  
  ) {
    const historialRef = this.db
      .collection('users')
      .doc(userId)
      .collection('tomasHistorial')
      .doc(); 

    const data = {
      medicamentoId: medId,
      nombreMedicamento,
      estado,
      fecha: admin.firestore.Timestamp.fromDate(new Date()), 
      fechaStr,
      horaProgramada,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    await historialRef.set(data);
    
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
    .doc(medId)
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
  const inventoryRef = this.db
    .collection('users')
    .doc(userId)
    .collection('inventario')
    .doc(itemId);

  const doc = await inventoryRef.get();

  if (!doc.exists) {
    throw new Error('Item no encontrado');
  }

  const inventory = doc.data() as any;

  
  let nuevaCantidad = inventory.cantidad;

  if (data.cantidad !== undefined) {
    nuevaCantidad = data.cantidad;
  }

  await inventoryRef.update({
    ...data,
  });

  
  if (nuevaCantidad <= inventory.limiteBajo) {
    await this.notificationsService.sendLowStockNotification(
      userId,
      inventory.nombre,
      nuevaCantidad,
    );
  }

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