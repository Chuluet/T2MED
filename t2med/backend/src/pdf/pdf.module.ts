import { Module } from '@nestjs/common';
import { PdfController } from './pdf.controller';
import { PdfService } from './pdf.service';

@Module({
  controllers: [PdfController],
  providers: [PdfService],
  exports: [PdfService], // por si otros módulos lo necesitan
})
export class PdfModule {}