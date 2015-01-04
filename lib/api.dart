library achievements.api;

import "dart:async";
import "package:polymorphic_bot/api.dart";

class Achievement {
  final String name;
  final String id;
  final String description;
  
  Achievement(this.name, this.id, this.description);
}

class Achievements {
  final BotConnector bot;
  
  Achievements(this.bot);
  
  void give(String network, String user, String achievement) {
    bot.plugin.callRemoteMethod("achievements", "give", {
      "network": network,
      "user": user,
      "achievement": achievement
    });
  }
  
  void register(Achievement achievement) {
    bot.plugin.callRemoteMethod("achievements", "register", {
      "id": achievement.id,
      "name": achievement.name,
      "description": achievement.description
    });
  }
  
  Future<List<Achievement>> list(String network, String user) {
    return bot.plugin.callRemoteMethod("achievements", "list", {
      "network": network,
      "user": user
    }).then((List<Map<String, dynamic>> maps) {
      return maps.map((it) {
        return new Achievement(it["name"], it["id"], it["description"]);
      }).toList();
    });
  }
  
  void remove(String network, String user, String achievement) {
    bot.plugin.callRemoteMethod("achievements", "remove", {
      "network": network,
      "user": user,
      "achievement": achievement
    });
  }
}