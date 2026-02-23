import { Injectable } from '@nestjs/common';
import * as admin from 'firebase-admin';

@Injectable()
export class AppointmentsService {
    private db = admin.firestore();

    // ==================== CRUD de citas ====================

    async createAppointment(userId: string, data: any) {
        const appointmentRef = await this.db
            .collection('users')
            .doc(userId)
            .collection('citas')
            .add({
                ...data,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });

        return {
            id: appointmentRef.id,
            message: 'Cita creada correctamente',
        };
    }

    async getAppointments(userId: string) {
        const snapshot = await this.db
            .collection('users')
            .doc(userId)
            .collection('citas')
            .orderBy('fecha', 'asc') // ordenadas por fecha
            .get();

        return snapshot.docs.map(doc => ({
            id: doc.id,
            ...doc.data(),
        }));
    }

    async updateAppointment(userId: string, appointmentId: string, data: any) {
        await this.db
            .collection('users')
            .doc(userId)
            .collection('citas')
            .doc(appointmentId)
            .update(data);

        return { message: 'Cita actualizada correctamente' };
    }

    async deleteAppointment(userId: string, appointmentId: string) {
        await this.db
            .collection('users')
            .doc(userId)
            .collection('citas')
            .doc(appointmentId)
            .delete();

        return { message: 'Cita eliminada correctamente' };
    }
}