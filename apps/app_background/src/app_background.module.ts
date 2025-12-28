import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { QueueModule } from '@app/queue';
import { AppBackgroundController } from './app_background.controller';
import { AppBackgroundService } from './app_background.service';

@Module({
  imports: [
    // Load environment variables
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),
    // Queue module (Consumer)
    QueueModule.forRoot(),
    // TODO: Add your processor modules here
  ],
  controllers: [AppBackgroundController],
  providers: [AppBackgroundService],
})
export class AppBackgroundModule { }
