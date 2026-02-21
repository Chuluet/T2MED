import { Module } from '@nestjs/common';
import { MedsService } from './meds.service';
import { MedsController } from './meds.controller';
import { FirebaseModule } from '../firebase/firebase.module';

@Module({
  imports: [FirebaseModule],
  controllers: [MedsController],
  providers: [MedsService],
})
export class MedsModule {}
