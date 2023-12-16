import 'dart:math';

import 'a_game_controller.dart';

abstract class Utils {
  
  ///  Сгенирировать уникальный код для комнаты
  static String uniquieRandomRoomCode() {
    String str;
    do {
      str = String.fromCharCodes([
            65 + Random().nextInt(25),
            65 + Random().nextInt(25),
          ]) +
          Random().nextInt(100).toString();
    } while (AvGameController.codeGames.containsKey(str));

    return str;
  }

  /// Сгенировать случайное имя
  static String generateRandomName() {
    const List<String> firstname = [
      "Неопознанный",
      "Загадочный",
      "Таинственный",
      "Секретный",
      "Ракета",
      "Звезда",
      "Гриб",
      "Дикий",
      "НЛО",
      "UFO",
      "Агент",
      "Человек",
      "Двуногий",
      "Двурукий",
      "Индеец",
      "Викинг",
      "Ковбой",
      "Воин",
      "Космонавт",
      "Заблудившийся",
      "Призрак",
      "Привидение",
      "Панда",
      "Неудержимый",
      "Комета",
      "Серьезный",
      "Испытатель",
      "Ученный",
    ];

    Random rand = Random();
    int countRandomName = rand.nextInt(firstname.length);

    return "${firstname[countRandomName]} №${rand.nextInt(1000)}";
  }

}