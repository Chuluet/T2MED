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
      body.nombreMedicamento,
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

  // ==================== INVENTARIO ====================

@Post('inventory/create')
async createInventory(@Req() req, @Body() body: any) {
  const userId = req.user.uid;
  return this.medsService.createInventoryItem(userId, body);
}

@Get('inventory')
async getInventory(@Req() req) {
  const userId = req.user.uid;
  return this.medsService.getInventory(userId);
}

@Put('inventory/:itemId')
async updateInventory(
  @Req() req,
  @Param('itemId') itemId: string,
  @Body() body: any
) {
  const userId = req.user.uid;
  return this.medsService.updateInventoryItem(userId, itemId, body);
}

@Delete('inventory/:itemId')
async deleteInventory(@Req() req, @Param('itemId') itemId: string) {
  const userId = req.user.uid;
  return this.medsService.deleteInventoryItem(userId, itemId);
}
}