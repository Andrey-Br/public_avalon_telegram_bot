import 'package:dart_telegram_avalon/admin_users.dart';

import 'a_game.dart';
import 'action_telegram.dart';
import 'generate_buttons.dart';
import 'package:dart_telegram_avalon/inline_buttons.dart';
import 'messages.dart';
import 'package:teledart/model.dart';
import 'roles.dart';
import 'telebot.dart';
import 'users.dart';
import 'utils.dart';

class AvGameController {
  static Map<String, AvGame> codeGames = {};

  /// Иницализация контроллера
  static void init() {
    _autoDeleteGameInit();
  }

  /// Игрок покидает комнату
  static void leaveGame(UserData userData) async {
    if (userData.player == null) {
      TelegramSendMessage(
          userData, "Вы не можете покинуть игру\\, так как вы не в игре",
          replyMarkup: Buttons.delete);
      return;
    }

    if (userData.player!.game.bStart) {
      TelegramSendMessage(userData,
          "Вы не можете покинуть игру\\, так как она уже началась\\. Нажмите /reCreateGame \\, чтобы узнать больше\\.",
          replyMarkup: Buttons.delete);
      return;
    }

    await userData.player!.game.deletePlayer(userData.player!);

    TelegramSendMessage(userData, "Вы покинули игру",
        replyMarkup: Buttons.delete);
  }

  /// Игрок подключается к комнате
  static void connectGame(UserData userData, AvGame game) async {
    if (game.bStart) {
      return;
    }

    game.invitedUserData.remove(userData);
    userData.player = game.addUser(userData);
    userData.inviteGame = null;

    refreshUser(userData, reSend: true);

    TelegramSendMessage(
        userData, "Вы подключились к игре `${game.gameCode}`\\!",
        replyMarkup: Buttons.delete);
  }

  /// Создать игру
  static void createGame(UserData userData) async {
    if (userData.player != null) {
      TelegramSendMessage(userData,
          "Невозможно создать игру\\, так как вы сейчас находитесь в игре",
          replyMarkup: Buttons.delete);
      return;
    }

    if (userData.inviteGame != null) {
      TelegramSendMessage(
          userData, "Невозможно создать игру\\, так как Вам пришло приглашение",
          replyMarkup: Buttons.delete);
      return;
    }

    AvGame game = AvGame(userData, Utils.uniquieRandomRoomCode());
    codeGames[game.gameCode] = game;
    userData.player = game.addUser(userData);

    refreshUser(userData, reSend: true);

    TelegramSendMessage(userData,
        "Вы создали игру `${game.gameCode}`\\. Вы в ней администратор\\.",
        replyMarkup: Buttons.delete);
  }

  /// Принять приглашение
  static void acceptInvite(UserData userData) {
    // Если уже в игре
    if (userData.player != null) {
      TelegramSendMessage(userData,
          "Не удалось подключиться по приглашению \\. Вы уже в игре \\.",
          replyMarkup: Buttons.delete);
      return;
    }

    // Если нет приглашенной игры
    if (userData.inviteGame == null) {
      TelegramSendMessage(userData, "Не удалось подключиться по приглашению",
          replyMarkup: Buttons.delete);
      return;
    }

    // Если игра уже началась
    if (userData.inviteGame!.bStart) {
      TelegramSendMessage(userData,
          "Не удалось подключиться по приглашению\\. Игра уже началась\\.",
          replyMarkup: Buttons.delete);
      userData.inviteGame = null;
      return;
    }

    AvGame game = userData.inviteGame!;
    connectGame(userData, game);
  }

  /// Отказать предложение
  static void ignoreInvite(UserData userData) {
    if (userData.inviteGame != null) {
      if (userData.inviteGame!.bStart == false) {
        userData.inviteGame!.invitedUserData.remove(userData);
        userData.inviteGame!.playersRefreshMessage();
      }
    }
    userData.inviteGame = null;
  }

  /// Поиск игры по коду
  static void searchGameFromCode(UserData userData, String gameCode) {
    if (userData.player != null) {
      TelegramSendMessage(userData,
          "Вы не можете подключиться к игре\\. Так как Вы уже в игре\\.",
          replyMarkup: Buttons.delete);
      return;
    }

    if (codeGames.containsKey(gameCode) == false) {
      TelegramSendMessage(userData, "Не удалось найти игру `$gameCode`",
          replyMarkup: Buttons.delete);
      return;
    }

    var game = codeGames[gameCode]!;

    if (game.bStart) {
      TelegramSendMessage(userData,
          "Невозможно подключится к игре `$gameCode`\\, так как она уже началась",
          replyMarkup: Buttons.delete);
      return;
    }

    connectGame(userData, codeGames[gameCode]!);
  }

  /// Обновить главное сообщение пользователя
  static Future<bool> refreshUser(UserData userData,
      {bool reSend = false}) async {
    InlineKeyboardMarkup? replyMarkup = getMainButtonsUser(userData);

    late String text;

    if (userData.player == null) {
      text =
          "Приветствую\\, ${userData.url}\\.\nДобро пожаловать в игру *Авалон*\\! 🧙‍♂️\n\n${Msg.startInfo}";
    } else {
      text = userData.player!.generateMainMessage();
    }

    var editMainMessage =
        TelegramEditMainMessage(userData, text, replyMarkup, resend: reSend);

    return await editMainMessage.answer;
  }

  /// Если возможно обновляем сообщение игры
  static void refreshSecondMessage(UserData userData) {
    if (userData.player == null) return;
    if (!userData.player!.game.bStart) return;
    if (userData.player!.game.turn == null) return;

    Turn turn = userData.player!.game.turn!;

    if (turn.actionsPlayers.contains(userData.player!)) {
      turn.reSendSecondMessage(userData.player!);
    }
  }

  /// Получить доступные кнопки пользователя
  static InlineKeyboardMarkup? getMainButtonsUser(UserData userData) {
    if (userData.player == null) {
      return Buttons.empty;
    } else {
      return userData.player!.getButtons();
    }
  }

  /// Начать игру
  static void startGame(UserData userData) {
    if (userData.player == null) {
      return;
    }

    if (!userData.player!.isAdmin) {
      return;
    }

    if (userData.player!.game.bStart) {
      return;
    }

    userData.player!.game.start();
  }

  ///  Игрок приглашает другого игрока
  static Future<void> invite(UserData fromUserData, int inviteUserId) async {
    UserData? inviteUserData = await users.get(inviteUserId);

    if (inviteUserData == null) {
      TelegramSendMessage(fromUserData,
          "Этого игрока нет в моей базе\\. Сначала он должен подключиться к боту\\.",
          replyMarkup: Buttons.delete);

      return;
    }

    if (inviteUserData.player != null) {
      TelegramSendMessage(fromUserData,
          "Невозможно пригласить игрока\\: ${inviteUserData.url}\\. Этот пользователь уже находится в игре\\.",
          replyMarkup: Buttons.delete);

      return;
    }

    if (inviteUserData.inviteGame != null) {
      TelegramSendMessage(fromUserData,
          "Невозможно пригласить игрока\\: ${inviteUserData.url}\\. Приглашение уже отпралвенно этому пользователю\\.",
          replyMarkup: Buttons.delete);
      return;
    }

    if (fromUserData.player == null) {
      TelegramSendMessage(fromUserData,
          "Невозможно пригласить игрока\\: ${inviteUserData.url}\\. Так как вы сами не в игре\\. Вы можете создать свою игру командой /create или подключится к уже созданной игре отправив боту сообщение с её кодом\\, или же другие пользователи которые уже в игре могут поделиться с ботом Вашим контактом \\, чтобы Вам пришло приглашение\\.",
          replyMarkup: Buttons.delete);
      return;
    }

    var game = fromUserData.player!.game;

    inviteUserData.inviteGame = game;

    game.invitedUserData.add(inviteUserData);
    game.playersRefreshMessage();

    TelegramSendMessage(fromUserData,
        'Приглашение отправленно игроку\\: ${inviteUserData.url}\\!',
        replyMarkup: Buttons.delete);

    TelegramSendMessage(
        inviteUserData, "${fromUserData.url} отправил Вам приглашение на игру",
        replyMarkup: Buttons.invite,
        duration: Duration(minutes: 2), onAutoDelete: (value) {
      if (value) {
        inviteUserData.inviteGame?.invitedUserData.remove(inviteUserData);
        inviteUserData.inviteGame?.playersRefreshMessage();
        inviteUserData.inviteGame = null;
      }
    });
  }

  /// Открыть развернутую информацию об игре
  static void gameMoreInformation(UserData userData) {
    if (userData.player == null) throw "Вы не в игре!";
    if (!userData.player!.game.bStart) throw "Игра не началась";

    TelegramSendMessage(userData, userData.player!.game.stringMoreInformation,
        replyMarkup: Buttons.delete);
  }

  /// Сообщение о роли
  static void gameAboutRole(UserData userData) {
    if (userData.player == null) throw "Вы не в игре!";
    if (!userData.player!.game.bStart) throw "Игра не началась";

    TelegramSendMessage(userData, userData.player!.roleMessage(),
        replyMarkup: Buttons.delete);
  }

  /// Пересоздать игру
  static void reCreateGame(UserData userData) {
    if (userData.player == null) {
      TelegramSendMessage(
          userData, "Вы не в игре\\, поэтому не можете ее создать\\.",
          replyMarkup: Buttons.delete);
      return;
    }

    if (userData.player!.game.adminUserData != userData) {
      TelegramSendMessage(userData,
          "Вы не администратор\\, поэтому не можете совершить это действие\\. Обратитесь к администратору ${userData.player!.game.adminUserData.url}\\.",
          replyMarkup: Buttons.delete);
      return;
    }

    AvGame game = userData.player!.game;

    game.reCreateGame();

    game.messageAllPlayers("Игра была пересоздана\\.");
  }

  /// Инициализация сообщения кика
  static void kickInit(UserData userData) {
    if (userData.player == null) {
      return;
    }

    if (!userData.player!.isAdmin) {
      return;
    }

    if (userData.player!.game.bStart) {
      return;
    }

    var players =
        userData.player!.game.players.where((value) => !value.isAdmin);

    if (players.isEmpty) {
      TelegramSendMessage(userData, "Нет игроков", replyMarkup: Buttons.delete);
      return;
    }

    TelegramSendMessage(userData, "Кого выкинуть\\?",
        replyMarkup: GenerateButtons.fromPlayers(
            players: players,
            startStringCallback: "!kick",
            endCommands: Buttons.delete.inlineKeyboard));
  }

  /// Попытка удалить пользователя
  static Future<void> kick(UserData adminUserData, int userKickId) async {
    if (adminUserData.player == null) {
      return;
    }

    if (!adminUserData.player!.isAdmin) {
      return;
    }

    if (adminUserData.player!.game.bStart) {
      return;
    }

    UserData? kickedUserData = await users.get(userKickId);

    if (kickedUserData == null) {
      print('kicked user not found!');
      return;
    }

    AvGame game = adminUserData.player!.game;

    if (kickedUserData.player == null) {
      return;
    }

    if (game.players.contains(kickedUserData.player)) {
      game.deletePlayer(kickedUserData.player!, isKick: true);
    }
  }

  /// Инициализация сообщения о передаче администрирования
  static void newAdminInit(UserData userData) {
    if (userData.player == null) {
      return;
    }

    if (!userData.player!.isAdmin) {
      return;
    }

    var players =
        userData.player!.game.players.where((value) => !value.isAdmin);

    // if (players.isEmpty) {
    //   TelegramSendMessage(userId, "Нет игроков", replyMarkup: Buttons.delete);
    //   return;
    // }

    TelegramSendMessage(userData, "Кто будет новым администратором\\?",
        replyMarkup: GenerateButtons.fromPlayers(
            players: players,
            startStringCallback: "!newAdmin",
            endCommands: Buttons.delete.inlineKeyboard));
  }

  /// Попытка передать администрирование
  static Future<void> newAdmin(UserData adminUserData, int newAdminId) async {
    if (adminUserData.player == null) {
      return;
    }

    if (!adminUserData.player!.isAdmin) {
      return;
    }
    UserData? newAdminUserData = await users.get(newAdminId);

    if (newAdminUserData == null) {
      print('new Admin user not found!');
      return;
    }

    AvGame game = adminUserData.player!.game;

    if (newAdminUserData.player == null) {
      return;
    }

    if (game.players.contains(newAdminUserData.player)) {
      game.changeAdministrator(newAdminUserData);
    }
  }

  /// Попытка включить/Выключить русалку
  static void gameChangeLady(UserData userData) {
    if (userData.player == null) {
      return;
    }

    if (!userData.player!.isAdmin) {
      return;
    }

    if (userData.player!.game.bStart) {
      return;
    }

    userData.player!.game.changeLady();
  }

  /// Инициализация сообщения смены первого игрока
  static void changeFirstPlayersInit(UserData userData) {
    if (userData.player == null) {
      return;
    }

    if (!userData.player!.isAdmin) {
      return;
    }

    if (userData.player!.game.bStart) {
      return;
    }

    List<Player> players = userData.player!.game.players;

    TelegramSendMessage(userData, "Выберите первого игрока",
        replyMarkup: GenerateButtons.fromPlayers(
            players: players,
            startStringCallback: "!changeFirstPlayers",
            endCommands: Buttons.delete.inlineKeyboard));
  }

  /// Callback отвечающий за перестановку игроков местами
  static Future<void> changeFirstPlayerCallback(
      UserData userData, int messageId, List<String> params) async {
    if (userData.player == null) {
      throw "Вы не в игре";
    }

    if (!userData.player!.isAdmin) {
      throw "Вы больше не администратор!";
    }

    if (userData.player!.game.bStart) {
      throw "Игра уже началась";
    }

    // Игра админа
    AvGame game = userData.player!.game;

    int userIdFirstPlayer = int.parse(params[0]);

    var userDataFirstPlayer = await users.get(userIdFirstPlayer);

    if (userDataFirstPlayer == null) {
      throw "Не могу найти этого игрока";
    }

    if (userDataFirstPlayer.player == null) {
      throw "Этот игрок не в игре";
    }

    if (userDataFirstPlayer.player!.game != game) {
      throw "Этот игрок в другой игре";
    }

    game.changeFirstPlayer(userDataFirstPlayer.player!.index);
    throw "Изменененно";
  }

  /// Инициализация сообщения об перестановке игроков
  static void changeIndexPlayersInit(UserData userData) {
    if (userData.player == null) {
      return;
    }

    if (!userData.player!.isAdmin) {
      return;
    }

    if (userData.player!.game.bStart) {
      return;
    }

    List<Player> players = userData.player!.game.players;

    if (players.length < 5) {
      TelegramSendMessage(userData,
          "Невозможно менять последовательность игроков \\, пока их не будет хотя бы минимальное количество \\(5\\)\\.",
          replyMarkup: Buttons.delete);
      return;
    }

    if (players.length > 12) {
      TelegramSendMessage(userData,
          "Невозможно менять последовательность игроков \\, игроков не может быть больше 12\\.",
          replyMarkup: Buttons.delete);
      return;
    }

    TelegramSendMessage(userData, "Выберите первого игрока",
        replyMarkup: GenerateButtons.fromPlayers(
            players: players,
            startStringCallback: "!changeIndexPlayers",
            endCommands: Buttons.delete.inlineKeyboard,
            convertCallback: (player) => player.index.toString()));
  }

  /// Callback отвечающий за перестановку игроков местами
  static void changeIndexCallback(
      UserData userData, int messageId, List<String> params) {
    if (userData.player == null) {
      throw "Вы не в игре";
    }

    if (!userData.player!.isAdmin) {
      throw "Вы больше не администратор!";
    }

    if (userData.player!.game.bStart) {
      throw "Игра уже началась";
    }

    // Игра админа
    AvGame game = userData.player!.game;

    // ID пользователей
    List<int> usersIndex = params.map((e) => int.parse(e)).toList();

    // Перепроверяем на то, что индекс пользователя меньше чем игроков в игре
    usersIndex =
        usersIndex.where((oneIndex) => game.players.length > oneIndex).toList();

    // Получаем массив пользовательских данных
    List<UserData> usersDataList = usersIndex
        .map<UserData>((oneUserIndex) => game.players[oneUserIndex].userData)
        .toList();

    //  Вычисляем игроков оставшихся игроков
    List<Player> leftPlayer = game.players
        .where((player) => !usersDataList.contains(player.userData))
        .toList();

    if (leftPlayer.length <= 1) {
      usersDataList.addAll(
          leftPlayer.map<UserData>((oneUserData) => oneUserData.userData));
      game.changeIndexFromUserData(usersDataList);
      throw "Измененно";
    } else {
      String message = "Новая последовательность игроков\\: \n";

      for (var oneUserData in usersDataList) {
        message += "${oneUserData.player!}\n";
      }

      message += "\nКто будет следующим?";

      String newParam = "";

      // Отправимм всю последовательность в кнопку
      for (UserData oneUserData in usersDataList) {
        newParam += ">${oneUserData.player!.index}";
      }

      InlineKeyboardMarkup buttons = GenerateButtons.fromPlayers(
        players: leftPlayer,
        startStringCallback: "!changeIndexPlayers$newParam",
        endCommands: Buttons.delete.inlineKeyboard,
        convertCallback: (player) => player.index.toString(),
      );

      TelegramEditMessage(userData.chatId, messageId, message,
          replyMarkup: buttons);
    }
  }

  /// Инициализация сообщения о смене роли добра
  static void changeGoodRoleInit(UserData userData) {
    if (userData.player == null) {
      return;
    }

    if (!userData.player!.isAdmin) {
      return;
    }

    if (userData.player!.game.bStart) {
      return;
    }

    Map<String, String> stringAndCallback = {};

    var goodRole = userData.player!.game.goodRoles;

    for (int i = 0; i < goodRole.length; i++) {
      stringAndCallback[goodRole[i].toString()] = goodRole[i].name;
    }

    var buttons = GenerateButtons.fromStrings(
        stringsAndCallback: stringAndCallback,
        endCommands: Buttons.delete.inlineKeyboard,
        startStringCallback: "!changeGood");

    TelegramSendMessage(userData, "Выберете кого заменить?",
        replyMarkup: buttons);
  }

  /// Callback сообщения о смене роли добра
  static void changeGoodRoleCallback(
      UserData userData, int messageId, List<String> params) {
    if (userData.player == null) {
      throw "Вы не в игре";
    }

    if (!userData.player!.isAdmin) {
      throw "Вы больше не администратор!";
    }

    if (userData.player!.game.bStart) {
      throw "Игра уже началась";
    }

    // Если только один параметр, то выбрали кого заменяем. Генереируем сообщение на "кем заменим"
    if (params.length == 1) {
      Map<String, String> stringAndCallback = {};

      Role.namesAndEmojiGoodRoles.forEach((name, emoji) {
        stringAndCallback['$emoji $name'] = name;
      });

      var button = GenerateButtons.fromStrings(
          stringsAndCallback: stringAndCallback,
          startStringCallback: "!changeGood>${params[0]}",
          endCommands: Buttons.delete.inlineKeyboard);

      TelegramEditMessage(
          userData.chatId, messageId, "На кого заменить ${params[0]}\\?",
          replyMarkup: button);

      return;
    }
    // Если пришло два параметра, то выбрано на кого и кем. А значит проверяем и создаем
    else {
      TelegramDeleteMessage(userData.chatId, messageId);
      var game = userData.player!.game;

      // Находим индекс заменяемой роли
      int count = game.goodRoles.indexWhere((role) => role.name == params[0]);

      // Если не нашли
      if (count == -1) throw "Заменяемая роль не найдена";

      game.goodRoles[count] = Role.fromName(params[1], game) as Good;
      game.goodRoles.sort((good1, good2) => good1.sortValue - good2.sortValue);
      game.playersRefreshMessage();
    }
  }

  /// Инициализация сообщения о смене роли добра
  static void changeEvilRoleInit(UserData userData) {
    if (userData.player == null) {
      return;
    }

    if (!userData.player!.isAdmin) {
      return;
    }

    if (userData.player!.game.bStart) {
      return;
    }

    Map<String, String> stringAndCallback = {};

    var evilRole = userData.player!.game.evilRoles;

    for (int i = 0; i < evilRole.length; i++) {
      stringAndCallback[evilRole[i].toString()] = evilRole[i].name;
    }

    var buttons = GenerateButtons.fromStrings(
        stringsAndCallback: stringAndCallback,
        endCommands: Buttons.delete.inlineKeyboard,
        startStringCallback: "!changeEvil");

    TelegramSendMessage(userData, "Выберете кого заменить?",
        replyMarkup: buttons);
  }

  /// Callback сообщения о смене роли добра
  static void changeEvilRoleCallback(
      UserData userData, messageId, List<String> params) {
    if (userData.player == null) {
      throw "Вы не в игре";
    }

    if (!userData.player!.isAdmin) {
      throw "Вы больше не администратор!";
    }

    if (userData.player!.game.bStart) {
      throw "Игра уже началась";
    }

    // Если только один параметр, то выбрали кого заменяем. Генереируем сообщение на "кем заменим"
    if (params.length == 1) {
      Map<String, String> stringAndCallback = {};

      Role.namesAndEmojiEvilRoles.forEach((name, emoji) {
        stringAndCallback['$emoji $name'] = name;
      });

      var button = GenerateButtons.fromStrings(
          stringsAndCallback: stringAndCallback,
          startStringCallback: "!changeEvil>${params[0]}",
          endCommands: Buttons.delete.inlineKeyboard);

      TelegramEditMessage(
          userData.chatId, messageId, "На кого заменить ${params[0]}\\?",
          replyMarkup: button);

      return;
    }
    // Если пришло два параметра, то выбрано на кого и кем. А значит проверяем и создаем
    else {
      TelegramDeleteMessage(userData.chatId, messageId);
      var game = userData.player!.game;

      // Находим индекс заменяемой роли
      int count = game.evilRoles.indexWhere((role) => role.name == params[0]);

      // Если не нашли
      if (count == -1) throw "Заменяемая роль не найдена";

      game.evilRoles[count] = Role.fromName(params[1], game) as Evil;
      game.evilRoles.sort((good1, good2) => good1.sortValue - good2.sortValue);
      game.playersRefreshMessage();
    }
  }

  /// Игровой Callback, передаем в игру
  static void gameCallback(
      UserData userData, String command, List<String> params) {
    if (userData.player == null) throw "Error!";
    AvGame game = userData.player!.game;
    if (!game.bStart) throw "Error!";
    if (game.turn == null) throw "Error!";
    if (!game.turn!.isActivePlayer(userData.player!)) throw "Error!";

    game.turn!.callback(userData.player!, command, params);
  }

  /// Пользователь пытается поменять имя
  static void changeName(UserData userData, String newName) async {
    if (userData.player != null) {
      TelegramSendMessage(userData,
          "Невозможно изменить имя\\, находясь в игровой комнате\\. Сначала выйдете из нее\\.",
          replyMarkup: Buttons.delete);
      return;
    }

    String? name = correctName(newName);

    if (name == null) {
      TelegramSendMessage(userData, "Некорректное имя\\: $newName",
          replyMarkup: Buttons.delete);
      return;
    } else {
      userData.name = name;
      users.update(userData);

      TelegramSendMessage(userData, "Ваше имя измененно на ${userData.name}",
          replyMarkup: Buttons.delete);

      refreshUser(userData);
      return;
    }
  }

  /// Проверка и проеобразование именни в коректное (удаление лишних символов и пробелов) null если это не возможно
  static String? correctName(String name) {
    String newName = "";
    // Проверяем на кореректность Можно вводить только ангийские и русские буквы с одним пробелом

    RegExp regExp = RegExp(r'([A-Za-zа-яА-я]+|[ _]+)');

    List<RegExpMatch> matches = regExp.allMatches(name).toList();

    // Убрали все лишние символы и лишние пробелы
    for (var element in matches) {
      if (element[0]![0] == " " || element[0]![0] == "_") {
        newName += " ";
      } else {
        newName += element[0]!;
      }
    }

    // Если Начинается пробелами удаляем
    newName = newName.replaceAll(RegExp(r'^ +'), '');

    // Если длинна больше 20 символов обрезаем
    if (newName.length > 20) {
      newName = newName.substring(0, 20);
    }

    // Если оканчивается пробелами удаляем
    newName = newName.replaceAll(RegExp(r' +$'), '');

    // Если получившиеся строка меньше 2 символов
    if (newName.length < 2) {
      return null;
    } else {
      return newName;
    }
  }

  /// Проверка, не сменилось ли username
  static Future<void> checkUsername(UserData userData, User user) async {
    if (userData.username != user.username) {
      userData.username = user.username;
      users.update(userData);
      // await users.rewrite(userData.copyWidth(username: user.username));
    }
  }

  /// Функция осщкствляющая проверку неиспользуемых игр
  static void _autoDeleteGameInit() async {
    Future.doWhile(() async {
      await Future.delayed(Duration(minutes: 30));

      var games = codeGames.values.toList();
      var now = DateTime.now();

      for (var oneGame in games) {
        /// Если игра запущена не трогаем ее
        if (oneGame.bStart) {
          continue;
        }

        if (oneGame.createDateTime.difference(now).inMinutes >= 40) {
          oneGame.deleteGame();
        }
      }

      return true;
    });
  }

  static void adminTelegramMessage(UserData userData) async {
    if (admin_users.contains(userData.userId) == false) {
      return;
    }

    String msg = "";

    int allCountUser = await users.getCountAllUsers();
    msg += "Всего пользователей\\: $allCountUser";
    msg += "\nАктивных пользователей\\: ${users.users.length}";
    msg += "\nАктивных игр\\: ${codeGames.length}";

    if (codeGames.isNotEmpty) {
      msg += "\n\nЧтобы подсмотреть /show или /showm с номером игры\nИгры\\:\n";

      for (var oneGame in codeGames.values) {
        if (oneGame.bStart) {
          msg += '🎮 ';
        } else {
          msg += '🔢 ';
        }

        msg += '`${oneGame.gameCode}` \\: ${oneGame.players.length} игроков';
      }
    }

    TeleBot.sendMessage(userData, msg, replyMarkup: Buttons.delete);
  }

  static void adminShowGame(UserData userData, String codeGame) {
    if (admin_users.contains(userData.userId) == false) {
      return;
    }

    codeGame = codeGame.toUpperCase();

    if (!codeGames.containsKey(codeGame)) {
      TeleBot.sendMessage(userData, "Игра не найдена",
          replyMarkup: Buttons.delete);
      return;
    }

    TeleBot.sendMessage(
        userData, "`$codeGame`\n${codeGames[codeGame]!.gameMainMessage}",
        replyMarkup: Buttons.delete);
  }

  static void adminShowMoreGame(UserData userData, String codeGame) {
    if (admin_users.contains(userData.userId) == false) {
      return;
    }

    codeGame = codeGame.toUpperCase();

    if (!codeGames.containsKey(codeGame)) {
      TeleBot.sendMessage(userData, "Игра `$codeGame` не найдена",
          replyMarkup: Buttons.delete);
      return;
    }

    var game = codeGames[codeGame]!;

    String text = game.stringMoreInformation;

    TeleBot.sendMessage(userData, "`$codeGame`\n$text",
        replyMarkup: Buttons.delete);
  }
}
