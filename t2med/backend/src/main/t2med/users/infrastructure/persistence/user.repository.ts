import { Injectable } from '@nestjs/common';
import * as admin from 'firebase-admin';
import { User } from '../../domain/user.entity';

@Injectable()
export class UserRepository {
  private db = admin.firestore();

  async create(uid: string, data: Partial<User>): Promise<void> {
    await this.db.collection('users').doc(uid).set({
      ...data,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  async findById(uid: string): Promise<User | null> {
    const doc = await this.db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return { uid, ...doc.data() } as User;
  }

  async update(uid: string, data: Partial<User>): Promise<void> {
    const clean = Object.fromEntries(
      Object.entries(data).filter(([_, v]) => v !== undefined)
    );
    await this.db.collection('users').doc(uid).update({
      ...clean,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  async saveFcmToken(uid: string, token: string): Promise<void> {
    await this.db.collection('users').doc(uid).update({
      fcmToken: token,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  async getFcmToken(uid: string): Promise<string | null> {
    const doc = await this.db.collection('users').doc(uid).get();
    return doc.data()?.fcmToken || null;
  }
}