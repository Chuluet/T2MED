import { Injectable } from '@nestjs/common';
import * as admin from 'firebase-admin';
import { Appointment } from '../../domain/appointment.entity';

@Injectable()
export class AppointmentRepository {
  private db = admin.firestore();

  async create(userId: string, data: Partial<Appointment>): Promise<string> {
    const ref = await this.db
      .collection('users')
      .doc(userId)
      .collection('citas')
      .add({
        ...data,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    return ref.id;
  }

  async findAll(userId: string): Promise<Appointment[]> {
    const snapshot = await this.db
      .collection('users')
      .doc(userId)
      .collection('citas')
      .orderBy('fecha', 'asc')
      .get();

    return snapshot.docs.map(doc => ({
      id: doc.id,
      userId,
      ...doc.data(),
    } as Appointment));
  }

  async update(userId: string, appointmentId: string, data: Partial<Appointment>): Promise<void> {
    await this.db
      .collection('users')
      .doc(userId)
      .collection('citas')
      .doc(appointmentId)
      .update({
        ...data,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
  }

  async delete(userId: string, appointmentId: string): Promise<void> {
    await this.db
      .collection('users')
      .doc(userId)
      .collection('citas')
      .doc(appointmentId)
      .delete();
  }
}