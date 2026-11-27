#!/usr/bin/env python3
"""
Quantum Forge Search Tokenizer & Facet Extractor
-------------------------------------------------
Generates inverted search tokens, edge n-grams (3-8 chars), American Soundex phonetic
keys, bidirectional clinical/chemical synonyms, and curriculum facets for Firestore /library.
"""

import re
from typing import Any, Dict, List, Set

# Bidirectional clinical and chemical synonym pairs/groups
SYNONYM_GROUPS: List[Set[str]] = [
    {"paracetamol", "acetaminophen", "apap", "tylenol", "panadol"},
    {"adrenaline", "epinephrine"},
    {"noradrenaline", "norepinephrine"},
    {"salbutamol", "albuterol", "ventolin"},
    {"frusemide", "furosemide", "lasix"},
    {"lidocaine", "lignocaine", "xylocaine"},
    {"quetiapine", "seroquel"},
    {"omeprazole", "prilosec", "losec"},
    {"metformin", "glucophage"},
    {"atorvastatin", "lipitor"},
    {"acetylsalicylic", "aspirin"},
    {"morphine", "ms contin"},
    {"cyp450", "cytochrome p450", "cytochrome"},
    {"cyp3a4", "cytochrome 3a4"},
    {"cyp2e1", "cytochrome 2e1"},
    {"cyp2d6", "cytochrome 2d6"},
    {"ace", "ace-i", "ace inhibitor", "acei", "angiotensin converting enzyme inhibitor"},
    {"arb", "angiotensin receptor blocker"},
    {"nsaid", "nonsteroidal anti-inflammatory"},
    {"sglt2", "sglt2 inhibitor", "gliflozin"},
    {"glp1", "glp-1", "incretin"},
    {"hmg", "coa", "hmg-coa", "hmgcoa", "statin"},
    {"ivermectin", "stromectol"},
    {"fenbendazole", "panacur"},
    {"xylazine", "rompun"},
]

# Fast lookup map for synonyms
_SYNONYM_MAP: Dict[str, Set[str]] = {}
for group in SYNONYM_GROUPS:
    for item in group:
        _SYNONYM_MAP[item] = group

# Soundex character mapping (American Soundex)
_SOUNDEX_MAP = {
    'B': '1', 'F': '1', 'P': '1', 'V': '1',
    'C': '2', 'G': '2', 'J': '2', 'K': '2', 'Q': '2', 'S': '2', 'X': '2', 'Z': '2',
    'D': '3', 'T': '3',
    'L': '4',
    'M': '5', 'N': '5',
    'R': '6'
}


def compute_soundex(word: str) -> str:
    """Computes standard 4-character American Soundex key prefixed with phx_ (e.g., phx_Q315)."""
    clean = re.sub(r'[^A-Za-z]', '', word).upper()
    if not clean:
        return ""
    first_char = clean[0]
    digits = []
    prev_code = _SOUNDEX_MAP.get(first_char, '')

    for char in clean[1:]:
        code = _SOUNDEX_MAP.get(char, '')
        if code:
            if code != prev_code:
                digits.append(code)
            prev_code = code
        else:
            prev_code = ''

    digits_str = "".join(digits)
    soundex_code = (first_char + digits_str + "000")[:4]
    return f"phx_{soundex_code}"


def generate_edge_ngrams(token: str, min_len: int = 3, max_len: int = 8) -> List[str]:
    """Generates prefix edge n-grams from min_len up to min(max_len, len(token))."""
    if len(token) < min_len:
        return []
    ngrams = []
    upper_bound = min(len(token), max_len)
    for length in range(min_len, upper_bound + 1):
        ngrams.append(token[:length])
    return ngrams


def extract_words(text: str) -> List[str]:
    """Splits text into lowercase alphanumeric words of length >= 2."""
    if not text:
        return []
    # Replace dashes/underscores with spaces to preserve compound subwords
    spaced = text.replace('-', ' ').replace('_', ' ').replace('/', ' ')
    words = re.findall(r'[a-zA-Z0-9]+', spaced)
    return [w.lower() for w in words if len(w) >= 2]


def build_search_metadata(record: Dict[str, Any]) -> Dict[str, Any]:
    """
    Extracts high-signal search tokens, phonetic keys, edge n-grams,
    and curriculum/specialty facets from a reaction record.
    """
    name = str(record.get("name", "") or "")
    name_lower = name.strip().lower()
    iupac = str(record.get("iupac_name", "") or record.get("iupacName", "") or record.get("iupac_equation", "") or "")
    description = str(record.get("description", "") or "")
    doi = str(record.get("doi", "") or "")
    journal_ref = str(record.get("journal_ref", "") or record.get("journalRef", "") or "")
    catalyst = str(record.get("default_catalyst_name", "") or record.get("defaultCatalystName", "") or "")
    category = str(record.get("category", "") or "")

    raw_tags = record.get("tags", [])
    if isinstance(raw_tags, list):
        tags = [str(t) for t in raw_tags]
    elif isinstance(raw_tags, str):
        tags = [t.strip() for t in raw_tags.split(",") if t.strip()]
    else:
        tags = []

    # 1. Base tokens from primary fields
    name_words = extract_words(name)
    primary_name_tokens = set(name_words)
    collected_tokens: Set[str] = set()

    for field_text in [iupac, catalyst, doi, journal_ref, category]:
        for w in extract_words(field_text):
            collected_tokens.add(w)

    for tag in tags:
        for w in extract_words(tag):
            collected_tokens.add(w)

    # Also capture full alphanumeric DOI fragments without slashes
    if doi:
        clean_doi = re.sub(r'[^a-zA-Z0-9]', '', doi.lower())
        if clean_doi:
            collected_tokens.add(clean_doi)

    # 2. Synonym expansion for words in name and category
    synonym_tokens: Set[str] = set()
    for tok in list(primary_name_tokens) + list(collected_tokens):
        if tok in _SYNONYM_MAP:
            for syn in _SYNONYM_MAP[tok]:
                for w in extract_words(syn):
                    synonym_tokens.add(w)

    # 3. Edge N-grams for primary title words (lengths 3 to 7)
    ngram_tokens: Set[str] = set()
    for w in name_words:
        if len(w) >= 3 and not w.isdigit():
            for ng in generate_edge_ngrams(w, min_len=3, max_len=7):
                ngram_tokens.add(ng)

    # 4. Phonetic Soundex keys for words in title and key synonyms
    phonetic_tokens: Set[str] = set()
    for w in list(primary_name_tokens) + list(synonym_tokens):
        if len(w) >= 4 and not w.isdigit():
            phx = compute_soundex(w)
            if phx:
                phonetic_tokens.add(phx)

    # 5. Prioritize and cap tokens at 40
    # Prioritization:
    # 1. Exact words from title (highest signal)
    # 2. Edge n-grams for title words (supports prefix matching anywhere in title)
    # 3. Direct synonyms (supports alternative drug names)
    # 4. Phonetic keys (supports typos like qutiapene -> phx_Q315)
    # 5. Remaining metadata tokens (tags, catalyst, doi)
    final_tokens: List[str] = []

    def _add_set(token_set: Set[str]):
        for t in sorted(token_set):
            if t not in final_tokens:
                final_tokens.append(t)
                if len(final_tokens) >= 40:
                    return

    _add_set(primary_name_tokens)
    _add_set(ngram_tokens)
    _add_set(synonym_tokens)
    _add_set(phonetic_tokens)
    _add_set(collected_tokens)

    final_tokens = final_tokens[:40]

    # 6. Facet Decomposition
    combined_corpus = f"{name} {iupac} {description} {category} {' '.join(tags)}".lower()

    is_mbbs = (
        "mbbs" in combined_corpus
        or "usmle" in combined_corpus
        or category.lower() in ("pharmaceutical", "biochemical", "enzymatic")
        or any(k in combined_corpus for k in ["cardiology", "neurology", "nephrology", "oncology", "pathology", "metabolism"])
    )

    is_pharm_d = (
        "pharm-d" in combined_corpus
        or "pharmd" in combined_corpus
        or "pharmacy" in combined_corpus
        or "pharmacology" in combined_corpus
        or category.lower() in ("pharmaceutical", "total_synthesis", "organocatalysis")
        or any(k in combined_corpus for k in ["synthesis", "prodrug", "inhibitor", "mechanism", "pharmacokinetics"])
    )

    is_dvm = (
        "dvm" in combined_corpus
        or "veterinary" in combined_corpus
        or "vet" in combined_corpus
        or any(k in combined_corpus for k in ["ivermectin", "fenbendazole", "xylazine", "canine", "feline", "equine", "bovine"])
    )

    is_polymer = (
        category.lower() == "polymer"
        or "polymer" in combined_corpus
        or any(k in combined_corpus for k in ["polymerization", "monomer", "copolymer", "polyethylene", "polystyrene"])
    )

    # Specialty determination
    specialty = "general"
    if "cardio" in combined_corpus or "heart" in combined_corpus or "vascular" in combined_corpus:
        specialty = "cardiology"
    elif "nephro" in combined_corpus or "renal" in combined_corpus or "kidney" in combined_corpus:
        specialty = "nephrology"
    elif "neuro" in combined_corpus or "brain" in combined_corpus or "synapse" in combined_corpus:
        specialty = "neurology"
    elif "onco" in combined_corpus or "cancer" in combined_corpus or "neoplasm" in combined_corpus:
        specialty = "oncology"
    elif "infect" in combined_corpus or "antibiotic" in combined_corpus or "antiviral" in combined_corpus:
        specialty = "infectious_disease"
    elif is_dvm:
        specialty = "veterinary"

    return {
        "search_tokens": final_tokens,
        "name_lower": name_lower,
        "is_mbbs": bool(is_mbbs),
        "is_pharm_d": bool(is_pharm_d),
        "is_dvm": bool(is_dvm),
        "is_polymer": bool(is_polymer),
        "specialty": specialty,
    }


if __name__ == "__main__":
    # Self-test
    sample = {
        "name": "CYP2E1 Paracetamol Bioactivation to NAPQI",
        "category": "pharmaceutical",
        "tags": ["MBBS", "Toxicology", "Pharm-D"],
        "defaultCatalystName": "CYP2E1 Hemoprotein",
        "doi": "10.1056/NEJM1995"
    }
    meta = build_search_metadata(sample)
    print("Tokens count:", len(meta["search_tokens"]))
    print("Tokens:", meta["search_tokens"])
    print("Facets:", {k: v for k, v in meta.items() if k != "search_tokens"})
    assert "paracetamol" in meta["search_tokens"]
    assert "acetaminophen" in meta["search_tokens"] # Synonym expansion
    assert "phx_P623" in meta["search_tokens"]      # Soundex
    assert "para" in meta["search_tokens"]          # Edge n-gram
    assert meta["is_mbbs"] is True
    assert meta["is_pharm_d"] is True
    print("Self-test PASSED!")
