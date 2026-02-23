import { Module } from '@nestjs/common';
import { MedsService } from './meds.service';
import { MedsController } from './meds.controller';
import { FirebaseModule } from '../firebase/firebase.module';
import { NotificationsService } from '../notifications/notifications.service';
import { UserService } from '../users/user.service';

@Module({
  imports: [FirebaseModule],
  controllers: [MedsController],
  providers: [
    MedsService,
    NotificationsService, 
    UserService],
})
export class MedsModule {}