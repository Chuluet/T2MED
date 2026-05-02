import { Injectable, BadRequestException } from '@nestjs/common';
import * as admin from 'firebase-admin';
import { UserRepository } from '../infrastructure/persistence/user.repository';
import { User } from '../domain/user.entity';

@Injectable()
export class UserService {

  constructor(private readonly userRepository: UserRepository) {}

  async createUser(data: Pick<User, 'email' | 'password' | 'name' | 'lastName' | 'phone' | 'emergencyPhone'>) {
    if (!data.name?.trim())
      throw new BadRequestException('El nombre es obligatorio');
    if (!data.lastName?.trim())
      throw new BadRequestException('El apellido es obligatorio');

    const emailPattern = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
    if (!emailPattern.test(data.email))
      throw new BadRequestException('El formato del correo no es válido');

    const phonePattern = /^\+[1-9]\d{0,2}\d{10}$/;
    if (!phonePattern.test(data.phone))
      throw new BadRequestException('Número con prefijo internacional');

    if (data.emergencyPhone && !phonePattern.test(data.emergencyPhone))
      throw new BadRequestException('Teléfono de emergencia con prefijo internacional');

    if (!data.password || data.password.length < 8 || !/[A-Z]/.test(data.password) || !/[0-9]/.test(data.password))
      throw new BadRequestException('Mínimo 8 caracteres, una mayúscula y un número');

    const userRecord = await admin.auth().createUser({
      email: data.email,
      password: data.password,
      displayName: `${data.name} ${data.lastName}`,
    });

    await this.userRepository.create(userRecord.uid, {
      name: data.name,
      lastName: data.lastName,
      email: data.email,
      phone: data.phone,
      emergencyPhone: data.emergencyPhone || null,
    });

    return { message: 'Usuario creado correctamente' };
  }

  async getUserProfile(uid: string): Promise<User | null> {
    return this.userRepository.findById(uid);
  }

  async updateUserProfile(uid: string, updateData: Partial<Pick<User, 'email' | 'name' | 'lastName' | 'phone' | 'emergencyPhone'>>) {
    const userRecord = await admin.auth().getUser(uid);
    const authUpdate: any = {};

    if (updateData.email && updateData.email !== userRecord.email)
      authUpdate.email = updateData.email;

    if (updateData.name !== undefined || updateData.lastName !== undefined) {
      const newName = updateData.name ?? userRecord.displayName?.split(' ')[0] ?? '';
      const newLastName = updateData.lastName ?? userRecord.displayName?.split(' ').slice(1).join(' ') ?? '';
      authUpdate.displayName = `${newName} ${newLastName}`.trim();
    }

    if (Object.keys(authUpdate).length > 0)
      await admin.auth().updateUser(uid, authUpdate);

    await this.userRepository.update(uid, updateData);
    return { message: 'Perfil actualizado correctamente' };
  }

  async sendPasswordReset(email: string) {
    const link = await admin.auth().generatePasswordResetLink(email);
    return { message: 'Se ha enviado el correo de recuperación', link };
  }

  async saveFcmToken(uid: string, fcmToken: string): Promise<{ message: string }> {
    await this.userRepository.saveFcmToken(uid, fcmToken);
    return { message: 'Token registrado correctamente' };
  }

  async getUserFcmToken(uid: string): Promise<string | null> {
    return this.userRepository.getFcmToken(uid);
  }
}