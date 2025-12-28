import { Test, TestingModule } from '@nestjs/testing';
import { AppBackgroundController } from './app_background.controller';
import { AppBackgroundService } from './app_background.service';

describe('AppBackgroundController', () => {
  let appBackgroundController: AppBackgroundController;

  beforeEach(async () => {
    const app: TestingModule = await Test.createTestingModule({
      controllers: [AppBackgroundController],
      providers: [AppBackgroundService],
    }).compile();

    appBackgroundController = app.get<AppBackgroundController>(AppBackgroundController);
  });

  describe('root', () => {
    it('should return "Hello World!"', () => {
      expect(appBackgroundController.getHello()).toBe('Hello World!');
    });
  });
});
