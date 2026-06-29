// The default template lets Flutter take over the whole <body>. Here we mount the
// engine into the #flutter-app element instead, so the app renders as one section
// of an otherwise static, SEO-friendly HTML landing page (see web/index.html).
{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  config: {
    hostElement: document.querySelector("#flutter-app"),
  },
});
