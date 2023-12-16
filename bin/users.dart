import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/database.dart';
import 'package:firebase_dart/implementation/pure_dart.dart';

import 'a_game.dart';

class UserData {
  UserData({
    required this.userId,
    required this.chatId,
    required this.name,
    this.username,
    this.mainMessage,
  }) {
    lastAction = DateTime.now();
  }

  factory UserData.fromJsonMap(dynamic input) {
    Map<String, dynamic> map = input as Map<String, dynamic>;
    int userId = map["userId"] as int;
    int chatId = map["chatId"] as int;
    int? mainMessage = map['mainMessage'] as int?;
    String name = map['name'] as String;
    String? username = map['username'] as String?;

    return UserData(
        chatId: chatId,
        userId: userId,
        mainMessage: mainMessage,
        name: name,
        username: username);
  }

  Map<String, dynamic> toJsonMap() {
    Map<String, dynamic> map = {};
    map['userId'] = userId;
    map['chatId'] = chatId;
    map['name'] = name;
    if (mainMessage != null) {
      map['mainMessage'] = mainMessage;
    }
    if (username != null) {
      map['username'] = username;
    }

    return map;
  }

  final int userId;
  final int chatId;
  String? username;
  DateTime lastAction = DateTime.now();

  int? mainMessage;
  String name;
  Player? player;
  AvGame? inviteGame;

  // UserData copyWidth({
  //   int? userId,
  //   int? chatId,
  //   String? name,
  //   String? username,
  //   int? mainMessage,
  // }) {
  //   return UserData(
  //       userId: userId ?? this.userId,
  //       chatId: chatId ?? this.chatId,
  //       name: name ?? this.name,
  //       username: username ?? this.username,
  //       mainMessage: mainMessage ?? this.mainMessage);
  // }

  String get url {
    if (username != null) {
      return '*[$name](https://t.me/$username)*';
    } else {
      return '*[$name](tg://user?id=$userId)*';
    }
  }

  String urlText(String text) {
    if (username != null) {
      return '*[$text](https://t.me/$username)*';
    } else {
      return '*[$text](tg://user?id=$userId)*';
    }
  }

  @override
  String toString() {
    return name;
  }
}

class BotUserData extends UserData {
  BotUserData(int chatId, {String? name})
      : super(
            chatId: chatId,
            name: name ?? "Bot $countBot",
            userId: countBot,
            username: "DrusBr") {
    countBot++;
  }

  @override
  String get url => urlText(name);

  static int countBot = 1;
}

Map<int, BotUserData> botsUser = {};

/// MessageId и бот котрый ему соответсвует
Map<int, BotUserData> botMessages = {};

// Users users = Users();
FireUsers users = FireUsers.instance;

/// Реализация пользователей через Firebase
class FireUsers {
  FireUsers._();

  static final _instance = FireUsers._();
  static FireUsers get instance => _instance;

  late DatabaseReference _dbRefUsers;
  late FirebaseDatabase _database;


  Future<void> init() async {
    const firebaseConfig = {
      'apiKey': "AIzaSyCs78eneaSM21RdsyQWd2gvYrc8PGKEl24",
      'authDomain': "avalon-8c1ce.firebaseapp.com",
      'databaseURL': "https://avalon-8c1ce-default-rtdb.firebaseio.com",
      'projectId': "avalon-8c1ce",
      'storageBucket': "avalon-8c1ce.appspot.com",
      'messagingSenderId': "425217874051",
      'appId': "1:425217874051:web:ae60a777573bc54d62a3b6",
      'measurementId': "G-XJKGDPZ3D0"
    };

    FirebaseDart.setup();

    var app = await Firebase.initializeApp(
        options: FirebaseOptions.fromMap(firebaseConfig));

    _database = FirebaseDatabase(
      app: app,
    );

    _dbRefUsers = _database.reference().child("users");

    _dbRefUsers.onChildChanged.listen((event) {
      // print("DataBase changed : ${event.snapshot.key} : ${event.snapshot.value}");
    });

    // Запускаем механизм очистки неактивных пользователей из памяти
    _autoClearUsersInRam();
  }

  Map<int, UserData> users = {};

  /// Обновить/Добавить пользователя локально и на сервере
  void update(UserData userData) {
    //TODO: Убрать ботов
    if (userData is BotUserData) {
      botsUser[userData.userId] = userData;
      return;
    }

    users[userData.userId] = userData;
    _putServer(userData);
  }

  /// Получить UserData по ID
  Future<UserData?> get(int userId) async {
    //TODO: Убрать ботов
    if (botsUser.containsKey(userId)) {
      return botsUser[userId];
    }

    // Если пользовательские данные уже есть в памяти
    if (users.containsKey(userId)) {
      var userData = users[userId]!;
      userData.lastAction = DateTime.now();
      return userData;
    }

    // Если нет, пытаемся найти на сервере
    UserData? loadUser = await _getServer(userId);

    // Если что-то нашли, так же добавляем и в оперативную память
    if (loadUser != null) {
      users[loadUser.userId] = loadUser;
    }

    return loadUser;
  }

  /// Получить UserData с сервера
  Future<UserData?> _getServer(int userId) async {
    
    await _databaseConnect();

    dynamic inputJsonMap = await _dbRefUsers.child(userId.toString()).get();

    if (inputJsonMap == null) {
      return null;
    }

    if (inputJsonMap is! Map<String, dynamic>) {
      return null;
    }


    return UserData.fromJsonMap(inputJsonMap);
  }

  /// Загрузить на сервер
  Future<void> _putServer(UserData userData) async {    
    await _databaseConnect();



    // await _dbRefUsers
    //     .child(userData.userId.toString())
    //     .set(userData.toJsonMap());

    await _dbRefUsers.child(userData.userId.toString()).update(userData.toJsonMap());


  }

  /// Функция автоудаления пользователей из памяти, которые давно не используются
  Future<void> _autoClearUsersInRam() async {
    Future.doWhile(() async {
      DateTime now = DateTime.now();
      List<UserData> usersData = users.values.toList();

      for (var oneUserData in usersData) {
        // Если пользователи в игре или с приглашением не трогаем их
        if (oneUserData.player != null || oneUserData.inviteGame != null) {
          continue;
        }

        // Если пользователь не активен уже больше чем 2 часа, удаляем его
        if (now.difference(oneUserData.lastAction).inHours.abs() >= 2) {
          users.remove(oneUserData.userId);
        }
      }

      await Future.delayed(Duration(minutes: 10));

      return true;
    });
  }

  Future<int> getCountAllUsers() async {
    dynamic allUsersOneObject = await _dbRefUsers.get();

    if (allUsersOneObject is! Map<String, dynamic>) {
      return 0;
    }

    return (allUsersOneObject as Map<String, dynamic>).length;
  }

  Future<void> _databaseConnect() {
    return _database.goOnline();
  }

  Future<void> _databaseDiconnect() {
    return _database.goOffline();
  }
}
