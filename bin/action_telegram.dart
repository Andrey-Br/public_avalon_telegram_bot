import 'dart:async';
import 'package:dart_telegram_avalon/inline_buttons.dart';
import 'package:teledart/model.dart';
import 'telebot.dart';
import 'users.dart';

abstract class TelegramAction<T> {
  TelegramAction() {
    TelegramActionQueue.addAction(this);
  }

  final StreamController<T> streamControllerAnswer = StreamController<T>();

  Future<void> _actionFunction() async {}

  void _setAnswer(T result) {
    streamControllerAnswer.add(result);
  }

  Future<T> get answer async {
    T result = await streamControllerAnswer.stream.first;
    streamControllerAnswer.close();
    return result;
  }
}

/// Удалить сообщение и узнать успешно или нет
class TelegramDeleteMessage extends TelegramAction<bool> {
  final int chatId;
  final int messageId;
  final void Function()? onError;

  /// Пока что удаляем без задержки
  TelegramDeleteMessage(this.chatId, this.messageId, {this.onError}) {
    try {
      TeleBot.deleteMessage(chatId, messageId)
          .then((value) => _setAnswer(value))
          .onError((error, stackTrace) => throw "");
    } catch (_) {
      if (onError != null) {
        onError!();
      }
    }
  }

  @override
  Future<void> _actionFunction() async {
    // try {
    //   var result = await TeleBot.deleteMessage(chatId, messageId)
    //       .onError((error, stackTrace) => throw "");
    //   _setAnswer(result);
    // } catch (_) {
    //   if (onError != null) {
    //     onError!();
    //   }
    // }
  }
}

/// Изменить сообщение и узнать успешно или нет
class TelegramEditMessage extends TelegramAction<bool> {
  final int chatId;
  final int messageId;
  final String text;
  final InlineKeyboardMarkup? replyMarkup;
  final String? parseMode;
  final void Function()? onError;

  TelegramEditMessage(this.chatId, this.messageId, this.text,
      {InlineKeyboardMarkup? replyMarkup,
      this.parseMode = "MarkdownV2",
      this.onError})
      : replyMarkup = replyMarkup ?? Buttons.empty,
        super();

  @override
  Future<void> _actionFunction() async {
    try {
      var result = await TeleBot.updateTextMessage(chatId, messageId, text,
          replyMarkup: replyMarkup, parseMode: parseMode);
      _setAnswer(result);
    } catch (_) {
      if (onError != null) {
        onError!();
      }
    }
  }
}

/// Изменить главное сообщение и узнать успешно или нет
class TelegramEditMainMessage extends TelegramAction<bool> {
  final UserData userData;
  final String text;
  final InlineKeyboardMarkup? replyMarkup;
  final bool resend;
  final String? parseMode;
  final void Function()? onError;

  TelegramEditMainMessage(
      this.userData, this.text, InlineKeyboardMarkup? replyMarkup,
      {this.resend = false, this.parseMode = "MarkdownV2", this.onError})
      : replyMarkup = replyMarkup = replyMarkup ?? Buttons.empty,
        super();

  @override
  Future<void> _actionFunction() async {
    try {
      var result = await TeleBot.updateTextMainMessage(userData, text,
          replyMarkup: replyMarkup, resend: resend, parseMode: parseMode);
      _setAnswer(result);
    } catch (o) {
      print("updateMainMessage Error: ${o.toString()}");
      if (onError != null) {
        onError!();
      }
    }
  }
}

/// Отправить сообщение и узнать успешно или нет
class TelegramSendMessage extends TelegramAction<bool> {
  final bool delete;
  final Duration duration;
  final ReplyMarkup? replyMarkup;
  final String? parseMode;
  final UserData userData;
  final String text;
  final void Function(bool delete)? onAutoDelete;
  final void Function()? onError;

  TelegramSendMessage(this.userData, this.text,
      {this.delete = true,
      this.duration = const Duration(minutes: 2),
      ReplyMarkup? replyMarkup,
      this.parseMode = "MarkdownV2",
      // Функция вызывается при автоудалении при этом true если успешно, false если ошибка (Скорее всего сообщение уже удалено)
      this.onAutoDelete,
      this.onError})
      : replyMarkup = replyMarkup ?? Buttons.empty,
        super();

  @override
  Future<void> _actionFunction() async {
    try {
      var result = await TeleBot.sendMessage(userData, text,
              delete: delete,
              parseMode: parseMode,
              duration: duration,
              onAutoDelete: onAutoDelete,
              replyMarkup: replyMarkup)
          .onError((error, stackTrace) => throw "");
      _setAnswer(result);
    } catch (_) {
      if (onError != null) {
        onError!();
      }
    }
    return;
  }
}

/// Отправить сообщение и получить его, после того как это произошло
class TelegramSendAndGetMeesage extends TelegramAction<Message> {
  final bool delete;
  final Duration duration;
  final ReplyMarkup? replyMarkup;
  final String? parseMode;
  final UserData userData;
  final String text;
  final void Function(bool delete)? onAutoDelete;
  final void Function()? onError;

  TelegramSendAndGetMeesage(this.userData, this.text,
      {this.delete = true,
      this.duration = const Duration(minutes: 2),
      ReplyMarkup? replyMarkup,
      this.parseMode = "MarkdownV2",
      // Функция вызывается при автоудалении при этом true если успешно, false если ошибка (Скорее всего сообщение уже удалено)
      this.onAutoDelete,
      this.onError})
      : replyMarkup = replyMarkup ?? Buttons.empty,
        super();

  @override
  Future<void> _actionFunction() async {
    try {
      var result = await TeleBot.sendAndGetMessage(userData, text,
              delete: delete,
              parseMode: parseMode,
              duration: duration,
              onAutoDelete: onAutoDelete,
              replyMarkup: replyMarkup)
          .onError((error, stackTrace) => throw "");
      _setAnswer(result);
    } catch (_) {
      if (onError != null) {
        onError!();
      }
    }
    return;
  }
}

//Класс осуществляюищий очередь для совершенния действий в телеграм и замедляющий отправку множественных сообщений, чтобы не сработала защита от DDOS
abstract class TelegramActionQueue {
  static StreamController<TelegramAction> streamController = StreamController();
  static Stream<TelegramAction> get stream => streamController.stream;

  static Future<void> init() async {
    await for (TelegramAction action in stream) {
      action._actionFunction();

      /// TODO: Поставить задержку в 40 милисекунд, когда уберем ботов
      // await Future.delayed(Duration(seconds: 1));
      await Future.delayed(Duration(milliseconds: 40));
    }
  }

  static void addAction(TelegramAction action) {
    streamController.add(action);
  }
}
