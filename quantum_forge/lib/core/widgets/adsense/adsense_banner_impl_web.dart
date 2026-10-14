import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

final Set<String> _registeredAdSenseViews = {};
final Map<String, void Function(bool isFilled)> _statusCallbacks = {};

@JS('window')
external JSObject get _window;

void _triggerAdSensePush() {
  try {
    var ads = _window.getProperty('adsbygoogle'.toJS);
    if (ads == null || !ads.isA<JSObject>()) {
      ads = JSArray();
      _window.setProperty('adsbygoogle'.toJS, ads);
    }
    final pushFn = (ads as JSObject).getProperty('push'.toJS);
    if (pushFn != null && pushFn.isA<JSFunction>()) {
      (pushFn as JSFunction).callAsFunction(ads, JSObject());
    }
  } catch (_) {
    // Ad blockers or offline lab environment — safely swallow
  }
}

/// Web implementation of embedded Google AdSense banner using HTML <ins> element.
Widget buildPlatformAdSenseBanner({
  required String adClient,
  String? adSlot,
  required String adFormat,
  required bool fullWidthResponsive,
  required String viewIdSuffix,
  void Function(bool isFilled)? onStatusChanged,
}) {
  final cleanSuffix = viewIdSuffix.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
  final viewType = 'quantum-adsense-$cleanSuffix';

  if (onStatusChanged != null) {
    _statusCallbacks[viewType] = onStatusChanged;
  }

  if (!_registeredAdSenseViews.contains(viewType)) {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int id) {
      final container = web.HTMLDivElement()
        ..id = 'quantum-adsense-container-$id'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.display = 'flex'
        ..style.justifyContent = 'center'
        ..style.alignItems = 'center'
        ..style.overflow = 'hidden'
        ..style.backgroundColor = 'transparent';

      final ins = web.document.createElement('ins') as web.HTMLElement
        ..className = 'adsbygoogle'
        ..style.display = 'block'
        ..style.width = '100%'
        ..style.height = '100%'
        ..setAttribute('data-ad-client', adClient);

      if (adSlot != null && adSlot.isNotEmpty) {
        ins.setAttribute('data-ad-slot', adSlot);
      }
      ins.setAttribute('data-ad-format', adFormat);
      ins.setAttribute(
        'data-full-width-responsive',
        fullWidthResponsive ? 'true' : 'false',
      );

      // Mutation observer to notify when ad is filled or unfilled
      try {
        final observer = web.MutationObserver(
          (JSArray mutations, web.MutationObserver obs) {
            final status = ins.getAttribute('data-ad-status');
            if (status == 'filled') {
              _statusCallbacks[viewType]?.call(true);
            } else if (status == 'unfilled') {
              _statusCallbacks[viewType]?.call(false);
              container.style.display = 'none';
            }
          }.toJS,
        );

        observer.observe(
          ins,
          web.MutationObserverInit(
            attributes: true,
            attributeFilter: ['data-ad-status'.toJS].toJS,
          ),
        );
      } catch (_) {
        // Fallback for older browsers
      }

      container.appendChild(ins);

      // Trigger adsbygoogle push on next animation frame
      web.window.requestAnimationFrame((double _) {
        _triggerAdSensePush();
      }.toJS);

      return container;
    });
    _registeredAdSenseViews.add(viewType);
  }

  return HtmlElementView(
    key: ValueKey(viewType),
    viewType: viewType,
  );
}
