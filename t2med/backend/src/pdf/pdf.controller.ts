import { Controller, Post, Body, UseGuards, Req } from '@nestjs/common';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';
import { PdfService } from './pdf.service';

@Controller('pdf')
@UseGuards(FirebaseAuthGuard)
export class PdfController {
  constructor(private readonly pdfService: PdfService) {}

  @Post('send')
  async sendPdf(@Req() req, @Body() body: { email: string }) {
    const userId = req.user.uid;
    return this.pdfService.generateAndSendPdf(userId, body.email);
  }
}