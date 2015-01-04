import "package:polymorphic_bot/api.dart";
import "package:achievements/api.dart";
import "package:irc/client.dart" show Color;

BotConnector bot;
Plugin plugin;
Storage storage;
Map<String, Achievement> registered = {};
Map<String, List<String>> alerts = {};

void main(args, Plugin myPlugin) {
  plugin = myPlugin;
  bot = plugin.getBot();
  storage = plugin.getStorage("achievements");
  
  bot.getConfig().then((config) {
    if (config.containsKey("achievements")) {
      Map<String, dynamic> c = config["achievements"];
      if (c.containsKey("alerts")) {
        alerts = c["alerts"];
      }
    }
  });
  
  plugin.addRemoteMethod("give", (call) {
    var network = call.getArgument("network");
    var user = call.getArgument("user");
    var achievement = call.getArgument("achievement");
    
    List<String> achievements = storage.get("achievements by ${user} on ${network}", []);
    
    if (achievements.contains(achievement)) {
      return;
    }
    
    achievements.add(achievement);
    storage.set("achievements by ${user} on ${network}", achievements);
    
    if (alerts.containsKey(network)) {
      var tell = alerts[network];
      for (var target in tell) {
        bot.sendMessage(network, target, "[${Color.BLUE}Achievements${Color.NORMAL}] ${user} earned '${achievement}'");
      }
    }
  });
  
  plugin.addRemoteMethod("list", (call) {
    var network = call.getArgument("network");
    var user = call.getArgument("user");
    
    List<String> achievements = storage.get("achievements by ${user} on ${network}", []);
    call.reply(achievements.where((it) => registered.containsKey(it)).map((it) {
      return registered[it];
    }).map((it) {
      return {
        "id": it.id,
        "name": it.name,
        "description": it.description
      };
    }).toList());
  });
  
  plugin.addRemoteMethod("register", (call) {
    var id = call.getArgument("id");
    var name = call.getArgument("name");
    var description = call.getArgument("description");
    registered[id] = new Achievement(name, id, description);
  });
  
  plugin.addRemoteMethod("remove", (call) {
    var network = call.getArgument("network");
    var user = call.getArgument("user");
    var achievement = call.getArgument("achievement");
    
    List<String> achievements = storage.get("achievements by ${user} on ${network}", []);
    
    if (!achievements.contains(achievement)) {
      return;
    }
    
    achievements.remove(achievement);
    storage.set("achievements by ${user} on ${network}", achievements);
  });
}
