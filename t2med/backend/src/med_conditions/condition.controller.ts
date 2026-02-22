import { Controller, Post, Get, UseGuards, Req, Body } from '@nestjs/common';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';
import { ConditionService } from './condition.service';

@Controller('condition')
@UseGuards(FirebaseAuthGuard)
export class ConditionController {
  constructor(private readonly conditionService: ConditionService) {}

  @Post()
  async saveProfile(@Req() req, @Body() body: any) {
    const userId = req.user.uid;
    return this.conditionService.saveMedicalProfile(userId, body);
  }

  @Get()
  async getProfile(@Req() req) {
    const userId = req.user.uid;
    return this.conditionService.getMedicalProfile(userId);
  }
}