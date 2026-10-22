import 'package:flutter/widgets.dart';

/// Abstract contract for widgets that can be composed with an explicit child
/// in multi-level provider hierarchies.
abstract class SingleChildWidget implements Widget {
  Widget buildWithChild(BuildContext context, Widget? child);
}
