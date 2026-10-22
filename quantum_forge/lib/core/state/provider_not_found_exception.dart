/// Exception thrown when a provider of type [valueType] cannot be resolved
/// within the ancestor tree of a given [widgetType].
class ProviderNotFoundException implements Exception {
  final Type valueType;
  final Type widgetType;

  ProviderNotFoundException(this.valueType, this.widgetType);

  @override
  String toString() {
    return '''
Error: Could not find the correct Provider<$valueType> above this $widgetType Widget

To fix, please make sure that:
  * The Provider<$valueType> is an ancestor to that $widgetType Widget
  * The provider is configured with the correct type: Provider<$valueType>
''';
  }
}
