import 'package:flutter/widgets.dart';

/// Factory signature for lazily instantiating a provided value using [BuildContext].
typedef Create<T> = T Function(BuildContext context);

/// Disposal callback signature executed when a created value is discarded.
typedef Dispose<T> = void Function(BuildContext context, T value);
