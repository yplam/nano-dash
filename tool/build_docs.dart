// Renders the markdown in docs/ into a small, self-contained static doc site
// that matches the NanoDash landing page, then writes it into the web build
// output so Cloudflare Pages serves it alongside the Flutter app.
//
// Usage:
//   dart run tool/build_docs.dart [--src=docs] [--out=build/web/docs]
//
// Layout produced (clean URLs, one page per doc):
//   <out>/index.html              -> redirects to the default language + doc
//   <out>/<lang>/index.html       -> redirects to that language's default doc
//   <out>/<lang>/<slug>/index.html
//
// Config + sources live under docs/ (see docs/docs.yaml). Pages are fully
// self-contained (inlined CSS, system fonts, no external requests) so they load
// instantly, stay crawlable, and don't trip the site-wide
// Cross-Origin-Embedder-Policy: require-corp header in web/_headers.

import 'dart:io';

import 'package:markdown/markdown.dart' as md;
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

void main(List<String> args) {
  var srcDir = 'docs';
  var outDir = p.join('build', 'web', 'docs');
  for (final arg in args) {
    if (arg.startsWith('--src=')) srcDir = arg.substring('--src='.length);
    if (arg.startsWith('--out=')) outDir = arg.substring('--out='.length);
  }

  final configFile = File(p.join(srcDir, 'docs.yaml'));
  if (!configFile.existsSync()) {
    stderr.writeln('build_docs: config not found: ${configFile.path}');
    exit(1);
  }

  final config = loadYaml(configFile.readAsStringSync()) as YamlMap;
  final siteTitle = (config['site']?['title'] as String?) ?? 'Docs';
  final appUrl = (config['site']?['appUrl'] as String?) ?? '/';

  final languages = [
    for (final l in (config['languages'] as YamlList))
      (code: l['code'] as String, label: l['label'] as String),
  ];
  final nav = [
    for (final n in (config['nav'] as YamlList))
      (
        slug: n['slug'] as String,
        isDefault: n['default'] == true,
        titles: {
          for (final l in languages)
            if (n[l.code] != null) l.code: n[l.code] as String,
        },
      ),
  ];

  final defaultLang = languages.first.code;
  final defaultSlug =
      (nav.firstWhere((n) => n.isDefault, orElse: () => nav.first)).slug;

  // Which (lang, slug) pairs actually have a source file? Drives both the
  // sidebar (per language) and the language toggle (cross-language).
  bool hasDoc(String lang, String slug) =>
      File(p.join(srcDir, lang, '$slug.md')).existsSync();

  final out = Directory(outDir);
  if (out.existsSync()) out.deleteSync(recursive: true);
  out.createSync(recursive: true);

  var pageCount = 0;
  for (final lang in languages) {
    // Sidebar entries: nav docs that exist in this language, in nav order.
    final sidebar = [
      for (final n in nav)
        if (n.titles.containsKey(lang.code) && hasDoc(lang.code, n.slug))
          (slug: n.slug, title: n.titles[lang.code]!),
    ];
    if (sidebar.isEmpty) continue;

    for (final entry in sidebar) {
      final source =
          File(p.join(srcDir, lang.code, '${entry.slug}.md')).readAsStringSync();
      final body = md.markdownToHtml(
        source,
        extensionSet: md.ExtensionSet.gitHubWeb,
      );

      final html = _page(
        siteTitle: siteTitle,
        appUrl: appUrl,
        docTitle: entry.title,
        lang: lang.code,
        slug: entry.slug,
        languages: languages,
        sidebar: sidebar,
        // A language is reachable from this page only if it has this slug.
        langHref: (code) =>
            hasDoc(code, entry.slug) ? '../../$code/${entry.slug}/' : null,
        bodyHtml: body,
      );

      final file = File(p.join(outDir, lang.code, entry.slug, 'index.html'));
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(html);
      pageCount++;
    }

    // Per-language landing redirect: /docs/<lang>/ -> default (or first) doc.
    final langLanding =
        sidebar.any((e) => e.slug == defaultSlug) ? defaultSlug : sidebar.first.slug;
    File(p.join(outDir, lang.code, 'index.html'))
        .writeAsStringSync(_redirect('./$langLanding/'));
  }

  // Top-level redirect: /docs/ -> default language + doc.
  File(p.join(outDir, 'index.html'))
      .writeAsStringSync(_redirect('./$defaultLang/$defaultSlug/'));

  stdout.writeln('build_docs: wrote $pageCount page(s) to $outDir');
}

String _redirect(String to) => '''
<!DOCTYPE html>
<html><head><meta charset="UTF-8">
<meta http-equiv="refresh" content="0; url=$to">
<link rel="canonical" href="$to"><title>Redirecting…</title>
</head><body><a href="$to">Continue</a></body></html>
''';

String _page({
  required String siteTitle,
  required String appUrl,
  required String docTitle,
  required String lang,
  required String slug,
  required List<({String code, String label})> languages,
  required List<({String slug, String title})> sidebar,
  required String? Function(String code) langHref,
  required String bodyHtml,
}) {
  final navLinks = StringBuffer();
  for (final item in sidebar) {
    final active = item.slug == slug;
    // Sibling doc in the same language: /docs/<lang>/<slug>/ -> ../<slug>/.
    navLinks.writeln(
      '<a class="nav-link${active ? ' is-active' : ''}" '
      'href="../${item.slug}/"${active ? ' aria-current="page"' : ''}>'
      '${_esc(item.title)}</a>',
    );
  }

  final langToggle = StringBuffer();
  for (final l in languages) {
    final active = l.code == lang;
    final href = langHref(l.code);
    if (active) {
      langToggle.writeln(
        '<span class="lang is-active" aria-current="true">${_esc(l.label)}</span>',
      );
    } else if (href != null) {
      langToggle.writeln(
        '<a class="lang" href="$href" hreflang="${l.code}">${_esc(l.label)}</a>',
      );
    } else {
      // No translation for this doc: show the language, disabled.
      langToggle.writeln(
        '<span class="lang is-off" title="Not available in this language">'
        '${_esc(l.label)}</span>',
      );
    }
  }

  return '''
<!DOCTYPE html>
<html lang="$lang">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${_esc(docTitle)} — ${_esc(siteTitle)}</title>
  <link rel="icon" type="image/png" href="/favicon.png"/>
  <style>$_css</style>
</head>
<body>
  <header class="topbar">
    <a class="brand" href="$appUrl">
      <img src="/icons/Icon-192.png" alt="" width="28" height="28">
      <span>${_esc(siteTitle)}</span>
    </a>
    <nav class="langs" aria-label="Language">$langToggle</nav>
  </header>
  <div class="shell">
    <aside class="sidebar">
      <nav aria-label="Docs">$navLinks</nav>
    </aside>
    <main class="doc-content">$bodyHtml</main>
  </div>
</body>
</html>
''';
}

String _esc(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

// Matches web/index.html's palette and system-font stack. Kept inline so pages
// stay self-contained.
const _css = '''
:root {
  --bg: #101014; --card: #1c1c24; --line: #2a2a35;
  --fg: #f4f4f7; --fg-dim: #a8a8b6; --accent: #7c84ff; --accent-2: #4c50d6;
}
* { box-sizing: border-box; }
html { scroll-behavior: smooth; }
body {
  margin: 0; background: var(--bg); color: var(--fg);
  font-family: system-ui, -apple-system, "Segoe UI", Roboto, "PingFang SC",
    "Microsoft YaHei", "Noto Sans CJK SC", sans-serif;
  line-height: 1.7; -webkit-font-smoothing: antialiased;
}
a { color: var(--accent); text-decoration: none; }
a:hover { text-decoration: underline; }

.topbar {
  position: sticky; top: 0; z-index: 10;
  display: flex; align-items: center; justify-content: space-between;
  gap: 16px; padding: 12px 24px;
  background: rgba(16,16,20,0.82); backdrop-filter: blur(10px);
  border-bottom: 1px solid var(--line);
}
.brand { display: flex; align-items: center; gap: 10px; color: var(--fg); font-weight: 600; }
.brand:hover { text-decoration: none; }
.brand img { border-radius: 7px; }
.langs { display: flex; gap: 6px; }
.lang {
  padding: 5px 11px; border-radius: 999px; font-size: 14px;
  border: 1px solid var(--line); color: var(--fg-dim);
}
.lang.is-active { background: var(--accent-2); border-color: var(--accent-2); color: #fff; }
.lang.is-off { opacity: 0.4; cursor: not-allowed; }

.shell {
  display: grid; grid-template-columns: 232px minmax(0, 1fr);
  gap: 48px; max-width: 1040px; margin: 0 auto; padding: 32px 24px 96px;
}
.sidebar { position: sticky; top: 72px; align-self: start; }
.nav-link {
  display: block; padding: 8px 12px; border-radius: 9px;
  color: var(--fg-dim); font-size: 15px;
}
.nav-link:hover { background: var(--card); color: var(--fg); text-decoration: none; }
.nav-link.is-active { background: var(--card); color: var(--fg); font-weight: 600; }

.doc-content { min-width: 0; }
.doc-content h1 { font-size: clamp(28px, 4vw, 36px); letter-spacing: -0.02em; margin: 0 0 24px; }
.doc-content h2 { font-size: 22px; margin: 40px 0 12px; padding-top: 8px; border-top: 1px solid var(--line); }
.doc-content h3 { font-size: 18px; margin: 28px 0 8px; }
.doc-content p, .doc-content li { color: #d8d8e0; }
.doc-content ul, .doc-content ol { padding-left: 22px; }
.doc-content li { margin: 6px 0; }
.doc-content strong { color: var(--fg); }
.doc-content code {
  background: var(--card); border: 1px solid var(--line);
  border-radius: 5px; padding: 1px 6px; font-size: 0.9em;
  font-family: ui-monospace, "SF Mono", "Cascadia Code", Menlo, monospace;
}
.doc-content pre {
  background: var(--card); border: 1px solid var(--line);
  border-radius: 10px; padding: 16px; overflow-x: auto;
}
.doc-content pre code { background: none; border: none; padding: 0; }
.doc-content blockquote {
  margin: 16px 0; padding: 4px 18px; color: var(--fg-dim);
  border-left: 3px solid var(--accent-2); background: rgba(124,132,255,0.06);
  border-radius: 0 8px 8px 0;
}
.doc-content a { text-decoration: underline; text-underline-offset: 2px; }
.table-wrap, .doc-content > table { overflow-x: auto; }
.doc-content table { border-collapse: collapse; width: 100%; margin: 18px 0; display: block; overflow-x: auto; }
.doc-content th, .doc-content td { border: 1px solid var(--line); padding: 9px 12px; text-align: left; vertical-align: top; }
.doc-content th { background: var(--card); font-weight: 600; }

@media (max-width: 720px) {
  .shell { grid-template-columns: 1fr; gap: 20px; padding-top: 20px; }
  .sidebar {
    position: static; display: flex; gap: 6px; overflow-x: auto;
    padding-bottom: 8px; border-bottom: 1px solid var(--line);
  }
  .sidebar nav { display: flex; gap: 6px; }
  .nav-link { white-space: nowrap; }
}
''';
