import { Controller, Post, Get, Put, Delete, Param, Body, UseGuards, Req } from '@nestjs/common';
import { FirebaseAuthGuard } from '../../auth/firebase-auth.guard';
import { AppointmentsService } from '../application/appointment.service';
import { Appointment } from '../domain/appointment.entity';

@Controller('appointments')
@UseGuards(FirebaseAuthGuard)
export class AppointmentsController {
  constructor(private readonly appointmentsService: AppointmentsService) {}

  @Post('create')
  async createAppointment(@Req() req, @Body() body: Partial<Appointment>) {
    return this.appointmentsService.createAppointment(req.user.uid, body);
  }

  @Get()
  async getAppointments(@Req() req) {
    return this.appointmentsService.getAppointments(req.user.uid);
  }

  @Put(':appointmentId')
  async updateAppointment(
    @Req() req,
    @Param('appointmentId') appointmentId: string,
    @Body() body: Partial<Appointment>,
  ) {
    return this.appointmentsService.updateAppointment(req.user.uid, appointmentId, body);
  }

  @Delete(':appointmentId')
  async deleteAppointment(@Req() req, @Param('appointmentId') appointmentId: string) {
    return this.appointmentsService.deleteAppointment(req.user.uid, appointmentId);
  }
}