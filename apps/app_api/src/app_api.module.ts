import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { QueueModule } from '@app/queue';
import { AppApiController } from './app_api.controller';
import { AppApiService } from './app_api.service';

@Module({
  imports: [
    // Load environment variables
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),
    // Queue module (Producer)
    QueueModule.forRoot(),
    // TODO: Add your feature modules here
  ],
  controllers: [AppApiController],
  providers: [AppApiService],
})
export class AppApiModule { }
