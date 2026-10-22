import 'package:flutter/widgets.dart';

import 'inherited_notifier_scope.dart';
import 'inherited_provider_scope.dart';
import 'provider_not_found_exception.dart';

/// Abstract contract for resolving dependencies from a [BuildContext].
abstract class IProviderResolver {
  T resolve<T>(BuildContext context, {bool listen = true});
}

/// Core resolution engine for QuantumForge providers, implementing [IProviderResolver].
class QuantumProvider implements IProviderResolver {
  const QuantumProvider();

  static const IProviderResolver defaultResolver = QuantumProvider();

  @override
  T resolve<T>(BuildContext context, {bool listen = true}) {
    return of<T>(context, listen: listen);
  }

  /// Resolves the provided instance of type [T] from the [BuildContext].
  ///
  /// If [listen] is true, the calling context will be registered to rebuild
  /// whenever the resolved [T] (if it is a [Listenable]) notifies listeners.
  /// If [T] is nullable (e.g. `DashboardViewModel?`) and no matching provider
  /// exists in the ancestor tree, `null` is returned instead of throwing.
  static T of<T>(BuildContext context, {bool listen = true}) {
    // 1. Fast path: exact type match
    if (listen) {
      final notifierScope =
          context.dependOnInheritedWidgetOfExactType<InheritedNotifierScope<T>>();
      if (notifierScope != null) {
        return notifierScope.value;
      }
      final providerScope =
          context.dependOnInheritedWidgetOfExactType<InheritedProviderScope<T>>();
      if (providerScope != null) {
        return providerScope.value;
      }
    } else {
      final notifierScope =
          context.getInheritedWidgetOfExactType<InheritedNotifierScope<T>>();
      if (notifierScope != null) {
        return notifierScope.value;
      }
      final providerScope =
          context.getInheritedWidgetOfExactType<InheritedProviderScope<T>>();
      if (providerScope != null) {
        return providerScope.value;
      }
    }

    // 2. Polymorphic / Subtype / Nullable ancestor search
    bool found = false;
    T? resolvedValue;

    context.visitAncestorElements((element) {
      final widget = element.widget;
      if (widget is InheritedNotifierScope && widget.value is T) {
        if (listen && element is InheritedElement) {
          context.dependOnInheritedElement(element);
        }
        resolvedValue = widget.value as T;
        found = true;
        return false;
      }
      if (widget is InheritedProviderScope && widget.value is T) {
        if (listen && element is InheritedElement) {
          context.dependOnInheritedElement(element);
        }
        resolvedValue = widget.value as T;
        found = true;
        return false;
      }
      return true;
    });

    if (found) {
      return resolvedValue as T;
    }

    // 3. If T is nullable, return null if no provider was found
    if (null is T) {
      return null as T;
    }

    throw ProviderNotFoundException(T, context.widget.runtimeType);
  }
}
