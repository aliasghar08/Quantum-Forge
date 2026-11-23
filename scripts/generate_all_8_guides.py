import os
import re

out_dir = "quantum_forge/web/guides"
os.makedirs(out_dir, exist_ok=True)

# Helper for shared HTML shell
def create_guide_html(slug, title, meta_title, meta_desc, category, read_time, body_content, amazon_link, amazon_title, amazon_desc, references_list):
    ref_items = "\n".join([f"          <li>{r}</li>" for r in references_list])
    
    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{meta_title} — Quantum Forge Guides</title>
  <meta name="description" content="{meta_desc}">
  <meta name="author" content="Ali Asghar">
  <meta name="copyright" content="Copyright © 2026 Ali Asghar. All Rights Reserved.">
  <link rel="icon" type="image/png" href="../favicon.png">
  <meta name="google-adsense-account" content="ca-pub-9402443776639153">
  <script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-9402443776639153" crossorigin="anonymous"></script>
  <!-- Google tag (gtag.js) -->
  <script async src="https://www.googletagmanager.com/gtag/js?id=AW-16732994716"></script>
  <script>
    window.dataLayer = window.dataLayer || [];
    function gtag(){{dataLayer.push(arguments);}}
    gtag('js', new Date());
    gtag('config', 'AW-16732994716');
  </script>
  <style>
    :root {{
      --bg: #090D16;
      --card-bg: #111827;
      --card-border: #1F2937;
      --primary: #00E5FF;
      --accent: #00BFA5;
      --text: #F3F4F6;
      --text-muted: #9CA3AF;
      --font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    }}
    * {{ box-sizing: border-box; margin: 0; padding: 0; }}
    body {{ background-color: var(--bg); color: var(--text); font-family: var(--font-family); line-height: 1.8; }}
    header {{ background: rgba(17, 24, 39, 0.85); backdrop-filter: blur(12px); border-bottom: 1px solid var(--card-border); position: sticky; top: 0; z-index: 50; padding: 1rem 2rem; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 1rem; }}
    .logo-container {{ display: flex; align-items: center; gap: 0.75rem; text-decoration: none; color: var(--text); }}
    .logo-badge {{ background: linear-gradient(135deg, #00BFA5, #00E5FF); color: #090D16; font-weight: 800; font-size: 1.1rem; padding: 0.25rem 0.6rem; border-radius: 6px; }}
    .logo-title {{ font-weight: 700; font-size: 1.25rem; letter-spacing: -0.025em; }}
    nav {{ display: flex; gap: 1.25rem; align-items: center; flex-wrap: wrap; }}
    nav a {{ color: var(--text-muted); text-decoration: none; font-size: 0.95rem; font-weight: 500; transition: color 0.2s; }}
    nav a:hover, nav a.active {{ color: var(--primary); }}
    .container {{ max-width: 900px; margin: 2rem auto; padding: 0 1.5rem; }}
    .breadcrumbs {{ font-size: 0.85rem; color: var(--text-muted); margin-bottom: 1.5rem; }}
    .breadcrumbs a {{ color: var(--text-muted); text-decoration: none; }}
    .breadcrumbs a:hover {{ color: var(--primary); }}
    article {{ background-color: var(--card-bg); border: 1px solid var(--card-border); border-radius: 12px; padding: 2.5rem; margin-bottom: 2rem; box-shadow: 0 4px 20px rgba(0, 0, 0, 0.4); }}
    h1 {{ font-size: 2.2rem; font-weight: 800; background: linear-gradient(135deg, #FFFFFF 0%, #00E5FF 100%); -webkit-background-clip: text; -webkit-text-fill-color: transparent; margin-bottom: 1rem; line-height: 1.3; }}
    .meta-bar {{ display: flex; gap: 1.5rem; font-size: 0.85rem; color: var(--text-muted); border-bottom: 1px solid var(--card-border); padding-bottom: 1rem; margin-bottom: 2rem; flex-wrap: wrap; }}
    h2 {{ color: #FFFFFF; font-size: 1.4rem; margin: 2rem 0 1rem; border-bottom: 1px solid var(--card-border); padding-bottom: 0.4rem; }}
    h3 {{ color: var(--primary); font-size: 1.15rem; margin: 1.5rem 0 0.5rem; }}
    p {{ margin-bottom: 1.2rem; color: #D1D5DB; }}
    ul, ol {{ margin: 0 0 1.5rem 1.75rem; color: #D1D5DB; }}
    li {{ margin-bottom: 0.5rem; }}
    strong {{ color: #FFFFFF; }}
    table {{ width: 100%; border-collapse: collapse; margin: 1.5rem 0; font-size: 0.9rem; }}
    th, td {{ border: 1px solid var(--card-border); padding: 0.75rem 1rem; text-align: left; }}
    th {{ background: rgba(15, 23, 42, 0.8); color: var(--primary); font-weight: 600; }}
    td {{ background: rgba(17, 24, 39, 0.4); }}
    .math-block {{ background: rgba(15, 23, 42, 0.8); border: 1px solid rgba(0, 229, 255, 0.2); border-radius: 8px; padding: 1rem 1.25rem; font-family: "Courier New", Courier, monospace; color: #67E8F9; margin: 1.5rem 0; overflow-x: auto; }}
    .callout {{ background: rgba(0, 191, 165, 0.08); border-left: 4px solid var(--accent); padding: 1.25rem; border-radius: 0 8px 8px 0; margin: 1.75rem 0; }}
    .callout h4 {{ color: var(--accent); margin-bottom: 0.5rem; font-size: 1rem; }}
    .callout p {{ margin: 0; color: #E5E7EB; }}
    .interactive-card {{ background: linear-gradient(135deg, rgba(0, 191, 165, 0.15) 0%, rgba(0, 229, 255, 0.15) 100%); border: 1px solid rgba(0, 229, 255, 0.3); border-radius: 8px; padding: 1.5rem; margin: 2rem 0; text-align: center; }}
    .interactive-card h4 {{ color: #FFFFFF; margin-bottom: 0.5rem; font-size: 1.1rem; }}
    .interactive-card p {{ color: #D1D5DB; margin-bottom: 1rem; font-size: 0.95rem; }}
    .interactive-card a {{ display: inline-block; background: linear-gradient(135deg, var(--accent), var(--primary)); color: #090D16; font-weight: 700; padding: 0.6rem 1.25rem; border-radius: 6px; text-decoration: none; transition: opacity 0.2s; }}
    .interactive-card a:hover {{ opacity: 0.9; }}
    .references {{ font-size: 0.85rem; color: var(--text-muted); border-top: 1px solid var(--card-border); padding-top: 1.5rem; margin-top: 2rem; }}
    .references ol {{ margin-left: 1.25rem; }}
    .references a {{ color: var(--primary); text-decoration: none; }}
    .references a:hover {{ text-decoration: underline; }}
    footer {{ background: #060911; border-top: 1px solid var(--card-border); padding: 2.5rem 1.5rem; text-align: center; font-size: 0.85rem; color: var(--text-muted); }}
    .footer-links {{ display: flex; justify-content: center; gap: 1.5rem; margin-bottom: 1rem; flex-wrap: wrap; }}
    .footer-links a {{ color: var(--text-muted); text-decoration: none; transition: color 0.2s; }}
    .footer-links a:hover {{ color: var(--primary); }}
  </style>
</head>
<body>

  <header>
    <a href="/" class="logo-container">
      <div class="logo-badge">QF</div>
      <div class="logo-title">Quantum Forge</div>
    </a>
    <nav>
      <a href="/">Interactive 3D Lab</a>
      <a href="/guides/" class="active">Scientific Guides</a>
      <a href="/about.html">About</a>
      <a href="/contact.html">Contact</a>
      <a href="/privacy.html">Privacy Policy</a>
      <a href="/terms.html">Terms</a>
    </nav>
  </header>

  <div class="container">
    <div class="breadcrumbs">
      <a href="/">Home</a> &rarr; <a href="/guides/">Guides</a> &rarr; <span>{title}</span>
    </div>

    <article>
      <h1>{title}</h1>
      <div class="meta-bar">
        <span><strong>Author:</strong> Ali Asghar</span>
        <span><strong>Category:</strong> {category}</span>
        <span><strong>Est. Read Time:</strong> {read_time}</span>
        <span><strong>Updated:</strong> November 2026</span>
      </div>

{body_content}

      <div class="references">
        <h2>References & Peer-Reviewed Literature</h2>
        <ol>
{ref_items}
        </ol>
      </div>
    </article>

    <aside aria-label="Recommended Study Resources" class="study-resources-card" style="background: rgba(17, 24, 39, 0.85); border: 1px solid #1F2937; border-radius: 12px; padding: 1.5rem 1.75rem; margin-top: 2rem; margin-bottom: 2rem; box-shadow: 0 4px 20px rgba(0, 0, 0, 0.35);">
      <div style="display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 0.5rem; margin-bottom: 0.85rem; border-bottom: 1px solid #1F2937; padding-bottom: 0.6rem;">
        <span style="font-weight: 700; color: #00E5FF; font-size: 0.95rem; letter-spacing: 0.03em; display: flex; align-items: center; gap: 0.5rem;">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="color: #00BFA5;"><path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path></svg>
          Recommended Curriculum Study Resource
        </span>
        <span style="font-size: 0.78rem; color: #9CA3AF; font-style: italic;">Verified Educational Reference</span>
      </div>
      <div>
        <h3 style="margin: 0 0 0.4rem; font-size: 1.15rem; color: #FFFFFF;">
          <a href="{amazon_link}" rel="nofollow sponsored noopener" target="_blank" style="color: #00E5FF; text-decoration: none;">{amazon_title}</a>
        </h3>
        <p style="margin: 0 0 0.8rem; font-size: 0.92rem; color: #D1D5DB; line-height: 1.55;">
          {amazon_desc}
        </p>
        <p style="margin: 0; font-size: 0.78rem; color: #9CA3AF; line-height: 1.4; border-top: 1px dashed #1F2937; padding-top: 0.6rem;">
          Disclosure: As an Amazon Associate, Quantum Forge earns from qualifying purchases at no extra cost to you.
        </p>
      </div>
    </aside>
  </div>

  <footer>
    <div class="footer-links">
      <a href="/">Launch 3D Lab</a>
      <a href="/guides/">All Scientific Guides</a>
      <a href="/about.html">About</a>
      <a href="/contact.html">Contact</a>
      <a href="/privacy.html">Privacy Policy</a>
      <a href="/terms.html">Terms of Service</a>
      <a href="/sitemap.xml">Sitemap (XML)</a>
    </div>
    <p>Copyright &copy; 2026 Ali Asghar. All Rights Reserved. Educational Simulation Only &mdash; Not for Medical Care.</p>
  </footer>

</body>
</html>
"""
    return html

print("Helper defined.")
