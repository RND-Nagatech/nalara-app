{{flutter_js}}
{{flutter_build_config}}

// Give the engine a real phone-width host. This also constrains MediaQuery,
// Navigator overlays and dialog positioning; it is not a scaled screenshot.
(() => {
  const host = document.getElementById('nalara-app');
  const loading = document.getElementById('nalara-loading');
  const message = document.getElementById('nalara-loading-message');
  const spinner = document.getElementById('nalara-loading-spinner');
  const reload = document.getElementById('nalara-reload');
  let firstFrame = false;
  reload.addEventListener('click', () => window.location.reload());

  const showFailure = () => {
    if (firstFrame) return;
    loading.setAttribute('aria-busy', 'false');
    message.textContent = 'NALARA belum dapat dibuka. Periksa koneksi lalu muat ulang.';
    spinner.hidden = true;
    reload.hidden = false;
  };

  window.addEventListener('error', showFailure);
  window.addEventListener('unhandledrejection', showFailure);
  window.addEventListener('flutter-first-frame', () => {
    firstFrame = true;
    loading.remove();
    window.removeEventListener('error', showFailure);
    window.removeEventListener('unhandledrejection', showFailure);
  }, {once: true});
  _flutter.loader.load({
    config: {hostElement: host},
    onEntrypointLoaded: async (engineInitializer) => {
      try {
        const runner = await engineInitializer.initializeEngine({hostElement: host});
        await runner.runApp();
      } catch (_) {
        showFailure();
      }
    },
  }).catch(showFailure);
})();
