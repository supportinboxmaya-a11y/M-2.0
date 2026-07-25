/**
 * Maya 2.0 — SVG Icon Set
 * Used instead of emoji for consistent rendering across platforms.
 */
(function () {
  const I = {};
  window.MayaIcons = I;

  // All icons are 20x20 viewBox inline SVGs
  I.plus = '<svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><line x1="10" y1="3" x2="10" y2="17"/><line x1="3" y1="10" x2="17" y2="10"/></svg>';
  I.search = '<svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="8.5" cy="8.5" r="5.5"/><line x1="12.5" y1="12.5" x2="17" y2="17"/></svg>';
  I.check = '<svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><polyline points="4 10 8 14 16 6"/></svg>';
  I.close = '<svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><line x1="5" y1="5" x2="15" y2="15"/><line x1="15" y1="5" x2="5" y2="15"/></svg>';
  I.copy = '<svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><rect x="6" y="2" width="10" height="13" rx="1.5" ry="1.5"/><path d="M4 6H3.5A1.5 1.5 0 0 0 2 7.5v9A1.5 1.5 0 0 0 3.5 18h9a1.5 1.5 0 0 0 1.5-1.5V16"/></svg>';
  I.edit = '<svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M14 2l4 4-9 9H5v-4z"/></svg>';
  I.trash = '<svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><polyline points="3 6 17 6"/><path d="M8 6V4a1 1 0 0 1 1-1h2a1 1 0 0 1 1 1v2"/><path d="M5 6l1 10a2 2 0 0 0 2 2h4a2 2 0 0 0 2-2l1-10"/></svg>';
  I.retry = '<svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><polyline points="1 4 1 10 7 10"/><path d="M3.51 15a9 9 0 1 0 2.13-9.36L1 10"/></svg>';
  I.share = '<svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="6" cy="10" r="2.5"/><circle cx="14" cy="4" r="2.5"/><circle cx="14" cy="16" r="2.5"/><line x1="8" y1="11.5" x2="12" y2="14.5"/><line x1="8" y1="8.5" x2="12" y2="5.5"/></svg>';
  I.pin = '<svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M12 2l6 6-2 2H8l-6 6 2-2"/></svg>';
  I.regenerate = '<svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M17 9A8 8 0 1 0 4 15l-2 1v-4h4"/></svg>';
  I.continue_play = '<svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor"><polygon points="6 4 16 10 6 16"/></svg>';
  I.mic = '<svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><rect x="7" y="2" width="6" height="10" rx="3"/><line x1="10" y1="15" x2="10" y2="19"/><line x1="5" y1="13" x2="15" y2="13"/></svg>';
  I.camera = '<svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M16 6h-2l-2-2H8L6 6H4a2 2 0 0 0-2 2v7a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2z"/><circle cx="10" cy="11" r="3"/></svg>';
  I.attach = '<svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M10 3l-7 7a4 4 0 0 0 6 6l7-7a2.5 2.5 0 0 0-4-4l-7 7a1 1 0 0 0 2 2l7-7"/></svg>';
  I.send = '<svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><line x1="10" y1="3" x2="10" y2="17"/><polyline points="4 9 10 3 16 9"/></svg>';
  I.menu = '<svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><line x1="3" y1="5" x2="17" y2="5"/><line x1="3" y1="10" x2="17" y2="10"/><line x1="3" y1="15" x2="17" y2="15"/></svg>';
  I.export = '<svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M7 17h6"/><polyline points="10 3 10 13 14 9"/><polyline points="10 13 6 9"/></svg>';
  I.stop = '<svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor"><rect x="5" y="5" width="10" height="10" rx="2"/></svg>';
  I.image = '<svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><rect x="2" y="2" width="16" height="16" rx="2"/><circle cx="7" cy="7" r="2"/><path d="M2 14l4-4 3 3 3-3 4 4"/></svg>';
  I.more = '<svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor"><circle cx="10" cy="5" r="1.5"/><circle cx="10" cy="10" r="1.5"/><circle cx="10" cy="15" r="1.5"/></svg>';
  I.select = '<svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><rect x="3" y="3" width="5" height="5" rx="1"/><rect x="12" y="3" width="5" height="5" rx="1"/><rect x="3" y="12" width="5" height="5" rx="1"/><rect x="12" y="12" width="5" height="5" rx="1"/></svg>';
  I.folder = '<svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M2 4h6l2 2h7a1 1 0 0 1 1 1v8a1 1 0 0 1-1 1H3a1 1 0 0 1-1-1V5a1 1 0 0 1 1-1z"/></svg>';

  // Helper to get icon HTML
  I.render = function(name, size) {
    size = size || 20;
    var icon = I[name];
    if (!icon) return '❓';
    return icon.replace(/width="20"/g, 'width="' + size + '"').replace(/height="20"/g, 'height="' + size + '"');
  };
})();
