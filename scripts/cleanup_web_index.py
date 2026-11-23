index_path = "quantum_forge/web/index.html"
with open(index_path, "r") as f:
    content = f.read()

# 1. Remove Google AdSense tags from head
adsense_tags = """  <!-- Google AdSense -->
  <meta name="google-adsense-account" content="ca-pub-9402443776639153">
  <script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-9402443776639153" crossorigin="anonymous"></script>"""

if adsense_tags in content:
    content = content.replace(adsense_tags, "  <!-- AdSense omitted on /app/ to prevent Auto Ads over 3D WebGL canvases -->")
    print("Removed AdSense from web/index.html")
else:
    print("Warning: adsense_tags not matched verbatim")

# 2. Reset flutter-view, flt-glass-pane style to standard 1280px lock
old_style = """    flutter-view, flt-glass-pane {
      position: absolute;
      top: 0;
      left: 0;
      z-index: 1;
      background-color: #060911;
      min-width: 1280px;
      width: 100% !important;
      height: 100% !important;
    }"""

new_style = """    flutter-view, flt-glass-pane {
      min-width: 1280px;
      width: 100% !important;
      height: 100% !important;
    }"""

if old_style in content:
    content = content.replace(old_style, new_style, 1)
    print("Reset flutter-view style")

# 3. Clean up dismissSplash
old_dismiss_comment = "        // Keep #seo-crawler-content visible in the DOM behind <flutter-view> (z-index: 0)"
if old_dismiss_comment in content:
    content = content.replace(old_dismiss_comment, "")
    print("Cleaned dismissSplash comment")

# 4. Replace noscript and remove seo-crawler-content
noscript_idx = content.find("<noscript>")
if noscript_idx != -1:
    before_noscript = content[:noscript_idx]
    clean_noscript_and_end = """<noscript>
    <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 600px; margin: 40px auto; padding: 24px; line-height: 1.7; color: #E2E8F0; background: #0F172A; border: 1px solid #1E293B; border-radius: 12px; text-align: center;">
      <h1 style="color: #00E5FF; font-size: 1.5rem; margin-bottom: 12px;">JavaScript &amp; WebGL Required</h1>
      <p style="color: #94A3B8; font-size: 0.95rem;">Quantum Forge 3D Workstation requires an active JavaScript and WebGL environment to render molecular simulations and hemodynamic viewports.</p>
      <p style="margin-top: 16px;"><a href="/" style="color: #00BFA5; text-decoration: none; font-weight: 600;">Return to Quantum Forge Home &rarr;</a></p>
    </div>
  </noscript>
</body>
</html>
"""
    content = before_noscript + clean_noscript_and_end
    print("Replaced noscript and stripped #seo-crawler-content")

with open(index_path, "w") as f:
    f.write(content)

print("Saved cleaned quantum_forge/web/index.html")
