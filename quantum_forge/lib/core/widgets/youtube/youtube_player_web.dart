import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

final Set<String> _registeredPlayers = {};

/// Web implementation of embedded YouTube player using responsive HTML iframe.
Widget buildPlatformEmbeddedPlayer({
  required String videoId,
  required String title,
  required VoidCallback onOpenExternal,
}) {
  final viewType = 'quantum-yt-embed-$videoId';

  if (!_registeredPlayers.contains(viewType)) {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final iframe = web.HTMLIFrameElement()
        ..id = 'quantum-yt-iframe-$viewId'
        ..src = 'https://www.youtube-nocookie.com/embed/$videoId?autoplay=1&rel=0&modestbranding=1'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.borderRadius = '12px'
        ..allowFullscreen = true
        ..title = title
        ..setAttribute(
          'allow',
          'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share',
        );
      return iframe;
    });
    _registeredPlayers.add(viewType);
  }

  return ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: HtmlElementView(
      key: ValueKey(viewType),
      viewType: viewType,
    ),
  );
}
