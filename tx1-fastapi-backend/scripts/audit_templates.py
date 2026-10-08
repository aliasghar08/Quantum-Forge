import json, re, sys
from collections import Counter

def parse_xyz(xyz_str):
    lines = [l.strip() for l in xyz_str.strip().splitlines() if l.strip()]
    if not lines: return []
    try:
        n = int(lines[0]); body = lines[2:2+n]
    except ValueError:
        body = lines
    return [l.split()[0].upper().capitalize() for l in body if len(l.split()) >= 4]

def audit(name, reactant, product):
    ra, pa = parse_xyz(reactant), parse_xyz(product)
    cr, cp = Counter(ra), Counter(pa)
    if cr != cp:
        print(f"  MISMATCH {name}: reactant={dict(cr)} product={dict(cp)}")
    elif ra != pa:
        print(f"  ORDER-DIFF {name}: same formula, different ordering (backend reorder handles)")
    else:
        print(f"  OK {name}")

if __name__ == "__main__":
    # Medical reactions
    print("=== medical_reactions.json ===")
    with open("quantum_forge/assets/medical_reactions.json") as f:
        for r in json.load(f):
            audit(r.get("id", "?"), r.get("reactantXyz", ""), r.get("productXyz", ""))

    # Dart templates
    print("=== reaction_templates.dart ===")
    text = open("quantum_forge/lib/features/reaction_library/data/reaction_templates.dart").read()
    xyz = dict(re.findall(r"const (_\w+) = '''(.*?)''';", text, re.DOTALL))
    for tid, rx, px in re.findall(
        r"id:\s*'([^']+)'.*?reactantXyz:\s*(_\w+).*?productXyz:\s*(_\w+)",
        text, re.DOTALL,
    ):
        audit(tid, xyz.get(rx, ""), xyz.get(px, ""))
