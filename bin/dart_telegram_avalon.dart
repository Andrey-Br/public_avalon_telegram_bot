import 'a_game_controller.dart';
import 'action_telegram.dart';
import 'telebot.dart';
import 'users.dart';

//dart compile exe D:\AB\Projects\Flutter\dart_telegram_avalon\bin\dart_telegram_avalon.dart

void main(List<String> arguments) async {
  /// Инициализируем пользователей
  await users.init();
  print("Users init");

  /// Инициализируем очередь совершения действий в телеграм
  TelegramActionQueue.init();

  /// Инициализируем контроллер
  AvGameController.init();

  /// Запускаем бота
  TeleBot.start();

  print("Ready!");
}
