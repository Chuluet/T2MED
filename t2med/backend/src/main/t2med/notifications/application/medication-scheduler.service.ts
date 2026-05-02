import { Injectable } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import * as admin from 'firebase-admin';
import { NotificationsService } from './notification.service';

@Injectable()
export class MedicationSchedulerService {
  private db = admin.firestore();

  constructor(private readonly notificationsService: NotificationsService) {}

  @Cron(CronExpression.EVERY_MINUTE)
  async checkMedications(): Promise<void> {
    const now = new Date();
    const horaStr = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`;

    const usersSnapshot = await this.db.collection('users').get();

    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;

      const medicamentosSnapshot = await this.db
        .collection('users')
        .doc(userId)
        .collection('medicamentos')
        .where('hora', '==', horaStr)
        .get();

      if (medicamentosSnapshot.empty) continue;

      for (const doc of medicamentosSnapshot.docs) {
        const medData = doc.data();
        const fechaInicio = medData.fechaInicio ? new Date(medData.fechaInicio) : null;
        const fechaFin = medData.fechaFin ? new Date(medData.fechaFin) : null;
        const today = new Date();

        if (fechaInicio && fechaFin && today >= fechaInicio && today <= fechaFin) {
          await this.notificationsService.sendMedicationReminder(
            userId,
            medData.nombre,
            medData.dosis,
            now,
          );
        }
      }
    }
  }
}