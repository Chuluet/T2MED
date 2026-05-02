import { Module } from '@nestjs/common';
import { NotificationsService } from './application/notification.service';
import { MedicationSchedulerService } from './application/medication-scheduler.service';
import { UserModule } from '../users/user.module';

@Module({
  imports: [UserModule],
  providers: [NotificationsService, MedicationSchedulerService],
  exports: [NotificationsService],
})
export class NotificationsModule {}