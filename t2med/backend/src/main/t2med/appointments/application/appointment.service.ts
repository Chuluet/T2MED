import { Injectable } from '@nestjs/common';
import { AppointmentRepository } from '../infrastructure/persistence/appointment.repository';
import { Appointment } from '../domain/appointment.entity';

@Injectable()
export class AppointmentsService {
  constructor(private readonly appointmentRepository: AppointmentRepository) {}

  async createAppointment(userId: string, data: Partial<Appointment>): Promise<{ id: string; message: string }> {
    const id = await this.appointmentRepository.create(userId, data);
    return { id, message: 'Cita creada correctamente' };
  }

  async getAppointments(userId: string): Promise<Appointment[]> {
    return this.appointmentRepository.findAll(userId);
  }

  async updateAppointment(userId: string, appointmentId: string, data: Partial<Appointment>): Promise<{ message: string }> {
    await this.appointmentRepository.update(userId, appointmentId, data);
    return { message: 'Cita actualizada correctamente' };
  }

  async deleteAppointment(userId: string, appointmentId: string): Promise<{ message: string }> {
    await this.appointmentRepository.delete(userId, appointmentId);
    return { message: 'Cita eliminada correctamente' };
  }
}