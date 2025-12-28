import { Injectable } from '@nestjs/common';

@Injectable()
export class AppBackgroundService {
  getHello(): string {
    return 'Hello World!';
  }
}
