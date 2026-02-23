import { Injectable } from '@nestjs/common';
import * as admin from 'firebase-admin';

@Injectable()
export class UserService {
  private db = admin.firestore();
  async getUserProfile(uid: string) {
    const doc = await this.db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  async updateUserProfile(
    uid: string,
    updateData: {
      email?: string;               // opcional
      name?: string;                 // opcional
      lastName?: string;              // opcional
      phone?: string;                 // opcional
      emergencyPhone?: string | null; // opcional y puede ser null
    },
  ) {
    const userRecord = await admin.auth().getUser(uid);

    const firestoreUpdate: any = {
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    const authUpdate: any = {};

    if (updateData.email !== undefined && updateData.email !== userRecord.email) {
      authUpdate.email = updateData.email;
      firestoreUpdate.email = updateData.email;
    }

    if (updateData.name !== undefined || updateData.lastName !== undefined) {
      const newName = updateData.name ?? userRecord.displayName?.split(' ')[0] ?? '';
      const newLastName = updateData.lastName ?? userRecord.displayName?.split(' ').slice(1).join(' ') ?? '';
      authUpdate.displayName = `${newName} ${newLastName}`.trim();
      if (updateData.name !== undefined) firestoreUpdate.name = updateData.name;
      if (updateData.lastName !== undefined) firestoreUpdate.lastName = updateData.lastName;
    }

    if (Object.keys(authUpdate).length > 0) {
      await admin.auth().updateUser(uid, authUpdate);
    }

    // Actualizar Firestore solo con los campos que llegaron
    if (updateData.phone !== undefined) firestoreUpdate.phone = updateData.phone;
    if (updateData.emergencyPhone !== undefined) {
      firestoreUpdate.emergencyPhone = updateData.emergencyPhone || null;
    }

    await this.db.collection('users').doc(uid).update(firestoreUpdate);

    return { message: 'Perfil actualizado correctamente' };
  }

  async createUser(data: {
    email: string;
    password: string;
    name: string;
    lastName: string;
    phone: string;
    emergencyPhone?: string | null;
  }) {
    const userRecord = await admin.auth().createUser({
      email: data.email,
      password: data.password,
      displayName: `${data.name} ${data.lastName}`,
    });

    await this.db.collection('users').doc(userRecord.uid).set({
      name: data.name,
      lastName: data.lastName,
      email: data.email,
      phone: data.phone,
      emergencyPhone: data.emergencyPhone || null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { message: 'Usuario creado correctamente' };
  }

  async login() {
    return { message: 'Login handled by Firebase Auth token' };
  }

  async logout() {
    return { message: 'Logout handled on client' };
  }

  async sendPasswordReset(email: string) {
    const link = await admin.auth().generatePasswordResetLink(email);
    return { message: 'Se ha enviado el correo de recuperación', link };
  }


  async notifyEmergencyContact(params: {
    userId: string;
    medicationName: string;
    dosis: string;
    scheduledTime: Date;
    minutosGracia: number;
  }) {
    const { userId, medicationName, dosis, scheduledTime, minutosGracia } = params;

    const userDoc = await this.db.collection('users').doc(userId).get();
    if (!userDoc.exists) throw new Error('Usuario no encontrado');

    const data = userDoc.data()!;
    const emergencyPhone = data.emergencyPhone as string | undefined;

    if (!emergencyPhone) return 'No hay contacto de emergencia registrado.';

    const elapsed = (new Date().getTime() - scheduledTime.getTime()) / 60000;
    if (elapsed < minutosGracia) return null; // No pasa tiempo de gracia aún

    const fullName = `${data.name} ${data.lastName ?? ''}`.trim();
    const message = `${fullName} no ha confirmado la toma del medicamento: ${medicationName} (${dosis}).`;

    await this.db
      .collection('users')
      .doc(userId)
      .collection('alertas_sms_pendientes')
      .add({
        to: emergencyPhone,
        body: message,
        medicationName,
        dosis,
        userName: fullName,
        horaLimite: admin.firestore.Timestamp.fromDate(scheduledTime),
        minutosGracia,
        type: 'sms',
        status: 'pending',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    return { message: 'Alerta guardada en cola de procesamiento' };
  }
  async saveFcmToken(userId: string, fcmToken: string) {
    await this.db.collection('users').doc(userId).update({
      fcmToken: fcmToken,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return { message: 'Token registrado correctamente' };
  }

  async getUserFcmToken(userId: string): Promise<string | null> {
    const userDoc = await this.db.collection('users').doc(userId).get();
    return userDoc.data()?.fcmToken || null;
  }
}
