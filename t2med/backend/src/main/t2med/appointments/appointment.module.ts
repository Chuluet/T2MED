import { Module } from '@nestjs/common';
import { AppointmentsController } from './controller/appointments.controller';
import { AppointmentsService } from './application/appointment.service';
import { AppointmentRepository } from './infrastructure/persistence/appointment.repository';

@Module({
  controllers: [AppointmentsController],
  providers: [AppointmentsService, AppointmentRepository],
  exports: [AppointmentsService],
})
export class AppointmentsModule {}