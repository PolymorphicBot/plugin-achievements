import "package:polymorphic_bot/api.dart";
import "package:achievements/api.dart";
import "package:irc/client.dart" show Color;
import "dart:async";

BotConnector bot;
Plugin plugin;
Storage storage;
Map<String, Achievement> registered = {};
Map<String, List<String>> alerts = {};

void main(args, Plugin myPlugin) {
  plugin = myPlugin;
  bot = plugin.getBot();
  storage = plugin.getStorage("achievements")..load();
  
  new Future.delayed(new Duration(seconds: 5), () {
    bot.getConfig().then((config) {
      if (config.containsKey("achievements")) {
        Map<String, dynamic> c = config["achievements"];
        if (c.containsKey("alerts")) {
          alerts = c["alerts"];
        }
      }
    });
  });
  
  plugin.addRemoteMethod("give", (call) {
    var network = call.getArgument("network");
    var user = call.getArgument("user");
    var achievement = call.getArgument("achievement");
    
    List<String> achievements = storage.get("achievements by ${user} on ${network}", []);
    
    if (achievements.contains(achievement)) {
      return;
    }
    
    if (!registered.containsKey(achievement)) {
      return;
    }
    
    achievements.add(achievement);
    storage.set("achievements by ${user} on ${network}", achievements);
    
    if (alerts.containsKey(network)) {
      var tell = alerts[network];
      for (var target in tell) {
        bot.sendMessage(network, target, "[${Color.BLUE}Achievements${Color.NORMAL}] ${user} earned '${registered[achievement].name}'");
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
        "description": it.description,
        "plugin": it.plugin
      };
    }).toList());
  });
  
  plugin.addRemoteMethod("register", (call) {
    var id = call.getArgument("id");
    var name = call.getArgument("name");
    var description = call.getArgument("description");
    var plugin = call.getArgument("plugin");
    registered[id] = new Achievement(name, id, description, plugin);
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
  
  bot.command("list-achievements", (event) {
    for (var id in registered.keys) {
      var a = registered[id];
      event.replyNotice("'${a.name}' provided by ${a.plugin}: ${a.description}");
    }
  });
  
  bot.command("achieved", (event) {
    if (event.args.length > 1) {
      event.reply("[${Color.BLUE}Achievements${Color.NORMAL}] Usage: achieved [user]");
      return;
    }
        
    List<String> achievements = storage.get("achievements by ${event.args.isEmpty ? event.user : event.args[0]} on ${event.network}", []);
    
    if (achievements.isEmpty) {
      event.reply("[${Color.BLUE}Achievements${Color.NORMAL}] No Achievements Earned");
    } else {
      event.reply("[${Color.BLUE}Achievements${Color.NORMAL}] ${achievements.where((it) => registered.containsKey(it)).map((it) => registered[it].name).join(", ")}");
    }
  });
}
