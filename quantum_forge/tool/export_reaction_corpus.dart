import 'dart:convert';
import 'dart:io';

import 'package:quantum_forge/features/reaction_library/data/reaction_templates.dart';
import 'package:quantum_forge/features/reaction_library/data/reaction_template_generator.dart';

void main() {
  print('Building full reaction template library...');
  final allTemplates = buildFullTemplateLibrary(kReactionTemplates, maxGenerated: 5000);
  print('Total templates built: ${allTemplates.length}');

  final list = allTemplates.map((t) => {
    'id': t.id,
    'name': t.name,
    'reactantXyz': t.reactantXyz,
    'productXyz': t.productXyz,
    'referenceEa': t.referenceEa,
    'tags': t.tags,
    'category': t.category,
  }).toList();

  final outPath = '../tx1-fastapi-backend/data/dart_generated_templates.json';
  File(outPath).writeAsStringSync(jsonEncode(list));
  print('Exported ${list.length} templates to $outPath');
}
