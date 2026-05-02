import { Module } from '@nestjs/common';
import { UserController } from './controller/user.controller';
import { UserService } from './application/user.service';
import { UserRepository } from './infrastructure/persistence/user.repository';

@Module({
  controllers: [UserController],
  providers: [UserService, UserRepository],
  exports: [UserService],
})
export class UserModule {}