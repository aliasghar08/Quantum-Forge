#!/bin/bash
set -e

# Resolve repository and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== Building Quantum Forge Hosting Distribution ==="
echo "Project Root: $PROJECT_ROOT"

cd "$PROJECT_ROOT"

# 1. Compile Flutter Web with base-href /app/
echo "--> Compiling Flutter Web release bundle with --base-href /app/ ..."
flutter build web --release --base-href "/app/" --no-tree-shake-icons

# 2. Prepare hosting_dist directory
HOSTING_DIST="$PROJECT_ROOT/hosting_dist"
echo "--> Assembling distribution in $HOSTING_DIST ..."
rm -rf "$HOSTING_DIST"
mkdir -p "$HOSTING_DIST/app"

# 3. Copy static site assets to root of hosting_dist
echo "--> Copying static site files (homepage, guides, trust pages, sitemap, ads.txt)..."
cp -R "$PROJECT_ROOT/static_site/"* "$HOSTING_DIST/"

# 4. Copy compiled Flutter web app into /app/
echo "--> Copying Flutter Web application into /app/ ..."
cp -R "$PROJECT_ROOT/build/web/"* "$HOSTING_DIST/app/"

echo "=== Quantum Forge Hosting Distribution Successfully Assembled ==="
echo "Root: $HOSTING_DIST (index.html, guides/, sitemap.xml, ads.txt)"
echo "App:  $HOSTING_DIST/app/ (Flutter 3D Workstation)"
