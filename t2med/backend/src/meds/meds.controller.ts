import { Controller, Post, Get, Put, Delete, Param, Body, UseGuards, Req, Query } from '@nestjs/common';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';
import { MedsService } from './meds.service';

@Controller('meds')
@UseGuards(FirebaseAuthGuard)
export class MedsController {
  constructor(private readonly medsService: MedsService) {}

  // ==================== CRUD medicamentos ====================

  @Post('create')
  async createMed(@Req() req, @Body() body: any) {
    const userId = req.user.uid;
    return this.medsService.createMed(userId, body);
  }

  @Get()
  async getMeds(@Req() req) {
    const userId = req.user.uid;
    return this.medsService.getMeds(userId);
  }

  @Put(':medId')
  async updateMed(@Req() req, @Param('medId') medId: string, @Body() body: any) {
    const userId = req.user.uid;
    return this.medsService.updateMed(userId, medId, body);
  }

  @Delete(':medId')
  async deleteMed(@Req() req, @Param('medId') medId: string) {
    const userId = req.user.uid;
    return this.medsService.deleteMed(userId, medId);
  }

  // ==================== Tomas / Historial ====================

  @Post(':medId/toma')
  async registrarToma(
    @Req() req,
    @Param('medId') medId: string,
    @Body() body: { estado: string; fecha: string; horaProgramada: string, nombreMedicamento: string }
  ) {
    const userId = req.user.uid;
    return this.medsService.registrarToma(
      userId,
      medId,
      body.nombreMedicamento, // Asegúrate de enviar el nombre del medicamento desde el frontend
      body.estado,
      body.fecha,
      body.horaProgramada
    );
  }

  @Get(':medId/toma')
  async obtenerTomaDelDia(
    @Req() req,
    @Param('medId') medId: string,
    @Query('fecha') fecha: string
  ) {
    const userId = req.user.uid;
    return this.medsService.obtenerTomaDelDia(userId, medId, fecha);
  }

  @Get('historial')
  async obtenerHistorial(@Req() req) {
    const userId = req.user.uid;
    return this.medsService.obtenerHistorial(userId);
  }
}