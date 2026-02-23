import { Controller, Post, Get, Put, Delete, Param, Body, UseGuards, Req } from '@nestjs/common';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';
import { AppointmentsService } from './appointments.service';

@Controller('appointments')
@UseGuards(FirebaseAuthGuard)
export class AppointmentsController {
    constructor(private readonly appointmentsService: AppointmentsService) {}

    // ==================== CRUD citas ====================

    @Post('create')
    async createAppointment(@Req() req, @Body() body: any) {
        const userId = req.user.uid;
        return this.appointmentsService.createAppointment(userId, body);
    }

    @Get()
    async getAppointments(@Req() req) {
        const userId = req.user.uid;
        return this.appointmentsService.getAppointments(userId);
    }

    @Put(':appointmentId')
    async updateAppointment(
        @Req() req,
        @Param('appointmentId') appointmentId: string,
        @Body() body: any,
    ) {
        const userId = req.user.uid;
        return this.appointmentsService.updateAppointment(userId, appointmentId, body);
    }

    @Delete(':appointmentId')
    async deleteAppointment(
        @Req() req,
        @Param('appointmentId') appointmentId: string,
    ) {
        const userId = req.user.uid;
        return this.appointmentsService.deleteAppointment(userId, appointmentId);
    }
}