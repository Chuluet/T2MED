import { Module } from '@nestjs/common';
import { FirebaseModule } from './firebase/firebase.module';
import { MedsModule } from './meds/meds.module';
import { UserModule } from './users/user.module';
import { PdfModule } from './pdf/pdf.module';
import { MedicationSchedulerService } from './notifications/medication-scheduler.service';
import { NotificationsService } from './notifications/notifications.service';
import { ScheduleModule } from '@nestjs/schedule';
import { ConditionModule } from './med_conditions/condition.module';

@Module({
  imports: [
    FirebaseModule,
    MedsModule,
    UserModule,
    PdfModule,
    ConditionModule,
    ScheduleModule.forRoot(),
  ],
  providers: [MedicationSchedulerService, NotificationsService],
})
export class AppModule {}