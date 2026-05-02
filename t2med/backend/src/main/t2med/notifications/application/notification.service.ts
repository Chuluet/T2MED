import { Injectable } from '@nestjs/common';
import * as admin from 'firebase-admin';
import { UserService } from '../../users/application/user.service';

@Injectable()
export class NotificationsService {
  constructor(private readonly userService: UserService) {}

  async sendMedicationReminder(
    userId: string,
    medicationName: string,
    dosis: string,
    scheduledTime: Date,
  ): Promise<void> {
    const fcmToken = await this.userService.getUserFcmToken(userId);
    if (!fcmToken) {
      console.log(`Usuario ${userId} no tiene token FCM registrado`);
      return;
    }

    const message = {
      token: fcmToken,
      notification: {
        title: '💊 Recordatorio de Medicamento',
        body: `Es hora de tomar ${medicationName} (${dosis})`,
      },
      data: {
        type: 'medication_reminder',
        scheduledTime: scheduledTime.toISOString(),
      },
    };

    try {
      const response = await admin.messaging().send(message);
      console.log('Notificación enviada:', response);
    } catch (error) {
      console.error('Error enviando notificación:', error);
    }
  }

  async sendLowStockNotification(
    userId: string,
    medicationName: string,
    cantidadRestante: number,
  ): Promise<void> {
    const fcmToken = await this.userService.getUserFcmToken(userId);
    if (!fcmToken) {
      console.log(`Usuario ${userId} no tiene token FCM registrado`);
      return;
    }

    const message = {
      token: fcmToken,
      notification: {
        title: '⚠️ Inventario Bajo',
        body: `Te quedan solo ${cantidadRestante} pastillas de ${medicationName}`,
      },
      data: {
        type: 'low_stock_alert',
        medicationName,
        cantidadRestante: cantidadRestante.toString(),
      },
    };

    try {
      const response = await admin.messaging().send(message);
      console.log('Notificación de inventario enviada:', response);
    } catch (error) {
      console.error('Error enviando notificación de inventario:', error);
    }
  }

  async notifyEmergencyContact(params: {
    userId: string;
    medicationName: string;
    dosis: string;
    scheduledTime: Date;
    minutosGracia: number;
  }): Promise<{ message: string } | string | null> {
    const { userId, medicationName, dosis, scheduledTime, minutosGracia } = params;

    const user = await this.userService.getUserProfile(userId);
    if (!user) throw new Error('Usuario no encontrado');
    if (!user.emergencyPhone) return 'No hay contacto de emergencia registrado.';

    const elapsed = (new Date().getTime() - scheduledTime.getTime()) / 60000;
    if (elapsed < minutosGracia) return null;

    const fullName = `${user.name} ${user.lastName ?? ''}`.trim();
    const db = admin.firestore();

    await db.collection('users').doc(userId).collection('alertas_sms_pendientes').add({
      to: user.emergencyPhone,
      body: `${fullName} no ha confirmado la toma del medicamento: ${medicationName} (${dosis}).`,
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
}