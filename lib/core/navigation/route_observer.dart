
import 'package:flutter/material.dart';
import '../utils/navigation_logger.dart';

class AppRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    NavigationLogger.log(
      NavigationEventType.push,
      'Pushed ${route.settings.name}',
      data: {'from': previousRoute?.settings.name, 'arguments': route.settings.arguments},
    );
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    NavigationLogger.log(
      NavigationEventType.pop,
      'Popped ${route.settings.name}',
      data: {'to': previousRoute?.settings.name},
    );
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    NavigationLogger.log(
      NavigationEventType.removeUntil,
      'Removed ${route.settings.name}',
      data: {'previousRoute': previousRoute?.settings.name},
    );
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    NavigationLogger.log(
      NavigationEventType.replace,
      'Replaced ${oldRoute?.settings.name} with ${newRoute?.settings.name}',
      data: {'oldArguments': oldRoute?.settings.arguments, 'newArguments': newRoute?.settings.arguments},
    );
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}
