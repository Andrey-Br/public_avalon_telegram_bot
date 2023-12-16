import 'package:dart_telegram_avalon/inline_buttons.dart';
import 'package:teledart/model.dart';
import 'a_game.dart';

abstract class GenerateButtons {
  static InlineKeyboardMarkup fromStrings(
      {String startStringCallback = "",
      required Map<String, String> stringsAndCallback,
      List<List<InlineKeyboardButton>>? endCommands}) {
    List<List<InlineKeyboardButton>> arrayButton = [[]];

    for (var key in stringsAndCallback.keys) {
      arrayButton.add(<InlineKeyboardButton>[
        InlineKeyboardButton(
            text: key,
            callbackData: "$startStringCallback>${stringsAndCallback[key]}")
      ]);
    }

    endCommands ??= Buttons.empty.inlineKeyboard;

    arrayButton.addAll(endCommands);

    return InlineKeyboardMarkup(inlineKeyboard: arrayButton);
  }

  static InlineKeyboardMarkup fromPlayers(
      {String startStringCallback = "",
      required Iterable<Player> players,
      List<List<InlineKeyboardButton>>? endCommands,
      String Function(Player)? convertCallback}) {
    Map<String, String> mapPlayers = {};

    convertCallback ??= (p) => "${p.userData.userId}";

    for (var player in players) {
      mapPlayers[player.name] = convertCallback(player);
    }

    return fromStrings(
        stringsAndCallback: mapPlayers,
        startStringCallback: startStringCallback,
        endCommands: endCommands);
  }
}
