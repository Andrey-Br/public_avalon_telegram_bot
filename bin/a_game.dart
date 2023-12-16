import 'package:dart_telegram_avalon/inline_buttons.dart';
import 'package:teledart/model.dart';
import 'action_telegram.dart';
import 'generate_buttons.dart';
import 'messages.dart';
import 'roles.dart';
import 'a_game_controller.dart';
import 'users.dart';
import 'utils.dart';

class GameSettings {
  const GameSettings(this.playersInTurn, this.countEvil, this.twoFail);

  final List<int> playersInTurn;
  final int countEvil;
  final bool twoFail;
}

const Map<int, GameSettings> _gameSettings = {
  5: GameSettings([2, 3, 2, 3, 3], 2, false),
  6: GameSettings([2, 3, 4, 3, 4], 2, false),
  7: GameSettings([2, 3, 3, 4, 4], 3, true),
  8: GameSettings([3, 4, 4, 5, 5], 3, true),
  9: GameSettings([3, 4, 4, 5, 5], 3, true),
  10: GameSettings([3, 4, 4, 5, 5], 4, true),
  11: GameSettings([3, 4, 5, 6, 5], 4, true),
  12: GameSettings([3, 4, 5, 6, 5], 5, true)
};

class Player {
  Player(this._game, this.userData, [Role? role]) {
    this.role = role ?? Role(_game);
  }

  String get name {
    if (role is Arthur) {
      return "${Arthur.emoj} ${index + 1} ${userData.name}";
    } else {
      return '${index + 1} ${userData.name}';
    }
  }

  bool get isTurn => index == game.countTurnPlayer;
  final UserData userData;
  LadyAnswer? ladyAnswer;
  final AvGame _game;
  late Role role;
  String get url {
    if (role is Arthur) {
      return userData.urlText(name);
    } else {
      return userData.urlText(name);
    }
  }

  int get index => _game.players.indexOf(this);
  AvGame get game => _game;
  bool get isAdmin => userData == game.adminUserData;
  List<Player> get vision => role.vision();

  String roleMessage() {
    String messages = "";

    messages += "${userData.url}\\, Ваша роль \\: ${role.toString()}\n";

    messages += role.aboutRole;
    messages += "\n";
    List<Player> playersVision = role.vision();

    if (playersVision.isNotEmpty) {
      messages += "\nИгроки\\, которые известны Вам\\:\n";

      for (var onePlayer in playersVision) {
        messages += "${onePlayer.url} \n";
      }
    }

    return messages;
  }

  @override
  String toString() {
    return url;
  }

  InlineKeyboardMarkup? getButtons() {
    if (game.bStart) {
      return Buttons.gameMainMassage;
    } else {
      if (isAdmin) {
        return Buttons.admin;
      } else {
        return Buttons.leave;
      }
    }
  }

  String generateMainMessage() {
    return game.gameMainMessage;
  }
}

/// Общий тип хода
abstract class Turn {
  final AvGame game;
  List<Player> actionsPlayers = [];
  String get messageChat => "Turn";
  void callback(Player player, String command, List<String> params) {}
  Turn(this.game);
  bool isCompleted = false;

  bool isActivePlayer(Player player) => actionsPlayers.contains(player);
  Map<Player, int> messageIdFromPlayer = {};

  String get resultString => "rsult Turn";

  String generateMessage(Player player) => "Turn";
  InlineKeyboardMarkup generateButton(Player player) => Buttons.delete;

  void initAllMessages() {
    for (var player in actionsPlayers) {
      initSecondMessage(player);
    }
  }

  void completeThisTurn() {
    isCompleted = true;
    actionsPlayers.clear();
  }

  void deleteSecondMessage(Player player) {
    TelegramDeleteMessage(player.userData.chatId, messageIdFromPlayer[player]!);
  }

  void refreshSecondMessage(Player player) {
    TelegramEditMessage(player.userData.chatId, messageIdFromPlayer[player]!,
        generateMessage(player), replyMarkup: generateButton(player),
        onError: () {
      initSecondMessage(player);
    });
  }

  void reSendSecondMessage(Player player) {
    deleteSecondMessage(player);
    initSecondMessage(player);
  }

  void initSecondMessage(Player player) async {
    try {
      var sendMessage = TelegramSendAndGetMeesage(
          player.userData, generateMessage(player),
          replyMarkup: generateButton(player),
          duration: Duration(hours: 2), onAutoDelete: (b) {
        if (b) {
          game.deleteGame();
        }
      }, onError: () {
        throw "";
      });

      var msg = await sendMessage.answer;

      messageIdFromPlayer[player] = msg.messageId;
    } catch (_) {
      game.deleteGame();
    }
  }
}

/// Вопрос Русалки
class LadyAsk extends Turn {
  LadyAsk(super.game) {
    if (game.ladyPlayer == null) {
      game.nextTurn();
      return;
    }
    playerLady = game.ladyPlayer!;
    actionsPlayers = [playerLady!];
  }

  Player? playerLady;
  Player? playerAnswer;

  @override
  String get resultString => "🧜‍♀️ $playerLady хочет проверить $playerAnswer";

  @override
  String get messageChat =>
      "🧜‍♀️ $playerLady выбирает,сторону какого игрока хочет узнать\\. ";

  @override
  String generateMessage(Player player) {
    if (playerAnswer == null) {
      return "Ход русалки\\! 🧜‍♀️\nВыберите игрока\\.\nВы узнаете принадлежит этот игрок к силам Добра или к силам Зла\\. Русалка перейдет к этому игроку\\.";
    } else {
      return "Вы уверены\\,что хотите узнать сторону этого игрока\\?\n ${playerAnswer!.url}";
    }
  }

  @override
  InlineKeyboardMarkup generateButton(Player player) {
    if (playerAnswer == null) {
      return GenerateButtons.fromPlayers(
          players: game.players
              .where((pl) => (pl.ladyAnswer == null && pl != playerLady)),
          startStringCallback: "#ladyAsk",
          convertCallback: (pl) => "${pl.index}");
    } else {
      return InlineKeyboardMarkup(inlineKeyboard: [
        Buttons.gameAccept.inlineKeyboard[0],
        Buttons.gameReset.inlineKeyboard[0]
      ]);
    }
  }

  @override
  void callback(Player player, String command, List<String> params) {
    switch (command) {
      case '#ladyAsk':
        playerAnswer = game.players[int.parse(params[0])];
        break;

      case "#reset":
        playerAnswer = null;
        break;

      case "#accept":
        if (playerAnswer == null) {
          reSendSecondMessage(player);
          return;
        }

        if (playerAnswer!.ladyAnswer != null) {
          reSendSecondMessage(player);
          return;
        }

        deleteSecondMessage(player);
        completeThisTurn();
        game.nextTurn(
            newTurn: LadyAnswer(game, playerLady!, playerAnswer!),
            sendResult: false);
        return;
    }

    refreshSecondMessage(player);
  }
}

/// Ответ Русалки
class LadyAnswer extends Turn {
  final Player playerLady;
  final Player answerPlayer;
  bool? answer;
  bool? result;

  LadyAnswer(super.game, this.playerLady, this.answerPlayer) {
    playerLady.ladyAnswer = this;
    game.ladyPlayer = answerPlayer;
    actionsPlayers = [answerPlayer];
  }

  @override
  String get messageChat =>
      "🧜‍♀️ $playerLady хочет узнать сторону игрока $answerPlayer\\.Ожидание ответа\\.\\.\\. ";

  // Отрправить ответ игроку который спрашивал
  void messageLady() {
    if (result == null) return;
    TelegramSendMessage(playerLady.userData,
        "$answerPlayer ответил Вам\\, что относится к ${result! ? "Силам Добра\\! 🔆" : "Силам Зла\\! ‼️"}",
        replyMarkup: Buttons.delete);
  }

  @override
  String get resultString =>
      "🧜‍♀️ $playerLady узнал к какой стороне относится игрок $answerPlayer\\. Русалка 🧜‍♀️\\, переходит к игроку $answerPlayer";

  @override
  String generateMessage(Player player) {
    return "🧜‍♀️ $playerLady хочет узнать к какой стороне Вы принадлежите";
  }

  @override
  InlineKeyboardMarkup generateButton(Player player) {
    return Buttons.gameLadyAnswer(player.role.ladyAnswers);
  }

  @override
  void callback(Player player, String command, List<String> params) {
    bool bResult = true;

    switch (command) {
      case '#LadyAnswer+':
        bResult = true;
        break;

      case '#LadyAnswer-':
        bResult = false;

        break;

      default:
        reSendSecondMessage(player);
        return;
    }

    if (!answerPlayer.role.ladyAnswers.contains(bResult)) {
      reSendSecondMessage(player);
      return;
    }

    deleteSecondMessage(player);
    result = bResult;
    messageLady();
    completeThisTurn();
    game.nextTurn(ignoreSendPlayer: [playerLady]);
  }
}

/// Сам поход
class Quest extends Turn {
  final bool twoFail;
  int countFails = 0;
  bool result = true;
  Map<Player, bool> quest = {};
  final List<Player> questPlayers;
  final Player turnPlayer;
  int countArthur = 0;

  /// Инициализируем обновление главного сообщения каждые 2 секунды
  void initUpdateMainMessage() {
    int viewLeftPlayers = actionsPlayers.length;

    Future.doWhile(() async {
      if (viewLeftPlayers != actionsPlayers.length) {
        viewLeftPlayers = actionsPlayers.length;
        if (viewLeftPlayers != 0) {
          game.playersRefreshMessage();
        }
      }

      await Future.delayed(Duration(seconds: 2));
      return actionsPlayers.isNotEmpty;
    });
  }

  Quest(super.game, this.turnPlayer, this.questPlayers,
      {this.twoFail = false}) {
    actionsPlayers = questPlayers.toList();

    initUpdateMainMessage();
  }

  String get questResult {
    String msg = "";
    if (twoFail && countFails == 1) {
      msg += '✅ \\[❌\\]';
    } else if (countFails == 0) {
      msg += '✅';
    } else {
      for (int i = 0; i < countFails; i++) {
        msg += '❌';
      }
    }
    for (int i = 0; i < countArthur; i++) {
      msg += " 👑";
    }
    return msg;
  }

  @override
  String get resultString {
    String msg =
        "Поход от ${turnPlayer.url} \\, результат похода\\:$questResult\n";
    msg += "Участвовавшие игроки\\:\n";
    msg += questPlayers.join("\\, ");
    // for (var onePlayer in questPlayers) {
    //   msg += onePlayer.url;
    //   msg += "\\, ";
    // }
    return msg;
  }

  @override
  String get messageChat {
    String msg = "Ожидание результата похода\\:\n";
    msg += questPlayers.join("\\, ");
    msg += "\n\n Оставшиеся игроки\\:\n${actionsPlayers.join("\\, ")}";
    return msg;
  }

  @override
  String generateMessage(Player player) {
    String msg = "Вы в походе\\! Вместе с вами игроки\\:\n";

    for (var onePlayer
        in questPlayers.where((curPlayer) => curPlayer != player)) {
      msg += '${onePlayer.url}\n';
    }

    msg += "\nВаше решение\\: ";
    return msg;
  }

  @override
  InlineKeyboardMarkup generateButton(Player player) {
    List<bool> variable = player.role.questAnswers;
    variable.shuffle();
    return Buttons.gameVoteQuest(variable);
  }

  @override
  void callback(Player player, String command, List<String> params) {
    late bool answerPlayer;
    switch (command) {
      case "#VoteQuest-":
        answerPlayer = false;
        break;

      case '#VoteQuest+':
        answerPlayer = true;
        break;

      default:
        reSendSecondMessage(player);
        return;
    }

    if (!player.role.questAnswers.contains(answerPlayer)) {
      reSendSecondMessage(player);
      return;
    }

    //  Обозначаем что король ходил в поход
    if (player.role is Arthur) {
      (player.role as Arthur).bRunQuest = true;
      countArthur++;
    }

    quest[player] = answerPlayer;
    actionsPlayers.remove(player);
    deleteSecondMessage(player);

    if (actionsPlayers.isEmpty) {
      completeThisTurn();
      return;
    }

    // game.playersRefreshMessage();
  }

  @override
  void completeThisTurn() {
    super.completeThisTurn();
    quest.forEach((key, value) {
      if (!value) countFails++;
    });

    result = countFails <= (twoFail ? 1 : 0);

    game.quests.add(this);
    game.nextTurn();
  }
}

/// Игрок выбирает кто пойдет в поход
class Invite extends Turn {
  final Player turnPlayer;
  List<Player> invatedPlayers = [];
  final int countPlayers;
  VoteInvite? voteInvite;
  final bool twoFails;

  Invite(super.game, this.turnPlayer, this.countPlayers,
      {this.twoFails = false}) {
    actionsPlayers = [turnPlayer];
  }

  @override
  String get resultString =>
      "$turnPlayer назначает состав из ${Msg.digitEmoji[countPlayers]} человек\\.";

  @override
  void callback(Player player, String command, List<String> params) {
    switch (command) {
      case "#reset":
        invatedPlayers.clear();
        break;

      case "#accept":
        if (invatedPlayers.length == countPlayers) {
          deleteSecondMessage(player);
          completeThisTurn();
          return;
        }
        break;

      case "#gameSelectInviteQuest":
        int count = int.parse(params[0]);
        Player countPlayer = game.players[count];
        if (!invatedPlayers.contains(countPlayer) &&
            invatedPlayers.length < countPlayers) {
          invatedPlayers.add(countPlayer);
        }
        break;
    }

    refreshSecondMessage(player);
  }

  @override
  InlineKeyboardMarkup generateButton(Player player) {
    // Если уже нужное количество
    if (invatedPlayers.length == countPlayers) {
      return InlineKeyboardMarkup(inlineKeyboard: [
        Buttons.gameAccept.inlineKeyboard[0],
        Buttons.gameReset.inlineKeyboard[0]
      ]);
    }

    //  Оставшиеся игроки
    List<Player> leftPlayer = game.players.where((onePlayer) {
      // Пропускаем короля если он уже ходил
      if (onePlayer.role is Arthur) {
        if ((onePlayer.role as Arthur).bRunQuest) return false;
      }

      if (invatedPlayers.contains(onePlayer)) {
        return false;
      } else {
        return true;
      }
    }).toList();

    return GenerateButtons.fromPlayers(
        players: leftPlayer,
        startStringCallback: "#gameSelectInviteQuest",
        convertCallback: (p) => "${p.index}",
        endCommands: Buttons.gameReset.inlineKeyboard);
  }

  @override
  String generateMessage(Player player) {
    String message = "";

    if (invatedPlayers.isEmpty) {
      return "Выберите $countPlayers\\ игроков\\, которые пойдут в поход\\?";
    }

    message +=
        "Выбранные игроки ${invatedPlayers.length} из $countPlayers \\:\n";
    for (var onePlayer in invatedPlayers) {
      message += "${onePlayer.url}\n";
    }

    return message;
  }

  @override
  void completeThisTurn() {
    super.completeThisTurn();
    invatedPlayers.sort((a, b) => a.index - b.index);
    voteInvite =
        VoteInvite(game, turnPlayer, invatedPlayers, twoFails: twoFails);
    game.nextTurn(newTurn: voteInvite, sendResult: false);
  }

  @override
  String get messageChat =>
      "$turnPlayer выбирает ${Msg.digitEmoji[countPlayers]} игроков в поход";
}

/// Игроки голосуют за назначенный состав
class VoteInvite extends Turn {
  final List<Player> playersQuest;
  Map<Player, bool> playersVote = {};
  final bool twoFails;
  Player turnPlayer;
  Quest? quest;
  int countAgree = 0;
  int countNotAgree = 0;

  VoteInvite(super.game, this.turnPlayer, this.playersQuest,
      {this.twoFails = false}) {
    actionsPlayers = game.players.toList();

    initUpdateMainMessage();
  }

  /// Инициализируем обновление главного сообщения каждые 2 секунды
  void initUpdateMainMessage() {
    int viewLeftPlayers = actionsPlayers.length;

    Future.doWhile(() async {
      if (viewLeftPlayers != actionsPlayers.length) {
        viewLeftPlayers = actionsPlayers.length;
        if (viewLeftPlayers != 0) {
          game.playersRefreshMessage();
        }
      }

      await Future.delayed(Duration(seconds: 2));
      return actionsPlayers.isNotEmpty;
    });
  }

  @override
  String get resultString {
    String msg = "${turnPlayer.userData.url} назначил состав\\:\n";
    msg += playersQuest.toString();
    // for (var onePlayer in playersQuest) {
    //   msg += '${onePlayer.url}\\, ';
    // }
    msg += "\nРезультат голосования\\:\n";

    msg += game.players
        .map<String>(
            (pl) => "${pl.index + 1}\\:${playersVote[pl]! ? '✅' : '🚫'}")
        .toList()
        .toString();

    msg += quest != null
        ? "\n Состав утвержден\\!"
        : "\n Состав не утвержден\\! Ход переходит следующему игроку\\.";

    return msg;
  }

  @override
  String get messageChat =>
      "${turnPlayer.userData.url} предлагает соcтав\\:\n${playersQuest.join("\\, ")}\nИдет голосование\\.\\.\\.\nОжидание игроков\\:\n ${actionsPlayers.join("\\, ")}";

  @override
  String generateMessage(Player player) {
    String msg = "${turnPlayer.userData.url} предлагает соcтав\\:\n";
    for (var onePlayer in playersQuest) {
      msg += "${onePlayer.url}\n ";
    }
    msg += "\nВаш голос за этот состав\\:";
    return msg;
  }

  @override
  InlineKeyboardMarkup generateButton(Player player) {
    return Buttons.gameVoteInvite;
  }

  @override
  void callback(Player player, String command, List<String> params) {
    late bool answer;
    switch (command) {
      case '#VoteInvite+':
        answer = true;
        break;

      case '#VoteInvite-':
        answer = false;
        break;

      default:
        reSendSecondMessage(player);
        return;
    }

    playersVote[player] = answer;
    actionsPlayers.remove(player);
    deleteSecondMessage(player);

    if (actionsPlayers.isEmpty) {
      completeThisTurn();
      return;
    }

    // game.playersRefreshMessage();
  }

  @override
  void completeThisTurn() {
    super.completeThisTurn();
    playersVote.forEach((key, value) {
      if (value) {
        countAgree++;
      } else {
        countNotAgree++;
      }
    });

    if (countAgree > countNotAgree) {
      quest = Quest(game, turnPlayer, playersQuest);
      game.nextTurn(newTurn: quest);
    } else {
      game.nextTurn();
    }
  }
}

/// Поиск Мерлина, при победе добра
class SearchMerlin extends Turn {
  late Player? playerAssasin;
  Player? playerMerlin;

  SearchMerlin(super.game) {
    Player? searchPlayer = game.searchPlayerFromRole<Assasin>();
    searchPlayer ??= game.searchPlayerFromRole<Evil>();

    if (searchPlayer == null) {
      game._endGame(true, text: "Сил Зла не существует\\!");
      playerAssasin = null;
      return;
    }

    playerAssasin = searchPlayer;

    actionsPlayers = [searchPlayer];
  }

  @override
  String get resultString => playerMerlin is Merlin
      ? "Силы тьмы угадали Мерлина\\!"
      : "Силам тьмы не удалось угадать Мерлина\\";

  @override
  String get messageChat => "${playerAssasin?.url} пытается найти Мерлина";

  @override
  String generateMessage(Player player) {
    if (playerMerlin == null) {
      return "Кто по Вашему мнению является Мерлином\\?";
    } else {
      return "Вы думаете Мерлином является игрок $playerMerlin\\?";
    }
  }

  @override
  InlineKeyboardMarkup generateButton(Player player) {
    if (playerMerlin == null) {
      return GenerateButtons.fromPlayers(
          players: game.players
              .where((pl) => (pl.role is Good && pl.role is! Arthur)),
          startStringCallback: "#merlinIs",
          convertCallback: (pl) => "${pl.index}");
    } else {
      return InlineKeyboardMarkup(inlineKeyboard: [
        Buttons.gameAccept.inlineKeyboard[0],
        Buttons.gameReset.inlineKeyboard[0]
      ]);
    }
  }

  @override
  void callback(Player player, String command, List<String> params) {
    switch (command) {
      case '#merlinIs':
        playerMerlin = game.players[int.parse(params[0])];
        break;

      case "#reset":
        playerMerlin = null;
        break;

      case "#accept":
        if (playerMerlin == null) {
          reSendSecondMessage(player);
          return;
        }
        deleteSecondMessage(player);
        if (playerMerlin!.role is Merlin) {
          completeThisTurn();
          game._endGame(false,
              text:
                  "Силы Света выполнили 3 успешных похода\\.\nОднако Силы Тьмы выйграли\\, угадав Мерлина ${playerMerlin!.url} \\!");
          return;
        } else {
          completeThisTurn();
          game._endGame(true,
              text:
                  "Силы Света выполнили 3 успешных похода\\.\nСилы Зла ошиблись\\, посчитав\\, что Мерлином является\\, ${playerMerlin!.url} \\.");
          return;
        }
    }
    refreshSecondMessage(player);
  }
}

/// Игра
class AvGame {
  /// Код Игры
  String gameCode;

  /// Время создания игры
  DateTime createDateTime = DateTime.now();

  /// Пользователи которые получили приглашение
  List<UserData> invitedUserData = [];

  /// Все игроки
  List<Player> players = [];
  GameSettings get settings => _gameSettings[players.length < 5
      ? 5
      : players.length > 12
          ? 12
          : players.length]!;

  int countSkipInvite = 0;

  /// Админинистратор игры
  late UserData adminUserData;

  /// Включена ли руссалка
  bool bLady = false;

  /// Игрок у которого руссалка
  Player? ladyPlayer;

  /// Текущий ход
  Turn? turn;

  /// Какой по счету ход
  int get countTurn => quests.length;

  /// Индекс игрока чей ход
  int countTurnPlayer = 0;

  /// Начата ли Игра
  bool bStart = false;

  /// Походы
  List<Quest> quests = [];

  /// Список всех завершенных действий
  List<Turn> complitedTurns = [];

  ///  Список ролей добра
  List<Good> goodRoles = [];

  /// Список ролей зла
  List<Evil> evilRoles = [];

  /// Действующие роли в игре
  List<Role> roles = [];

  String get stringMoreInformation {
    if (bStart == false) {
      return _generateLobbyMessage;
    }

    String msg = '';

    if (quests.isNotEmpty) {
      msg += "Совершенные походы\\:\n\n";

      for (var oneQuest in quests) {
        msg +=
            " ${oneQuest.turnPlayer.url} назначил ${Msg.digitEmoji[oneQuest.questPlayers.length]} человек\\.";
        msg +=
            "\nРезультат\\: ${oneQuest.questResult}\nУчаствовашие игроки\\:\n";

        for (var onePlayer in oneQuest.questPlayers) {
          msg += " 🔸 ${onePlayer.url} \n";
        }
        msg += "\n";
      }
    }

    msg += "\nРоли добра\\:\n";
    for (var good in goodRoles) {
      msg += "${good.toString()} \\,  ";
    }

    msg += "\nРоли зла\\:\n";
    for (var evil in evilRoles) {
      msg += "${evil.toString()} \\,  ";
    }

    msg += '\nИстория действий\\:\n\n';

    for (var oneTurn in complitedTurns) {
      msg += "${oneTurn.resultString}\n\n";
    }

    msg += "\nСейчас\\:\n";
    msg += turn!.messageChat;
    return msg;
  }

  String get gameMainMessage {
    if (bStart) {
      return _generateGameMessage;
    } else {
      return _generateLobbyMessage;
    }
  }

  String get _generateGameMessage {
    String msg = "";

    for (var onePlayer in players) {
      if (onePlayer == ladyPlayer && onePlayer.isTurn) {
        msg += "🧜‍♀️🚩";
      } else if (onePlayer == ladyPlayer) {
        msg += '🧜‍♀️';
      } else if (onePlayer.isTurn) {
        msg += '🚩';
      } else {
        msg += "▫️";
      }
      msg += onePlayer.url;
      msg += "\n";
    }

    msg += "\nОтклоненные составы\\:\n";
    for (int i = 0; i < 4; i++) {
      msg += countSkipInvite > i ? "🔴" : "⚪️";
    }
    msg += "‼️";

    msg += "\n\nПоходы\\:\n";

    for (int i = 0; i < 5; i++) {
      if (countTurn == i) {
        msg += "➡️";
      } else {
        msg += "▫️";
      }

      msg += ' ${Msg.digitEmoji[settings.playersInTurn[i]]} ';
      if (i == 3 && settings.twoFail) {
        msg += "❗️";
      } else {
        msg += "▫️";
      }
      if (quests.length > i) {
        msg += quests[i].questResult;
        msg += " ";
        msg += quests[i]
            .questPlayers
            .map<int>((player) => player.index + 1)
            .join('\\, ');
      } else {
        msg += "🔲";
      }
      msg += "\n";
    }

    msg += "\nРоли добра\\:\n";
    msg += goodRoles.map<String>((e) => e.emoji).join(' ');

    msg += "\nРоли зла\\:\n";
    msg += evilRoles.map<String>((e) => e.emoji).join(' ');

    msg += "\n\nСейчас\\:\n";
    msg += turn!.messageChat;
    return msg;
  }

  String get _generateLobbyMessage {
    String message =
        "Вы в комнате `${gameCode}`\\.\nАдминистратор ${adminUserData.url} \n";

    message += "Игроки:\n";

    int countLady = 0;

    if (bLady) {
      countLady = (countTurnPlayer + players.length - 1) % players.length;
    } else {
      countLady = -1;
    }

    for (int i = 0; i < players.length; i++) {
      if (i == countLady) {
        message += '🧜‍♀️';
      } else if (i == countTurnPlayer) {
        message += '🚩';
      } else {
        message += '▫️';
      }
      message += "${players[i].url} \n";
    }

    if (invitedUserData.isNotEmpty) {
      message += "Приглашенния:\n";
      for (var inviteUserData in invitedUserData) {
        message += "${inviteUserData.url}\n";
      }
    }

    message += "\nРоли добра:\n";
    message += goodRoles.join("\\, ");

    // message += _game.goodRoles.toString();
    message += "\nРоли зла:\n";
    message += evilRoles.join("\\, ");

    // message += _game.evilRoles.toString();

    return message;
  }

  static Map<int, GameSettings> get gameSettings => _gameSettings;

  // Создать игру с администратором группы и кодом
  AvGame(this.adminUserData, this.gameCode);

  void start() {
    if (bStart) {
      return;
    }

    if (players.length < 5) {
      TelegramSendMessage(
          adminUserData, "В игре не может быть меньше 5 игроков",
          replyMarkup: Buttons.delete);
      return;
    }
    if (players.length > 12) {
      TelegramSendMessage(
          adminUserData, "В игре не может быть больше 12 игроков",
          replyMarkup: Buttons.delete);
      return;
    }

    // Если были приглашения убирем у них ссылки на игру
    for (UserData inviteUserData in invitedUserData) {
      inviteUserData.inviteGame = null;
    }

    invitedUserData.clear();

    countSkipInvite = 0;
    bStart = true;

    roles.addAll(goodRoles);
    roles.addAll(evilRoles);

    for (int i = 0; i < 5; i++) {
      roles.shuffle();
    }

    if (bLady) {
      int indexLady =
          countTurnPlayer == 0 ? players.length - 1 : countTurnPlayer - 1;
      ladyPlayer = players[indexLady];
    }

    // Раздаем роли игрокам
    for (int i = 0; i < players.length; i++) {
      players[i].role = roles[i];
    }

    for (var onePlayer in players) {
      TelegramSendMessage(onePlayer.userData, onePlayer.roleMessage(),
          replyMarkup: Buttons.delete);
    }

    nextTurn(reSendMain: true);
  }

  // Пересоздать игру после завершения
  void reCreateGame() {
    // Удаляем игру из массива игр
    AvGameController.codeGames.remove(gameCode);
    // Генерируем новый ключ
      
    gameCode = Utils.uniquieRandomRoomCode();
    // записываем игру под новым ключом
    AvGameController.codeGames[gameCode] = this;

    // Если были активны какие то игровые сообщения, удаляем
    if (turn != null) {
      for (var onePlayer in turn!.actionsPlayers) {
        turn!.deleteSecondMessage(onePlayer);
      }
    }

    // Удаляем пригашенных игроков
    for (UserData inviteUserData in invitedUserData) {
      inviteUserData.inviteGame = null;
    }

    // Чистим все игровые данные
    quests.clear();
    roles.clear();
    complitedTurns.clear();
    ladyPlayer = null;
    turn = null;
    bStart = false;
    invitedUserData.clear();

    //Пересоздаем роли добра, чтобы обновить в них параметры
    for (int i = 0; i < goodRoles.length; i++) {
      goodRoles[i] =
          Role.fromName(goodRoles[i].name, this) as Good;
    }

    //Пересоздаем роли Зла, чтобы обновить в них параметры
    for (int i = 0; i < evilRoles.length; i++) {
      evilRoles[i] =
          Role.fromName(evilRoles[i].name, this) as Evil;
    }

    // Очищаем параметры игрока
    for (var onePlayer in players) {
      onePlayer.role = Role(this);
      onePlayer.ladyAnswer = null;
    }

    // Обновляем время создания
    createDateTime = DateTime.now();

    playersRefreshMessage(reSend: true);
  }

  void nextTurn(
      {Turn? newTurn,
      bool sendResult = true,
      List<Player>? ignoreSendPlayer,
      bool reSendMain = false}) {
    if (turn == null) {
      turn = Invite(
          this, players[countTurnPlayer], settings.playersInTurn[countTurn]);
      playersRefreshMessage(reSend: reSendMain);
      turn!.initAllMessages();
      return;
    }

    if (sendResult) {
      messageAllPlayers(turn!.resultString, playersIgnore: ignoreSendPlayer);
    }

    complitedTurns.add(turn!);

    // Если передали необходимое действие
    if (newTurn != null) {
      turn = newTurn;
      playersRefreshMessage(reSend: reSendMain);
      turn!.initAllMessages();
      return;
    }

    // Если до этого было голосвание, значит оно провалилось
    if (turn is VoteInvite) {
      countSkipInvite++;
      if (countSkipInvite >= 5) {
        _endGame(false, text: "Состав похода отклонен 5 раз\\!");
        return;
      }
    }

    // Если был квест или голосвание, ход переходит следующему игроку
    if (turn is Quest || turn is VoteInvite) {
      countTurnPlayer = ++countTurnPlayer % players.length;
    }

    if (turn is Quest) {
      countSkipInvite = 0;
      // Подсчитываем успехи и провалы
      int countSuccess = 0;
      int countFail = 0;

      for (var oneQuest in quests) {
        if (oneQuest.result) {
          countSuccess++;
        } else {
          countFail++;
        }
      }

      // Если игра завершилась 3 мя успехами
      if (countSuccess >= 3) {
        if (searchPlayerFromRole<Merlin>() != null) {
          turn = SearchMerlin(this);
          playersRefreshMessage(reSend: reSendMain);
          turn!.initAllMessages();
          return;
        } else {
          _endGame(true, text: "Силы света выполнили 3 успешных похода\\!");
        }
        return;
      }

      // Если игра завершилась 3 мя фейлами
      if (countFail >= 3) {
        _endGame(false, text: "Силы Тьмы выполнили 3 проваленных похода\\!");
        return;
      }

      // Если ход русалки
      if (bLady && countTurn >= 2) {
        turn = LadyAsk(this);
        playersRefreshMessage(reSend: reSendMain);
        turn!.initAllMessages();
        return;
      }
    }
    turn = Invite(
        this, players[countTurnPlayer], settings.playersInTurn[countTurn],
        twoFails: countTurn == 3 ? settings.twoFail : false);
    playersRefreshMessage(reSend: reSendMain);
    turn!.initAllMessages();
  }

  void _endGame(bool result, {String? text}) {
    String msg = "";
    msg +=
        "Игра закончена победой ${result ? "Сил Добра\\! 🔆" : "Сил Зла\\! ‼️"}\n\n";
    if (text != null) {
      msg += text;
      msg += "\n\n";
    }
    msg += "Роли игроков\\:\n\n";
    for (var onePlayer in players) {
      msg +=
          "${onePlayer.role is Good ? "🔆" : "‼️"} ${onePlayer.url} \\( ${onePlayer.role.toString()} \\)\n";
    }

    for (var onePlayer in players) {
      bool isWin = (onePlayer.role is Good) == (result);
      TelegramSendMessage(onePlayer.userData,
          "${isWin ? "Вы выйграли\\! 🥳" : "Вы проиграли\\! 😒"} \n$msg",
          replyMarkup: Buttons.delete);
    }

    reCreateGame();
  }

  // Задать нового администратора группы
  Future<void> changeAdministrator(UserData newAdminUserData) async {
    UserData oldAdministrator = adminUserData;
    adminUserData = newAdminUserData;

    AvGameController.refreshUser(oldAdministrator);

    AvGameController.refreshUser(newAdminUserData);

    TelegramSendMessage(
        adminUserData, "Теперь вы администратор комнаты $gameCode",
        replyMarkup: Buttons.delete);
  }

  /// Включить/ Выключить русалку
  void changeLady() {
    // Если игра уже началась ничего не делаем
    if (bStart) return;

    bool oldbLady = bLady;

    // Если игроков 2 или меньше то русалка выключенна, иначе меняем на противоположное
    if (players.length <= 2) {
      bLady = false;
    } else {
      bLady = !bLady;
    }

    // Если изменолось состояние обновляем пользователей
    if (oldbLady != bLady) {
      playersRefreshMessage();
    }
  }

  /// Сменить первого игрока
  void changeFirstPlayer(int count) {
    // Если игра уже началась ничего не делаем
    if (bStart) return;

    // Если индекс нового пользовталя больше возможного
    if (count >= players.length) return;

    countTurnPlayer = count;
    playersRefreshMessage();
  }

  /// Добавить пользователя по Id
  Player addUser(UserData userData) {
    if (bStart) throw "Game is started";

    var player = Player(this, userData);
    players.add(player);
    regenerateRole(players.length);
    playersRefreshMessage(ignorePlayers: [player]);
    return player;
  }

  /// TODO: Убрать
  /// Добавить игрового бота
  void addTestBot(UserData userData) {
    if (bStart) return;

    BotUserData bot = BotUserData(userData.chatId,
        name: Utils.generateRandomName());

    botsUser[bot.userId] = bot;
    var player = Player(this, bot);
    players.add(player);
    bot.player = player;
    regenerateRole(players.length);
    playersRefreshMessage(ignorePlayers: [player]);
  }

  /// Удалить игрока по индексу
  Future<void> deletePlayerFromIndex(int index, {bool isKick = false}) async {
    if (bStart) return;
    if (index > 0 || index < players.length) {
      return deletePlayer(players[index], isKick: isKick);
    }
  }

  Future<void> deletePlayer(Player player, {bool isKick = false}) async {
    if (!players.contains(player)) return;

    if (player.index == countTurnPlayer) {
      countTurnPlayer = 0;
    }

    players.remove(player);

    if (players.length < 4) bLady = false;

    playersRefreshMessage();

    UserData userData = player.userData;
    userData.player = null;

    await AvGameController.refreshUser(userData);

    if (isKick) {
      TelegramSendMessage(userData, 'Вы были удалены из игры $gameCode',
          replyMarkup: Buttons.delete);
    }

    if (players.isEmpty) {
      deleteGame();
      return;
    }

    if (player.isAdmin) {
      changeAdministrator(players[0].userData);
    }
  }

  void deleteGame() {
    messageAllPlayers("Игра $gameCode была удалена");

    // Удаляем из списка игр
    AvGameController.codeGames.remove(gameCode);

    if (turn != null) {
      for (var onePlayer in turn!.actionsPlayers) {
        turn!.deleteSecondMessage(onePlayer);
      }
    }

    //Удаляем всех пользователей
    for (var player in players) {
      player.userData.player = null;
      AvGameController.refreshUser(player.userData);
    }

    for (var invitedUserData in invitedUserData) {
      invitedUserData.inviteGame = null;
    }

    players.clear();
    invitedUserData.clear();
    roles.clear();
  }

  /// Послать сообщение всем игрокам
  Future<void> messageAllPlayers(String text,
      {List<Player>? playersIgnore}) async {
    for (var onePlayer in players) {
      if (playersIgnore == null) {
        TelegramSendMessage(onePlayer.userData, text,
            replyMarkup: Buttons.delete);
      } else if (!playersIgnore.contains(onePlayer)) {
        TelegramSendMessage(onePlayer.userData, text,
            replyMarkup: Buttons.delete);
      }
    }
  }

  /// Обновить сообщение всех игроков
  void playersRefreshMessage(
      {List<Player>? ignorePlayers, bool reSend = false}) {
    for (var player in players) {
      //if (player.userData is BotUserData) continue;
      if (ignorePlayers == null) {
        AvGameController.refreshUser(player.userData, reSend: reSend);
      } else if (!ignorePlayers.contains(player)) {
        AvGameController.refreshUser(player.userData, reSend: reSend);
      }
    }
  }

  /// Изменить порядок игроков по массиву упользователей
  void changeIndexFromUserData(List<UserData> userDataList) {
    if (bStart) {
      return;
    }

    if (players.length != userDataList.length) {
      return;
    }

    for (Player player in players) {
      if (!userDataList.contains(player.userData)) {
        return;
      }
    }

    players = userDataList.map((oneUserData) => oneUserData.player!).toList();
    countTurnPlayer = 0;
    playersRefreshMessage();
  }

  /// Перегенировать стандартные роли
  void regenerateRole(int countPlayer) {
    var rolesss = generateDefaultRole(countPlayer);
    goodRoles = rolesss.$1;
    evilRoles = rolesss.$2;
  }

  (List<Good>, List<Evil>) generateDefaultRole(int countPlayer) {
    if (countPlayer < 5) countPlayer = 5;
    if (countPlayer > 12) countPlayer = 12;

    switch (countPlayer) {
      case (5):
        return (
          [Merlin(this), Persival(this), Good(this)],
          [Morgan(this), Assasin(this)]
        );

      case (6):
        return (
          [Merlin(this), Persival(this), Good(this), Good(this)],
          [Morgan(this), Assasin(this)]
        );

      case (7):
        return (
          [Merlin(this), Persival(this), Good(this), Good(this)],
          [Morgan(this), Assasin(this), Knight(this)]
        );

      case (8):
        return (
          [Merlin(this), Persival(this), Kay(this), Good(this), Good(this)],
          [Morgan(this), Assasin(this), Knight(this)]
        );

      case (9):
        return (
          [
            Merlin(this),
            Persival(this),
            Kay(this),
            Tristan(this),
            Isolde(this),
            Good(this)
          ],
          [Morgan(this), Nimue(this), Morded(this)]
        );

      case (10):
        return (
          [
            Merlin(this),
            Persival(this),
            Kay(this),
            Tristan(this),
            Isolde(this),
            Good(this)
          ],
          [Morgan(this), Nimue(this), Assasin(this), Morded(this)]
        );

      case (11):
        return (
          [
            Merlin(this),
            Persival(this),
            Kay(this),
            Tristan(this),
            Isolde(this),
            Arthur(this),
            Good(this)
          ],
          [Morgan(this), Nimue(this), Assasin(this), Morded(this)]
        );

      case (12):
        return (
          [
            Merlin(this),
            Persival(this),
            Kay(this),
            Tristan(this),
            Isolde(this),
            Arthur(this),
            Good(this)
          ],
          [Morgan(this), Nimue(this), Assasin(this), Morded(this), Oberon(this)]
        );

      default:
        return ([], []);
    }
  }

  /// Найти игрока с определенной ролью
  Player? searchPlayerFromRole<T extends Role>() {
    for (var onePlayer in players) {
      if (onePlayer.role is T) return onePlayer;
    }
    return null;
  }

  /// Найти определенную роль в списке ролей
  Role? searchRoleIn<T>(List<Role> roles) {
    for (var oneRole in roles) {
      if (oneRole is T) return oneRole;
    }
    return null;
  }
}
