import json

fb_path = "quantum_forge/firebase.json"
with open(fb_path, "r") as f:
    data = json.load(f)

hosting = data.get("hosting", {})
hosting["public"] = "hosting_dist"

hosting["headers"] = [
    {
        "source": "/",
        "headers": [
            {
                "key": "Cache-Control",
                "value": "public, max-age=3600, must-revalidate"
            }
        ]
    },
    {
        "source": "/app/@(index.html|flutter_service_worker.js|main.dart.js|flutter.js|flutter_bootstrap.js|version.json)",
        "headers": [
            {
                "key": "Cache-Control",
                "value": "no-cache, no-store, must-revalidate"
            }
        ]
    },
    {
        "source": "/@(robots.txt|sitemap.xml|ads.txt|about.html|contact.html|privacy.html|terms.html|licenses.html|google5e323cc7b5450853.html)",
        "headers": [
            {
                "key": "Cache-Control",
                "value": "public, max-age=3600, must-revalidate"
            }
        ]
    },
    {
        "source": "/guides/**",
        "headers": [
            {
                "key": "Cache-Control",
                "value": "public, max-age=3600, must-revalidate"
            }
        ]
    },
    {
        "source": "/app/assets/**",
        "headers": [
            {
                "key": "Cache-Control",
                "value": "max-age=31536000, immutable"
            }
        ]
    }
]

hosting["redirects"] = [
    {
        "source": "/reaction/:slug*",
        "destination": "/app/reaction/:slug*",
        "type": 301
    },
    {
        "source": "/library",
        "destination": "/app/library",
        "type": 301
    },
    {
        "source": "/history",
        "destination": "/app/history",
        "type": 301
    },
    {
        "source": "/editor",
        "destination": "/app/editor",
        "type": 301
    },
    {
        "source": "/analytics",
        "destination": "/app/analytics",
        "type": 301
    },
    {
        "source": "/cardio-cath",
        "destination": "/app/cardio-cath",
        "type": 301
    },
    {
        "source": "/cardiac",
        "destination": "/app/cardio-cath",
        "type": 301
    },
    {
        "source": "/neuro-lab",
        "destination": "/app/neuro-lab",
        "type": 301
    },
    {
        "source": "/neuro",
        "destination": "/app/neuro-lab",
        "type": 301
    },
    {
        "source": "/nephro-lab",
        "destination": "/app/nephro-lab",
        "type": 301
    },
    {
        "source": "/nephro",
        "destination": "/app/nephro-lab",
        "type": 301
    },
    {
        "source": "/pulmo-vent",
        "destination": "/app/pulmo-vent",
        "type": 301
    },
    {
        "source": "/pulmo",
        "destination": "/app/pulmo-vent",
        "type": 301
    },
    {
        "source": "/dental",
        "destination": "/app/dental",
        "type": 301
    },
    {
        "source": "/pharmacogenomics",
        "destination": "/app/pharmacogenomics",
        "type": 301
    },
    {
        "source": "/osce",
        "destination": "/app/osce",
        "type": 301
    },
    {
        "source": "/ddi",
        "destination": "/app/ddi",
        "type": 301
    }
]

# Keep API cloud run rewrites + Flutter /app rewrites only
api_rewrites = [
    r for r in hosting.get("rewrites", [])
    if r.get("source", "").startswith("/api/")
]

hosting["rewrites"] = api_rewrites + [
    {
        "source": "/app",
        "destination": "/app/index.html"
    },
    {
        "source": "/app/**",
        "destination": "/app/index.html"
    }
]

data["hosting"] = hosting

with open(fb_path, "w") as f:
    json.dump(data, f, indent=2)

print("Updated quantum_forge/firebase.json successfully!")
