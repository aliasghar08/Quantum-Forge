#!/usr/bin/env python3
import json

with open("quantum_forge/assets/medical_reactions.json", "r", encoding="utf-8") as f:
    reactions = json.load(f)

lines = [
    "// ============================================================================",
    "// Medical & Pharmaceutical Reaction Templates for MBBS & Pharm-D Students",
    "// Curated with 3D Cartesian coordinates (RDKit MMFF94) & clinical citations.",
    "// ============================================================================",
    "",
    "import 'package:quantum_forge/features/reaction_library/data/reaction_templates.dart';",
    "",
    "final List<ReactionTemplate> kMedicalReactionTemplates = ["
]

for r in reactions:
    cat = "ReactionCategory." + r["category"]
    tags_formatted = json.dumps(r["tags"])
    name_escaped = r["name"].replace("'", "\\'")
    iupac_escaped = r["iupacName"].replace("'", "\\'")
    desc_escaped = r["description"].replace("'", "\\'").replace("$", "\\$")
    
    r_xyz = r["reactantXyz"].strip()
    p_xyz = r["productXyz"].strip()
    
    entry = f"""  ReactionTemplate(
    id: '{r["id"]}',
    name: '{name_escaped}',
    iupacName: '{iupac_escaped}',
    description: '{desc_escaped}',
    category: {cat},
    reactantXyz: '''{r_xyz}''',
    productXyz: '''{p_xyz}''',
    referenceEa: {r["referenceEa"]},
    doi: '{r["doi"]}',
    journalRef: '{r["journalRef"]}',
    tags: const {tags_formatted},
  ),"""
    lines.append(entry)

lines.append("];")
lines.append("")

with open("quantum_forge/lib/features/reaction_library/data/medical_reaction_templates.dart", "w", encoding="utf-8") as f:
    f.write("\n".join(lines))

print("Successfully generated quantum_forge/lib/features/reaction_library/data/medical_reaction_templates.dart")
