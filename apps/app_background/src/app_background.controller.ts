import { Controller, Get } from '@nestjs/common';
import { AppBackgroundService } from './app_background.service';

@Controller()
export class AppBackgroundController {
  constructor(private readonly appBackgroundService: AppBackgroundService) {}

  @Get()
  getHello(): string {
    return this.appBackgroundService.getHello();
  }
}
