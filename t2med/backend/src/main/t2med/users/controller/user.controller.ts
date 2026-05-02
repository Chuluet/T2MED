import { Controller } from '@nestjs/common';
import { MessagePattern, Payload } from '@nestjs/microservices';
import { UserService } from '../application/user.service';
import { User } from '../domain/user.entity';

@Controller()
export class UserController {
  constructor(private readonly userService: UserService) {}

  @MessagePattern({ cmd: 'create_user' })
  async createUser(@Payload() data: Pick<User, 'email' | 'password' | 'name' | 'lastName' | 'phone' | 'emergencyPhone'>) {
    return this.userService.createUser(data);
  }

  @MessagePattern({ cmd: 'get_user_profile' })
  async getUserProfile(@Payload() uid: string) {
    return this.userService.getUserProfile(uid);
  }

  @MessagePattern({ cmd: 'update_user_profile' })
  async updateUserProfile(@Payload() payload: { uid: string; data: Partial<User> }) {
    return this.userService.updateUserProfile(payload.uid, payload.data);
  }

  @MessagePattern({ cmd: 'reset_password' })
  async resetPassword(@Payload() email: string) {
    return this.userService.sendPasswordReset(email);
  }

  @MessagePattern({ cmd: 'save_fcm_token' })
  async saveFcmToken(@Payload() payload: { uid: string; fcmToken: string }) {
    return this.userService.saveFcmToken(payload.uid, payload.fcmToken);
  }

  @MessagePattern({ cmd: 'get_fcm_token' })
  async getFcmToken(@Payload() uid: string) {
    return this.userService.getUserFcmToken(uid);
  }
}