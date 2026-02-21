// notifications.service.ts
import { Injectable } from '@nestjs/common';
import * as admin from 'firebase-admin';
import { UserService } from '../users/user.service';
@Injectable()
export class NotificationsService {
  constructor(private readonly userService: UserService) {}
  async sendMedicationReminder(
    userId: string,
    medicationName: string,
    dosis: string,
    scheduledTime: Date,
  ) {
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
        medicationId: 'opcional',
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
}