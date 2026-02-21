import { Module } from '@nestjs/common';
import * as admin from 'firebase-admin';
import { readFileSync } from 'fs';

@Module({
  providers: [
    {
      provide: 'FIREBASE_ADMIN',
      useFactory: () => {
        // Solo inicializar si no hay ninguna app ya creada
        if (admin.apps.length === 0) {
          const serviceAccount = JSON.parse(
            readFileSync('firebase-service-account.json', 'utf8'),
          );
          admin.initializeApp({
            credential: admin.credential.cert(serviceAccount),
          });
        }
        return admin;
      },
    },
  ],
  exports: ['FIREBASE_ADMIN'],
})
export class FirebaseModule {}