import 'package:dart_telegram_avalon/inline_buttons.dart';
import 'messages.dart';
import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';
import 'package:teledart/model.dart';
import 'package:dart_telegram_avalon/private_settings.dart';
import 'a_game_controller.dart';
import 'roles.dart';
import 'users.dart';
import 'utils.dart';

class TeleBot {
  static late TeleDart teledart;
  static late String botName;

  static void start() async {
    botName = (await Telegram(telegramBotKey).getMe()).firstName;
    teledart = TeleDart(telegramBotKey, Event(botName));

    teledart.setMyCommands([
      BotCommand(
          command: '/refresh', description: 'Обновить главное сообщение'),
      BotCommand(command: '/help', description: 'Помощь'),
      BotCommand(command: '/resend', description: 'Переотправить сообщение')
    ]);

    teledart.start();

    teledart.onMessage().listen(_onMessage);
    teledart.onCommand().listen(_onCommand);
    teledart.onCallbackQuery().listen(_onCallBack);
    teledart.onUrl().listen(_onMessage);
  }

  static void _onCallBack(TeleDartCallbackQuery callback) async {
    if (callback.message == null) {
      callback.answer(text: "Сообщение не найдено!");
      return;
    }



    var chatId = callback.message!.chat.id;
    var messageId = callback.message!.messageId;
    int userId = callback.from.id;

    // Если пришло не в личку
    if (callback.message!.chat.type != "private") {
      teledart.sendMessage(chatId, "Я работаю только через личные сообщения!");
      return;
    }



    late UserData userData;

    // TODO: Убрать ботов
    if (userId == 274591399 && botMessages.containsKey(messageId)) {
      userData = botMessages[messageId]!;
    } else {
      userData =
          await users.get(userId) ?? await _newUser(chatId, callback.from);
    }

    // Вдруг сменился username
    await AvGameController.checkUsername(userData, callback.from);

    // TODO: И Раскомментировать
    // UserData userData = users[userId]!;

    if (callback.data == null) {
      return;
    }

    var commands = callback.data!.split('_');
    List<String> params = [];

    for (String command in commands) {
      if (command[0] == '!' || command[0] == '#') {
        params = command.split('>');

        command = params[0];
        params.removeAt(0);
      }

      // Если это игровая команда, передаем в игру
      if (command[0] == "#") {
        try {
          AvGameController.gameCallback(userData, command, params);
        } catch (_) {
          deleteMessage(chatId, messageId);
        }
      } else {
        switch (command) {
          case 'refresh':
            deleteMessage(chatId, messageId);
            AvGameController.refreshUser(userData);
            break;

          case 'home':
            editInlineButtons(
                chatId: chatId,
                messageId: messageId,
                replyMarkup: AvGameController.getMainButtonsUser(userData));
            break;

          case 'leave':
            AvGameController.leaveGame(userData);
            break;

          case 'createGame':
            AvGameController.createGame(userData);
            deleteMessage(chatId, messageId);
            break;

          case "deleteMessage":
            deleteMessage(chatId, messageId);
            break;

          case "inviteIgnore":
            AvGameController.ignoreInvite(userData);
            deleteMessage(chatId, messageId);
            break;

          case "inviteAcept":
            AvGameController.acceptInvite(userData);
            deleteMessage(chatId, messageId);
            break;

          case "gameMoreInformation":
            try {
              AvGameController.gameMoreInformation(userData);
            } on String catch (text) {
              callback.answer(text: text);
              AvGameController.refreshUser(userData);
            } catch (_) {
              callback.answer(text: "Error!");
              AvGameController.refreshUser(userData);
            }
            break;

          case "gameAboutRole":
            try {
              AvGameController.gameAboutRole(userData);
            } on String catch (text) {
              callback.answer(text: text);
              AvGameController.refreshUser(userData);
            } catch (_) {
              callback.answer(text: "Error!");
              AvGameController.refreshUser(userData);
            }
            break;

          // ############ ADMIN

          case 'adminStart':
            AvGameController.startGame(userData);
            break;

          case 'adminKick':
            callback.answer(text: "Удалить пользователя");
            AvGameController.kickInit(userData);
            break;

          case '!kick':
            deleteMessage(chatId, messageId);
            if (params.isNotEmpty) {
              AvGameController.kick(userData, int.parse(params[0]));
            }
            break;

          case 'adminNewAdmin':
            callback.answer(text: 'Передать администрирование');
            AvGameController.newAdminInit(userData);
            break;

          case '!newAdmin':
            deleteMessage(chatId, messageId);
            if (params.isNotEmpty) {
              AvGameController.newAdmin(userData, int.parse(params[0]));
              break;
            }

          case 'adminChangeLady':
            callback.answer(text: "Изменить русалку");
            AvGameController.gameChangeLady(userData);
            break;

          case 'adminChangeFirstPlayers':
            callback.answer(text: "Изменить первого игрока");
            AvGameController.changeFirstPlayersInit(userData);
            break;

          case "!changeFirstPlayers":
            {
              try {
                await AvGameController.changeFirstPlayerCallback(
                    userData, messageId, params).onError((error, stackTrace) => throw error!);
              } on String catch (e) {
                callback.answer(text: e);
                deleteMessage(chatId, messageId);
              } catch (_) {
                callback.answer(text: "Error");
                deleteMessage(chatId, messageId);
              }
              break;
            }

          case 'adminChangeIndexPlayers':
            callback.answer(text: "Изменить порядок игроков");
            AvGameController.changeIndexPlayersInit(userData);
            break;

          case '!changeIndexPlayers':
            try {
              AvGameController.changeIndexCallback(userData, messageId, params);
            } on String catch (e) {
              callback.answer(text: e);
              deleteMessage(chatId, messageId);
            } catch (_) {
              callback.answer(text: "Error");
              deleteMessage(chatId, messageId);
            }
            break;

          case 'adminChangeGood':
            callback.answer(text: "Поменяйте добро");
            AvGameController.changeGoodRoleInit(userData);
            break;

          case '!changeGood':
            try {
              AvGameController.changeGoodRoleCallback(
                  userData, messageId, params);
            } on String catch (e) {
              callback.answer(text: e);
              deleteMessage(chatId, messageId);
            } catch (_) {
              callback.answer(text: "Error");
              deleteMessage(chatId, messageId);
            }
            break;

          case 'adminChangeEvil':
            callback.answer(text: "Поменяйте зло");
            AvGameController.changeEvilRoleInit(userData);
            break;

          case '!changeEvil':
            try {
              AvGameController.changeEvilRoleCallback(
                  userData, messageId, params);
            } on String catch (e) {
              callback.answer(text: e);
              deleteMessage(chatId, messageId);
            } catch (_) {
              callback.answer(text: "Error");
              deleteMessage(chatId, messageId);
            }
            break;
        }
      }
    }
  }

  //TODO: Протестить что будет если добавить в конференцию, а не в личке
  static void _onMessage(TeleDartMessage message) async {
    int chatId = message.chat.id;

    // Если пришло не в личку
    if (message.chat.type != "private") {
      teledart.sendMessage(chatId, "Я работаю только через личные сообщения!");
      return;
    }

    deleteMessage(chatId, message.messageId);

    if (message.from == null) {
      return;
    }

    User user = message.from!;

    UserData? userData = await users.get(user.id);

    // Если пользователь не найден создаем нового
    userData ??= await _newUser(chatId, user);

    // Вдруг сменился username
    await AvGameController.checkUsername(userData, user);

    if (message.contact != null) {
      return _onContact(userData, message);
    }

    if (message.text == null) {
      return;
    }

    String searchText = message.text!.toUpperCase();
    AvGameController.searchGameFromCode(userData, searchText);
  }

  static void _onCommand(TeleDartMessage message) async {
    int chatId = message.chat.id;
    int messageId = message.messageId;

    // Если пришло не в личку
    if (message.chat.type != "private") {
      teledart.sendMessage(chatId, "Я работаю только через личные сообщения!");
      return;
    }

    deleteMessage(chatId, messageId);

    if (message.from == null) {
      print('User unknown!');
      return;
    }

    if (message.text == null) {
      return;
    }

    User user = message.from!;

    UserData? userData = await users.get(user.id);

    // Если пользователь не найден создаем нового
    userData ??= await _newUser(chatId, user);

    // Вдруг сменился username
    await AvGameController.checkUsername(userData, user);

    List<String> params = message.text!.split(RegExp("[> ]"));

    String command = params[0];

    params.removeAt(0);

    switch (command) {
      case '/bot':
        if (userData.userId != 274591399) return;
        if (userData.player != null) {
          userData.player!.game.addTestBot(userData);
        }
        break;

      case '/admin':
        AvGameController.adminTelegramMessage(userData);
        break;

      case '/show':
        if (params.isEmpty) {
          return;
        }
        AvGameController.adminShowGame(userData, params[0]);
        break;

      case '/showm':
        if (params.isEmpty) {
          return;
        }
        AvGameController.adminShowMoreGame(userData, params[0]);
        break;

      case '/name':
        if (params.isEmpty) {
          TeleBot.sendMessage(userData,
              "Введите имя через пробел после команды /name\\. Например `/name Ivan Иванов`\nИмя может содержать пробелы, английские и русские буквы и иметь длинну не более 20 символов\\.",
              replyMarkup: Buttons.delete);
          return;
        }

        String name = params.join(" ");

        AvGameController.changeName(userData, name);
        break;

      case '/help':
        sendMessage(userData, Msg.help, replyMarkup: Buttons.delete);
        break;

      case '/helpMessage':
        sendMessage(userData, Msg.helpMessage, replyMarkup: Buttons.delete);
        break;

      case '/helpRoom':
        sendMessage(userData, Msg.helpRoom, replyMarkup: Buttons.delete);
        break;

      case '/aboutAuthor':
        sendMessage(userData, Msg.aboutAthor, replyMarkup: Buttons.delete);
        break;

      case '/rules':
        sendMessage(userData, Msg.rules, replyMarkup: Buttons.delete);
        break;

      case '/ruleAboutGame':
        sendMessage(userData, Msg.ruleAboutGame,
            replyMarkup: Buttons.delete, duration: Duration(minutes: 5));
        break;

      case '/ruleAboutRole':
        sendMessage(userData, Msg.ruleAboutRole,
            replyMarkup: Buttons.delete, duration: Duration(minutes: 5));
        break;

      case '/ruleAboutQuest':
        sendMessage(userData, Msg.ruleAboutQuest,
            replyMarkup: Buttons.delete, duration: Duration(minutes: 5));
        break;

      case '/ruleAboutSearchMerlin':
        sendMessage(userData, Msg.ruleAboutSearchMerlin,
            replyMarkup: Buttons.delete);
        break;

      case '/ruleAboutLady':
        sendMessage(userData, Msg.ruleAboutLady, replyMarkup: Buttons.delete);
        break;

      case '/ruleQuestCount':
        sendMessage(userData, Msg.ruleQuestCount, replyMarkup: Buttons.delete);
        break;

      case '/role':
        sendMessage(userData, Msg.allRolesMessage,
            replyMarkup: Buttons.delete, duration: Duration(minutes: 5));
        break;

      case '/aboutMerlin':
        sendMessage(userData, Merlin.cAboutRole, replyMarkup: Buttons.delete);
        break;

      case '/aboutPersival':
        sendMessage(userData, Persival.cAboutRole, replyMarkup: Buttons.delete);
        break;

      case '/aboutKay':
        sendMessage(userData, Kay.cAboutRole, replyMarkup: Buttons.delete);
        break;

      case '/aboutTristan':
        sendMessage(userData, Tristan.cAboutRole, replyMarkup: Buttons.delete);
        break;

      case '/aboutIsolde':
        sendMessage(userData, Isolde.cAboutRole, replyMarkup: Buttons.delete);
        break;

      case '/aboutArthur':
        sendMessage(userData, Arthur.cAboutRole, replyMarkup: Buttons.delete);
        break;

      case '/aboutGood':
        sendMessage(userData, Good.cAboutRole, replyMarkup: Buttons.delete);
        break;

      case '/aboutMorded':
        sendMessage(userData, Morded.cAboutRole, replyMarkup: Buttons.delete);
        break;

      case '/aboutMorgan':
        sendMessage(userData, Morgan.cAboutRole, replyMarkup: Buttons.delete);
        break;

      case '/aboutNimue':
        sendMessage(userData, Nimue.cAboutRole, replyMarkup: Buttons.delete);
        break;

      case '/aboutAssasin':
        sendMessage(userData, Assasin.cAboutRole, replyMarkup: Buttons.delete);
        break;

      case '/aboutKnight':
        sendMessage(userData, Knight.cAboutRole, replyMarkup: Buttons.delete);
        break;

      case '/aboutOberon':
        sendMessage(userData, Oberon.cAboutRole, replyMarkup: Buttons.delete);
        break;

      case '/aboutEvil':
        sendMessage(userData, Evil.cAboutRole, replyMarkup: Buttons.delete);
        break;

      case '/reCreateGame':
        AvGameController.reCreateGame(userData);
        break;

      case '/start':
        AvGameController.refreshUser(userData, reSend: true);
        break;

      case '/refresh':
        AvGameController.refreshUser(userData).then(
            (value) => {AvGameController.refreshSecondMessage(userData!)});
        break;

      case '/resend':
        AvGameController.refreshUser(userData, reSend: true).then(
            (value) => {AvGameController.refreshSecondMessage(userData!)});
        break;

      case '/hello':
        {
          sendMessage(userData,
              "Приветствую\\, ${userData.url}\\. Добро пожаловать в игру Авалон\\! 🧙‍♂️",
              replyMarkup: Buttons.delete);
        }
        break;

      case '/create':
        AvGameController.createGame(userData);
        break;
    }
  }

  /// Когда приглашают в игру
  static void _onContact(UserData userData, TeleDartMessage message) async {
    if (message.contact == null) {
      print('_onContact Error: message dont have contact!');
      return;
    }

    if (message.contact!.userId == null) {
      sendMessage(userData, 'Не могу найти этого игрока в Telegramm\\!',
          replyMarkup: Buttons.delete);
      return;
    }

    int inviteUserId = message.contact!.userId!;

    AvGameController.invite(userData, inviteUserId);
  }

  static Future<UserData> _newUser(int chatId, User user) async {
    var firstName = user.firstName;
    var lastName = user.lastName;
    var id = user.id;

    String name = '$firstName${lastName == null ? "" : " ${lastName[0]}"}';

    String? newName = AvGameController.correctName(name);

    if (newName != null) {
      name = newName;
    } else {
      if (user.username != null) {
        String? usName = AvGameController.correctName(user.username!);
        name = usName ?? Utils.generateRandomName();
      } else {
        name = Utils.generateRandomName();
      }
    }

    print("User ($id)$name (chat: $chatId) added");

    UserData userData = UserData(
        userId: user.id, chatId: chatId, name: name, username: user.username);

    await AvGameController.refreshUser(userData, reSend: true);

    users.update(userData);

    return userData;
  }

  static Future<bool> sendMessage(UserData userData, String text,
      {bool delete = true,
      Duration duration = const Duration(minutes: 2),
      ReplyMarkup? replyMarkup,
      String? parseMode = "MarkdownV2",

      /// Функция вызывается при автоудалении при этом true если успешно, false если ошибка (Скорее всего сообщение уже удалено)
      void Function(bool delete)? onAutoDelete}) async {
    replyMarkup ??= Buttons.empty;
    late Message msg;
    try {
      msg = await teledart
          .sendMessage(userData.chatId, text,
              replyMarkup: replyMarkup,
              parseMode: parseMode,
              disableWebPagePreview: true)
          .onError((o, stackTrace) {
        print("Error SendMessage ${o.toString()}");
        throw "error";
      });

      // TODO: Убрать как протестируем
      if (userData is BotUserData) {
        botMessages[msg.messageId] = userData;
      }

      if (delete) {
        Future.delayed(duration).then((_) async {
          deleteMessage(msg.chat.id, msg.messageId).then((value) {
            if (onAutoDelete != null) onAutoDelete(value);
          });
        });
      }
    } catch (v) {
      try {
        msg = await teledart
            .sendMessage(userData, "⁉️ Error Message ⁉️\n\n$text",
                replyMarkup: Buttons.delete, parseMode: null)
            .onError((error, stackTrace) => throw "error");

        // TODO: Убрать как протестируем
        if (userData is BotUserData) {
          botMessages[msg.messageId] = userData;
        }
      } catch (_) {
        print("Send Message Error");
        return false;
      }
    }

    return true;
  }

  static Future<Message> sendAndGetMessage(UserData userData, String text,
      {bool delete = true,
      Duration duration = const Duration(minutes: 2),
      ReplyMarkup? replyMarkup,
      String? parseMode = "MarkdownV2",
      // Функция вызывается при автоудалении при этом true если успешно, false если ошибка (Скорее всего сообщение уже удалено)
      void Function(bool delete)? onAutoDelete}) async {
    replyMarkup ??= Buttons.empty;
    late Message msg;
    try {
      msg = await teledart
          .sendMessage(userData.chatId, text,
              replyMarkup: replyMarkup,
              parseMode: parseMode,
              disableWebPagePreview: true)
          .onError((o, stackTrace) {
        print("Error SendMessage: ${(o as Message).text}");
        throw "error";
      });

      // TODO: Убрать как протестируем
      if (userData is BotUserData) {
        botMessages[msg.messageId] = userData;
      }

      if (delete) {
        Future.delayed(duration).then((_) async {
          deleteMessage(msg.chat.id, msg.messageId).then((value) {
            if (onAutoDelete != null) onAutoDelete(value);
          });
        });
      }
    } catch (v) {
      try {
        msg = await sendAndGetMessage(userData, "⁉️ Error Markdown ⁉️\n\n$text",
                replyMarkup: Buttons.delete, parseMode: null)
            .onError((error, stackTrace) => throw "error");
      } catch (_) {
        print("Error Message send");
        throw "Error Message send";
      }
    }

    return msg;
  }

  static Future<bool> deleteMessage(int chatId, int messageId) async {
    try {
      //TODO: Убрать проверку
      if (chatId == 274591399) {
        botMessages.remove(messageId);
      }
      await teledart
          .deleteMessage(chatId, messageId)
          .onError((_, stackTrace) => throw "Error");
    } catch (_) {
      return false;
    }
    return true;
  }

  static Future<bool> updateTextMessage(
    int chatId,
    int messageId,
    String text, {
    InlineKeyboardMarkup? replyMarkup,
    String? parseMode = "MarkdownV2",
  }) async {
    replyMarkup ??= Buttons.empty;

    try {
      await teledart
          .editMessageText(text,
              replyMarkup: replyMarkup,
              parseMode: parseMode,
              chatId: chatId,
              messageId: messageId,
              disableWebPagePreview: true)
          .onError((_, stackTrace) {
        throw "error";
      });
    } catch (_) {
      return false;
    }
    return true;
  }

  static Future<bool> updateTextMainMessage(
    UserData userData,
    String text, {
    InlineKeyboardMarkup? replyMarkup,
    bool resend = false,
    String? parseMode = "MarkdownV2",
  }) async {
    replyMarkup ??= Buttons.empty;

    Future<void> asFail() async {
      deleteMessage(userData.chatId, userData.mainMessage!);

      try {
        Message msg = await sendAndGetMessage(userData, text,
                delete: false, replyMarkup: replyMarkup, parseMode: parseMode)
            .onError((error, stackTrace) => sendAndGetMessage(userData, text,
                    delete: false, replyMarkup: replyMarkup, parseMode: null)
                .onError((error, stackTrace) => throw "Error"));
        userData.mainMessage = msg.messageId;
        users.update(userData);
      } catch (_) {
        print("Error update Message");
      }
    }

    try {
      if (userData.mainMessage == null) {
        var msg = await sendAndGetMessage(userData, text,
                delete: false, replyMarkup: replyMarkup, parseMode: parseMode)
            .onError((error, stackTrace) => throw "Error!");
        userData.mainMessage = msg.messageId;
        users.update(userData);
        return false;
      }

      if (resend) {
        await asFail();
        return true;
      }

      //bool isSucsses =
      await updateTextMessage(userData.chatId, userData.mainMessage!, text,
              parseMode: parseMode, replyMarkup: replyMarkup)
          .onError((_, stackTrace) async {
        return await updateTextMessage(userData.chatId, userData.mainMessage!,
                "Error Markdown\n\n$text",
                parseMode: null, replyMarkup: replyMarkup)
            .onError((error, stackTrace) => throw error ?? "Error");
      });
      // return isSucsses;
    } catch (er) {
      await asFail();
      return false;
    }

    return true;
  }

  static Future<bool> editInlineButtons(
      {required int chatId,
      required int messageId,
      InlineKeyboardMarkup? replyMarkup}) async {
    try {
      await teledart
          .editMessageReplyMarkup(
              chatId: chatId, messageId: messageId, replyMarkup: replyMarkup)
          .onError((_, stackTrace) => throw 'Error');
    } catch (_) {
      return false;
    }
    return true;
  }
}
