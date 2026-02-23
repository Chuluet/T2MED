import { Injectable } from '@nestjs/common';
import * as admin from 'firebase-admin';

@Injectable()
export class ConditionService {
  private db = admin.firestore();

  async saveMedicalProfile(userId: string, data: any) {
    await this.db
      .collection('users')
      .doc(userId)
      .collection('medicalProfile')
      .doc('profile')
      .set(
        {
          ...data,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

    return { message: 'Perfil médico actualizado correctamente' };
  }

  async getMedicalProfile(userId: string) {
    const doc = await this.db
      .collection('users')
      .doc(userId)
      .collection('medicalProfile')
      .doc('profile')
      .get();

    if (!doc.exists) {
      return {};
    }

    return doc.data();
  }
}