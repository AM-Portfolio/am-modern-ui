(function () {
  var root = document.documentElement;
  var toggle = document.getElementById('theme-toggle');
  var label = document.getElementById('theme-label');
  var APP_THEME_KEY = 'flutter.app_theme_mode';
  var PREFS_BLOB_KEY = 'flutter.shared_preferences';

  function readAppThemeMode() {
    try {
      var blob = localStorage.getItem(PREFS_BLOB_KEY);
      if (blob) {
        var prefs = JSON.parse(blob);
        if (prefs && prefs[APP_THEME_KEY]) {
          return String(prefs[APP_THEME_KEY]);
        }
      }

      var direct = localStorage.getItem(APP_THEME_KEY);
      if (direct) {
        try {
          return String(JSON.parse(direct));
        } catch (e) {
          return String(direct);
        }
      }
    } catch (e) {
      /* ignore storage read errors */
    }
    return null;
  }

  function systemTheme() {
    return window.matchMedia('(prefers-color-scheme: dark)').matches
      ? 'dark'
      : 'light';
  }

  function resolveTheme() {
    var params = new URLSearchParams(window.location.search);
    var fromUrl = params.get('theme');
    if (fromUrl === 'light' || fromUrl === 'dark') {
      return fromUrl;
    }

    var appMode = readAppThemeMode();
    if (appMode === 'dark') {
      return 'dark';
    }
    if (appMode === 'light' || appMode === 'white') {
      return 'light';
    }

    return systemTheme();
  }

  function applyTheme(theme) {
    if (theme === 'light' || theme === 'dark') {
      root.setAttribute('data-theme', theme);
    } else {
      root.removeAttribute('data-theme');
      theme = systemTheme();
    }
    if (label) {
      label.textContent = theme === 'dark' ? 'Light mode' : 'Dark mode';
    }
  }

  function syncInternalLinks() {
    var theme = resolveTheme();
    document.querySelectorAll('a[href]').forEach(function (link) {
      var href = link.getAttribute('href');
      if (!href || href.indexOf('mailto:') === 0 || href.indexOf('http') === 0) {
        return;
      }
      if (href.indexOf('.html') === -1) {
        return;
      }
      try {
        var url = new URL(href, window.location.origin);
        if (url.origin !== window.location.origin) {
          return;
        }
        url.searchParams.set('theme', theme);
        link.setAttribute('href', url.pathname + url.search);
      } catch (e) {
        /* ignore malformed href */
      }
    });
  }

  applyTheme(resolveTheme());
  syncInternalLinks();

  if (toggle) {
    toggle.addEventListener('click', function () {
      var current =
        root.getAttribute('data-theme') ||
        (window.matchMedia('(prefers-color-scheme: dark)').matches
          ? 'dark'
          : 'light');
      var next = current === 'dark' ? 'light' : 'dark';
      applyTheme(next);
      try {
        var url = new URL(window.location.href);
        url.searchParams.set('theme', next);
        window.history.replaceState({}, '', url.pathname + url.search);
        syncInternalLinks();
      } catch (e) {
        /* ignore history errors */
      }
    });
  }

  window
    .matchMedia('(prefers-color-scheme: dark)')
    .addEventListener('change', function () {
      if (!new URLSearchParams(window.location.search).get('theme')) {
        var appMode = readAppThemeMode();
        if (!appMode || appMode === 'system') {
          applyTheme(systemTheme());
        }
      }
    });

  window.addEventListener('storage', function (event) {
    if (
      event.key === PREFS_BLOB_KEY ||
      event.key === APP_THEME_KEY
    ) {
      if (!new URLSearchParams(window.location.search).get('theme')) {
        applyTheme(resolveTheme());
      }
    }
  });
})();
