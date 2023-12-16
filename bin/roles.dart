import 'a_game.dart';

class Role {
  Role(this.game);
  final AvGame game;

  List<Player> vision() => [];
  List<bool> get questAnswers => [true, false];
  List<bool> get ladyAnswers => [true, false];
  int get sortValue => 1000;

  static const emoj = "⁉️";
  String get emoji => emoj;
  String get name => "Unknown role";

  String get aboutRole => "Unknown";

  @override
  String toString() {
    return "$emoji Unknown role";
  }

  bool operator >(Role otherRole) => sortValue > otherRole.sortValue;
  bool operator <(Role otherRole) => sortValue < otherRole.sortValue;
  bool operator >=(Role otherRole) => sortValue >= otherRole.sortValue;
  bool operator <=(Role otherRole) => sortValue <= otherRole.sortValue;
}
//

class Good extends Role {
  Good(super.game);

  @override
  List<bool> get questAnswers => [true, true];

  @override
  List<bool> get ladyAnswers => [true, true];

  @override
  int get sortValue => 45;

  static const String cAboutRole =
      "${Good.emoj} ${Good.cname} относится к Силам Добра 🔆\nОн не знает ролей других игроков и просто желает победить Силам Добра🔆\\.";

  static const emoj = "👨‍🌾";
  static const cname = "Помощник";

  @override
  String get aboutRole => cAboutRole;
  @override
  String get emoji => emoj;
  @override
  String get name => cname;

  @override
  String toString() {
    return "$emoji $name";
  }
}

class Evil extends Role {
  Evil(super.game);

  static const String cAboutRole =
      "${Evil.emoj} ${Evil.cname} относится к Силам Зла ‼️\nОн видит роли других игроков Сил Зла‼️\\.";

  @override
  List<bool> get questAnswers => [false, true];

  @override
  List<bool> get ladyAnswers => [false, false];

  @override
  int get sortValue => 90;

  @override
  List<Player> vision() {
    List<Player> evilVision = [];
    for (var player in game.players) {
      Role role = player.role;
      if (role is Evil && role is! Oberon) {
        evilVision.add(player);
      }
    }
    return evilVision;
  }

  static const emoj = "🧟‍♂️";
  static const cname = "Слуга";

  @override
  String get aboutRole => cAboutRole;
  @override
  String get emoji => emoj;
  @override
  String get name => cname;

  @override
  String toString() {
    return "$emoji $name";
  }
}

class Assasin extends Evil {
  @override
  int get sortValue => 75;

  Assasin(super.game);

  static const String cAboutRole =
      "${Assasin.emoj} ${Assasin.cname} относится к Силам Зла ‼️\nОн видит роли других игроков Сил Зла‼️\\.\nКогда Силам Зла ‼️ предстоить найти Мерлина после 3 успешных походов\\, именно ${Assasin.emoj} ${Assasin.cname} будет выбирать игока с ролью Мерлина";

  static const emoj = "🥷";
  static const cname = "Ассасин";

  @override
  String get aboutRole => cAboutRole;
  @override
  String get emoji => emoj;
  @override
  String get name => cname;

  @override
  String toString() {
    return "$emoji $name";
  }
}

class Nimue extends Evil {
  Nimue(super.game);

  @override
  int get sortValue => 55;

  @override
  List<bool> get ladyAnswers => [true, false];

  static const String cAboutRole =
      "${Nimue.emoj} ${Nimue.cname} относится к Силам Зла ‼️\nОн видит роли других игроков Сил Зла‼️\\.\n${Nimue.emoj} ${Nimue.cname} единственный персонаж способный соврать\\, когда его проверяет 🧜‍♀️ русалка";

  static const emoj = "🧞‍♂️";
  static const cname = "Нимуэ";

  @override
  String get aboutRole => cAboutRole;
  @override
  String get emoji => emoj;
  @override
  String get name => cname;

  @override
  String toString() {
    return "$emoji $name";
  }
}

class Morgan extends Evil {
  Morgan(super.game);

  @override
  int get sortValue => 60;

  static const String cAboutRole =
      "${Morgan.emoj} ${Morgan.cname} относится к Силам Зла ‼️\nОна видит роли других игроков Сил Зла‼️\\.\n${Morgan.emoj} ${Morgan.cname} путает ${Persival.emoj} ${Persival.cname}\\, показываясь ему вместе с ${Merlin.emoj} ${Merlin.cname}\\. Из\\-за этого ${Persival.emoj} ${Persival.cname} не может определиться кто из игроков кто\\.";

  static const emoj = "💃";
  static const cname = "Моргана";

  @override
  String get aboutRole => cAboutRole;
  @override
  String get emoji => emoj;
  @override
  String get name => cname;

  @override
  String toString() {
    return "$emoji $name";
  }
}

class Oberon extends Evil {
  Oberon(super.game);
  @override
  List<Player> vision() => [];

  @override
  int get sortValue => 70;

  static const String cAboutRole =
      "${Oberon.emoj} ${Oberon.cname} относится к Силам Зла ‼️\n${Oberon.emoj} ${Oberon.cname} единственный персонаж Сил Зла ‼️\\, который как сам не видит друих игроков своей команды\\, так и игроки Сил Зла‼️ не видят его\\.";

  static const emoj = "🧌";
  static const cname = "Оберон";

  @override
  String get aboutRole => cAboutRole;
  @override
  String get emoji => emoj;
  @override
  String get name => cname;

  @override
  String toString() {
    return "$emoji $name";
  }
}

class Morded extends Evil {
  Morded(super.game);

  static const String cAboutRole =
      "${Morded.emoj} ${Morded.cname} относится к Силам Зла ‼️\nОн видит роли других игроков Сил Зла‼️\\.\n${Morded.emoj} ${Morded.cname} настолько таинственный персонаж\\, что даже ${Merlin.emoj} ${Merlin.cname} не знает его\\.";

  @override
  int get sortValue => 50;

  static const emoj = "🦹";
  static const cname = "Мордед";

  @override
  String get aboutRole => cAboutRole;
  @override
  String get emoji => emoj;
  @override
  String get name => cname;

  @override
  String toString() {
    return "$emoji $name";
  }
}

class Knight extends Evil {
  Knight(super.game);

  static const String cAboutRole =
      '${Knight.emoj} ${Knight.cname} относится к Силам Зла ‼️\nОн видит роли других игроков Сил Зла‼️\\.\n${Knight.emoj} ${Knight.cname} желает победы Сил Зла‼️ настолько сильно\\, что оказавшись в походе может кинуть только \\"Провал"\\';

  @override
  int get sortValue => 65;

  @override
  List<bool> get questAnswers => [false, false];

  static const emoj = "🧛‍♂️";
  static const cname = "Черный рыцарь";

  @override
  String get aboutRole => cAboutRole;
  @override
  String get emoji => emoj;
  @override
  String get name => cname;

  @override
  String toString() {
    return "$emoji $name";
  }
}

class Kay extends Good {
  Kay(super.game);

  @override
  int get sortValue => 10;

  static const String cAboutRole =
      "${Kay.emoj} ${Kay.cname} относится к Силам Добра 🔆\nОн не знает ролей других игроков\n${Kay.emoj} ${Kay.cname} выглядит немного подозрительно\\, поэтому ${Merlin.emoj} ${Merlin.cname} ошибочно считает\\, что он на стороне Сил Зла‼️";

  static const emoj = "👳‍♂️";
  static const cname = "Сэр Кей";

  @override
  String get aboutRole => cAboutRole;
  @override
  String get emoji => emoj;
  @override
  String get name => cname;

  @override
  String toString() {
    return "$emoji $name";
  }
}

class Tristan extends Good {
  Tristan(super.game);

  static const String cAboutRole =
      "${Tristan.emoj} ${Tristan.cname} относится к Силам Добра 🔆\nНикого не знает кроме ${Isolde.emoj} ${Isolde.cname}";

  @override
  int get sortValue => 15;

  @override
  List<Player> vision() {
    List<Player> tristanView = [];
    for (var player in game.players) {
      if (player.role is Isolde) {
        tristanView.add(player);
      }
    }

    return tristanView;
  }

  static const emoj = "🤵‍♂️";
  static const cname = "Тристан";

  @override
  String get aboutRole => cAboutRole;
  @override
  String get emoji => emoj;
  @override
  String get name => cname;

  @override
  String toString() {
    return "$emoji $name";
  }
}

class Isolde extends Good {
  Isolde(super.game);

  @override
  int get sortValue => 16;

  static const String cAboutRole =
      "${Isolde.emoj} ${Isolde.cname} относится к Силам Добра 🔆\nНикого не знает кроме ${Tristan.emoj} ${Tristan.cname}";

  @override
  List<Player> vision() {
    List<Player> isoldeView = [];
    for (var player in game.players) {
      if (player.role is Tristan) {
        isoldeView.add(player);
      }
    }
    return isoldeView;
  }

  static const emoj = "👰‍♀️";
  static const cname = "Изольда";

  @override
  String get aboutRole => cAboutRole;
  @override
  String get emoji => emoj;
  @override
  String get name => cname;

  @override
  String toString() {
    return "$emoji $name";
  }
}

class Persival extends Good {
  Persival(super.game);

  static const String cAboutRole =
      "${Persival.emoj} ${Persival.cname} относится к Силам Добра 🔆\n${Persival.emoj} ${Persival.cname} знает ${Merlin.emoj} ${Merlin.cname}\\, но ${Morgan.emoj} ${Morgan.cname} накладывает чары на него\\, такие\\, что он не может понять кто из них кто\\.";

  @override
  int get sortValue => 5;

  @override
  List<Player> vision() {
    List<Player> percivalVision = [];

    for (var player in game.players) {
      if (player.role is Merlin || player.role is Morgan) {
        percivalVision.add(player);
      }
    }
    return percivalVision;
  }

  static const emoj = "🧝";
  static const cname = "Персиваль";

  @override
  String get aboutRole => cAboutRole;
  @override
  String get emoji => emoj;
  @override
  String get name => cname;

  @override
  String toString() {
    return "$emoji $name";
  }
}

class Merlin extends Good {
  Merlin(super.game);

  @override
  int get sortValue => 1;

  static const String cAboutRole =
      "${Merlin.emoj} ${Merlin.cname} относится к Силам Добра 🔆\n${Merlin.emoj} ${Merlin.cname} знает всех игроков Сил Зла‼️\\, однако не может раскрыть свою роль всем\\. Силы Зла‼️\\ победят если вычислят\\, кто из игроков ${Merlin.emoj} ${Merlin.cname}";

  @override
  List<Player> vision() {
    List<Player> merlinVision = [];

    for (var player in game.players) {
      Role role = player.role;
      if ((role is Evil && role is! Morded) || role is Kay) {
        merlinVision.add(player);
      }
    }

    return merlinVision;
  }

  static const emoj = "🧙‍♂️";
  static const cname = "Мерлин";

  @override
  String get aboutRole => cAboutRole;
  @override
  String get emoji => emoj;
  @override
  String get name => cname;

  @override
  String toString() {
    return "$emoji $name";
  }
}

class Arthur extends Good {
  Arthur(super.game);

  bool bRunQuest = false;

  static const String cAboutRole =
      "${Arthur.emoj} ${Arthur.cname} относится к Силам Добра 🔆\n ${Arthur.emoj} ${Arthur.cname} не знает никого\\, однако его знают все с самого начала игры\\. Единственное НО\\, королям не пололженно ходить в походы\\, поэтому ${Arthur.emoj} ${Arthur.cname} может сходить в поход только один раз за игру\\.";

  @override
  int get sortValue => 30;

  static const emoj = "👑";
  static const cname = "Король Артур";

  @override
  String get aboutRole => cAboutRole;
  @override
  String get emoji => emoj;
  @override
  String get name => cname;

  @override
  String toString() {
    return "$emoji $name";
  }
}
