import 'package:teledart/model.dart';

abstract class Buttons {
  static InlineKeyboardMarkup home = InlineKeyboardMarkup(inlineKeyboard: [
    [InlineKeyboardButton(text: "Вернуться", callbackData: "home")]
  ]);

  static InlineKeyboardMarkup empty = InlineKeyboardMarkup(inlineKeyboard: []);

  static InlineKeyboardMarkup test = InlineKeyboardMarkup(inlineKeyboard: [
    [InlineKeyboardButton(text: "test", callbackData: "test")]
  ]);

  /// Кнопка для удаления этого сообщения
  static InlineKeyboardMarkup delete = InlineKeyboardMarkup(inlineKeyboard: [
    [InlineKeyboardButton(text: "Закрыть", callbackData: "deleteMessage")]
  ]);

  static InlineKeyboardMarkup invite = InlineKeyboardMarkup(inlineKeyboard: [
    [
      InlineKeyboardButton(text: "Принять", callbackData: "inviteAcept"),
      InlineKeyboardButton(text: "Отклонить", callbackData: "inviteIgnore")
    ]
  ]);

  static InlineKeyboardMarkup leave = InlineKeyboardMarkup(inlineKeyboard: [
    [
      InlineKeyboardButton(text: "Покинуть 👣", callbackData: "leave"),
    ]
  ]);

  static InlineKeyboardMarkup admin = InlineKeyboardMarkup(inlineKeyboard: [
    [InlineKeyboardButton(text: "Начать игру 🎮", callbackData: "adminStart")],
    [
      InlineKeyboardButton(
          text: "Роли Добра 🔆", callbackData: "adminChangeGood"),
      InlineKeyboardButton(
          text: "Роли Зла ‼️", callbackData: "adminChangeEvil"),
    ],
    [
      InlineKeyboardButton(
          text: "Порядок игроков 🔢", callbackData: "adminChangeIndexPlayers"),
      InlineKeyboardButton(
          text: "Первый игрок 🚩", callbackData: "adminChangeFirstPlayers")
    ],
    [
      InlineKeyboardButton(
          text: "Добавить/ Убрать русалку 🧜‍♀️",
          callbackData: "adminChangeLady"),
    ],
    [
      InlineKeyboardButton(
          text: "Удалить пользователя 🚫", callbackData: "adminKick")
    ],
    [
      InlineKeyboardButton(
          text: "Передать администрирование 👑", callbackData: "adminNewAdmin")
    ],
    [InlineKeyboardButton(text: "Покинуть👣", callbackData: "leave")],
  ]);

  static InlineKeyboardMarkup gameMainMassage =
      InlineKeyboardMarkup(inlineKeyboard: [
    [
      InlineKeyboardButton(text: "О моей роли", callbackData: "gameAboutRole"),
      InlineKeyboardButton(
          text: "Больше информации", callbackData: "gameMoreInformation")
    ]
  ]);

  static InlineKeyboardMarkup gameVoteInvite =
      InlineKeyboardMarkup(inlineKeyboard: [
    [
      InlineKeyboardButton(text: "Согласен", callbackData: "#VoteInvite+"),
      InlineKeyboardButton(text: "Против", callbackData: "#VoteInvite-")
    ]
  ]);

  static InlineKeyboardMarkup gameAccept =
      InlineKeyboardMarkup(inlineKeyboard: [
    [InlineKeyboardButton(text: "Подтвердить", callbackData: "#accept")]
  ]);

  static InlineKeyboardMarkup gameReset = InlineKeyboardMarkup(inlineKeyboard: [
    [InlineKeyboardButton(text: "Сбросить", callbackData: "#reset")]
  ]);

  static InlineKeyboardMarkup gameVoteQuest(List<bool> answers) {
    return InlineKeyboardMarkup(inlineKeyboard: [
      answers
          .map<InlineKeyboardButton>((b) => InlineKeyboardButton(
              text: b ? "Успех" : "Провал",
              callbackData: "#VoteQuest${b ? '+' : '-'}"))
          .toList()
    ]);
  }

  static InlineKeyboardMarkup gameLadyAnswer(List<bool> answers) {
    return InlineKeyboardMarkup(inlineKeyboard: [
      answers
          .map<InlineKeyboardButton>((b) => InlineKeyboardButton(
              text: b ? "Добро" : "Зло",
              callbackData: "#LadyAnswer${b ? '+' : '-'}"))
          .toList()
    ]);
  }
}
