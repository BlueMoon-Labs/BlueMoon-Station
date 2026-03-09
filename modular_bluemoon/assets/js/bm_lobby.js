// Lobby UI Library сука ебанный бобот мне теперь для тебя прийдется писать пояснения для каждого пука.
// Статический JS, загружается через asset cache.
// инициализируются отдельным инлайн-скриптом в _bm_build_html().

// СОСТОЯНИЕ
var _bm_sidebar_open  = true;
var _bm_settings_open = false;
var _bm_is_admin      = false;
var _bm_audio_playing = false;
var _bm_audio_muted   = false;
var _bm_audio_vol     = 35;


//  отправить action на сервер
var _bm_action_last = 0;
function bmAction(action) {
  var now = Date.now();
  if (now - _bm_action_last < 400) return;
  _bm_action_last = now;
  if (window._BM_SRC) location.href = '?src=' + window._BM_SRC + ';bm_lobby_action=' + action;
}

// === SIDEBAR ===
function bmToggleSidebar() {
  _bm_sidebar_open = !_bm_sidebar_open;
  var sb = document.getElementById('bm-sidebar');
  var tb = document.getElementById('bm-toggle-btn');
  if (_bm_sidebar_open) {
    sb.classList.remove('collapsed'); tb.classList.remove('collapsed');
    tb.innerHTML = '&#9654;'; tb.style.right = getComputedStyle(sb).width;
  } else {
    sb.classList.add('collapsed'); tb.classList.add('collapsed');
    tb.innerHTML = '&#9664;'; tb.style.right = '0';
  }
}

// === SETTINGS ===
function bmToggleSettings() {
  _bm_settings_open = !_bm_settings_open;
  document.getElementById('bm-settings-panel').classList.toggle('open', _bm_settings_open);
}
document.addEventListener('click', function(e) {
  if (!_bm_settings_open) return;
  var panel = document.getElementById('bm-settings-panel');
  var btn   = document.getElementById('bm-settings-btn');
  if (panel && btn && !panel.contains(e.target) && !btn.contains(e.target)) {
    _bm_settings_open = false; panel.classList.remove('open');
  }
});

// === ТОСТЫ ===
function bm_show_toast(text, type, duration) {
  var container = document.getElementById('bm-toasts');
  if (!container) return;
  var existing = container.querySelectorAll('.bm-toast:not(.dismiss)');
  for (var i = 0; i < existing.length; i++) {
    if (existing[i].textContent === text) return;
  }
  var toast = document.createElement('div');
  toast.className = 'bm-toast ' + (type || 'info');
  toast.textContent = text;
  toast.addEventListener('click', function() { _bm_dismiss(toast); });
  container.appendChild(toast);
  while (container.children.length > 4) _bm_dismiss(container.firstChild);
  setTimeout(function() { _bm_dismiss(toast); }, duration || 4000);
}
function _bm_dismiss(toast) {
  if (!toast || toast.classList.contains('dismiss')) return;
  toast.classList.add('dismiss');
  setTimeout(function() { if (toast.parentNode) toast.parentNode.removeChild(toast); }, 350);
}

// === ВЫЗЫВАЮТСЯ С СЕРВЕРА ===

function bm_update_character(name) {
  var el = document.getElementById('bm-char-name');
  if (el) el.textContent = name ? name.toUpperCase() : '\u2014 \u2014 \u2014';
}

var _bm_ready_state = 0;
function bm_toggle_ready(val) {
  var el = document.getElementById('bm-btn-ready');
  if (!el) return;
  if (val !== undefined) _bm_ready_state = Number(val);
  else _bm_ready_state = _bm_ready_state ? 0 : 1;
  el.innerHTML = _bm_ready_state
    ? "<span class='bm-checked'>\u2611</span> \u0413\u041e\u0422\u041e\u0412\u041d\u041e\u0421\u0422\u042c"
    : "<span class='bm-unchecked'>\u2612</span> \u0413\u041e\u0422\u041e\u0412\u041d\u041e\u0421\u0422\u042c";
}

var _bm_antag_state = 0;
function bm_toggle_antag(val) {
  var el = document.getElementById('bm-btn-antag');
  if (!el) return;
  if (val !== undefined) _bm_antag_state = Number(val);
  else _bm_antag_state = _bm_antag_state ? 0 : 1;
  el.innerHTML = _bm_antag_state
    ? "<span class='bm-checked'>\u2611</span> \u0420\u041e\u041b\u042c \u0410\u041d\u0422\u0410\u0413\u041e\u041d\u0418\u0421\u0422\u0410"
    : "<span class='bm-unchecked'>\u2612</span> \u0420\u041e\u041b\u042c \u0410\u041d\u0422\u0410\u0413\u041e\u041d\u0418\u0421\u0422\u0410";
}

function bm_update_nsfw_indicator(val) {
  var el = document.getElementById('bm-s-nsfw');
  if (el) el.textContent = Number(val) ? '\u0412\u041a\u041b' : '\u0412\u042b\u041a\u041b';
}

function bm_update_admin_bg_indicator(val) {
  var el = document.getElementById('bm-s-adminbg');
  if (el) el.textContent = Number(val) ? '\u0412\u041a\u041b' : '\u0412\u042b\u041a\u041b';
}

function bm_update_counts(online, ready) {
  if (ready === undefined && typeof online === 'string' && online.indexOf(',') >= 0) {
    var _parts = online.split(','); online = _parts[0]; ready = _parts[1];
  }
  var el_o = document.getElementById('bm-count-online');
  var el_r = document.getElementById('bm-count-ready');
  var el_h = document.getElementById('bm-player-count');
  var el_w = document.getElementById('bm-count-ready-wrap');
  if (el_o) el_o.textContent = (online !== undefined) ? online : '\u2014';
  if (el_h) el_h.textContent = ((online !== undefined) ? online : '\u2014') + ' \u0412 \u041b\u041e\u0411\u0411\u0418';
  if (_bm_is_admin && el_r && el_w) {
    el_w.style.display = 'inline'; el_r.textContent = (ready !== undefined) ? ready : '\u2014';
  }
}

function bm_set_admin(val) {
  _bm_is_admin = !!Number(val);
  var el = document.getElementById('bm-count-ready-wrap');
  if (el) el.style.display = _bm_is_admin ? 'inline' : 'none';
}

function bm_show_notice(text, type) {
  if (type === undefined && typeof text === 'string' && text.charAt(0) === "'") {
    var _m = text.match(/^'((?:[^'\\]|\\.)*)'(?:,\s*'?([^',]*)'?)?$/);
    if (_m) { text = _m[1]; type = _m[2] || ''; }
  }
  if (text) bm_show_toast(text, type || 'error', 8000);
}

function bm_set_background(data) {
  var bg = document.getElementById('bm-bg');
  if (!bg) return;
  var url, type;
  try {
    var parsed = JSON.parse(data);
    url  = parsed.url;
    type = parsed.type || 'image';
  } catch(e) {
    url  = data;
    type = 'image';
  }
  if (!url) return;
  // Если тип iframe и url — просто video_id (без слэшей), строим embed URL здесь
  if (type === 'iframe' && url.indexOf('/') === -1 && url.indexOf('.') === -1) {
    url = 'https://www.youtube.com/embed/' + url + '?autoplay=1&mute=1&loop=1&playlist=' + url + '&enablejsapi=1';
  }
  if (type === 'image') {
    if (bg.tagName !== 'IMG') {
      var img = document.createElement('img');
      img.id = 'bm-bg'; img.className = 'bg'; img.src = url;
      bg.parentNode.replaceChild(img, bg);
    } else { bg.src = url; }
    bm_show_volume_panel(null);
  } else if (type === 'video') {
    if (bg.tagName === 'VIDEO' && bg.getAttribute('data-bm-src') === url) return;
    var vid = document.createElement('video');
    vid.id = 'bm-bg'; vid.className = 'bg-video';
    vid.src = url; vid.autoplay = true; vid.loop = true; vid.muted = true;
    vid.setAttribute('playsinline', '');
    vid.setAttribute('data-bm-src', url);
    bg.parentNode.replaceChild(vid, bg);
    bm_show_volume_panel('video');
  } else if (type === 'iframe') {
    if (bg.tagName === 'IFRAME' && bg.getAttribute('data-bm-src') === url) return;
    var fr = document.createElement('iframe');
    fr.id = 'bm-bg';
    fr.className = 'bg-video';
    fr.src = url;
    fr.allow = 'autoplay; encrypted-media';
    fr.setAttribute('allowfullscreen', '');
    fr.setAttribute('data-bm-src', url);
    fr.style.pointerEvents = 'none';
    bg.parentNode.replaceChild(fr, bg);
    bm_show_volume_panel('iframe');
  }
}

// === РЕГУЛЯТОР ГРОМКОСТИ ВИДЕО ===
var _bm_video_type = null; var _bm_video_muted = true; var _bm_video_vol = 80;
function bm_show_volume_panel(mediaType) {
  _bm_video_type = mediaType || null;
  var row = document.getElementById('bm-video-row');
  if (!row) return;
  if (!mediaType || mediaType === 'image') {
    row.style.display = 'none';
    _bm_video_muted = true; _bm_video_vol = 80;
    return;
  }
  _bm_video_muted = true; _bm_video_vol = 80;
  var sl  = document.getElementById('bm-video-vol');
  var btn = document.getElementById('bm-btn-video-mute');
  if (sl)  sl.value = 0;
  if (btn) btn.innerHTML = '&#128263;';
  row.style.display = 'flex';
}
function _bmVideoApply() {
  var el  = document.getElementById('bm-bg');
  var sl  = document.getElementById('bm-video-vol');
  var btn = document.getElementById('bm-btn-video-mute');
  if (btn) btn.innerHTML = _bm_video_muted ? '&#128263;' : (_bm_video_vol > 50 ? '&#128266;' : '&#128265;');
  if (sl)  sl.value = _bm_video_muted ? 0 : _bm_video_vol;
  if (_bm_video_type === 'video' && el) {
    el.muted = _bm_video_muted; el.volume = _bm_video_muted ? 0 : _bm_video_vol / 100;
  } else if (_bm_video_type === 'iframe' && el && el.contentWindow) {
    if (_bm_video_muted) {
      el.contentWindow.postMessage('{"event":"command","func":"mute","args":""}', '*');
    } else {
      el.contentWindow.postMessage('{"event":"command","func":"unMute","args":""}', '*');
      el.contentWindow.postMessage('{"event":"command","func":"setVolume","args":[' + _bm_video_vol + ']}', '*');
    }
  }
}
function bmVideoVolume(val) {
  _bm_video_vol = parseInt(val);
  _bm_video_muted = (_bm_video_vol === 0);
  _bmVideoApply();
}
function bmVideoMute() {
  _bm_video_muted = !_bm_video_muted;
  _bmVideoApply();
}

// === АУДИО-ПЛЕЕР ===
function bm_load_audio(url) {
  var audio = document.getElementById('bm-audio');
  if (!audio || !url || url === 'null') return;
  audio.src = url;
  audio.volume = _bm_audio_muted ? 0 : _bm_audio_vol / 100;
  var sl = document.getElementById('bm-audio-vol');
  if (sl) sl.value = _bm_audio_muted ? 0 : _bm_audio_vol;
  var p = audio.play();
  if (p) p.then(function() {
    _bm_audio_playing = true;
    var btn = document.getElementById('bm-btn-play');
    if (btn) btn.innerHTML = '&#9646;&#9646;';
  }).catch(function() {
    document.addEventListener('click', function _ap() {
      var p2 = audio.play();
      if (p2) p2.then(function() {
        _bm_audio_playing = true;
        var btn = document.getElementById('bm-btn-play');
        if (btn) btn.innerHTML = '&#9646;&#9646;';
      });
    }, { once: true });
  });
}
function bm_set_audio_track(name) {
  var trel = document.getElementById('bm-audio-track');
  if (trel) trel.textContent = name || 'lobby music';
}
function bmAudioPlay() {
  var audio = document.getElementById('bm-audio');
  var btn   = document.getElementById('bm-btn-play');
  if (!audio || !audio.src || audio.src === window.location.href) return;
  if (_bm_audio_playing) {
    audio.pause(); _bm_audio_playing = false; if (btn) btn.innerHTML = '&#9654;';
  } else {
    var p = audio.play();
    if (p) p.then(function() {
      _bm_audio_playing = true; if (btn) btn.innerHTML = '&#9646;&#9646;';
    }).catch(function() {
      _bm_audio_playing = false; if (btn) btn.innerHTML = '&#9654;';
    });
    else { _bm_audio_playing = true; if (btn) btn.innerHTML = '&#9646;&#9646;'; }
  }
}
function bmAudioVolume(val) {
  _bm_audio_vol = parseInt(val);
  _bm_audio_muted = (_bm_audio_vol === 0);
  var audio = document.getElementById('bm-audio');
  var btn   = document.getElementById('bm-btn-mute');
  if (audio) audio.volume = _bm_audio_vol / 100;
  if (btn)   btn.innerHTML = _bm_audio_muted ? '&#128263;' : (_bm_audio_vol > 50 ? '&#128266;' : '&#128265;');
}
function bmAudioMute() {
  var audio = document.getElementById('bm-audio');
  var btn   = document.getElementById('bm-btn-mute');
  var sl    = document.getElementById('bm-audio-vol');
  _bm_audio_muted = !_bm_audio_muted;
  if (audio) audio.volume = _bm_audio_muted ? 0 : _bm_audio_vol / 100;
  if (sl)    sl.value = _bm_audio_muted ? 0 : _bm_audio_vol;
  if (btn)   btn.innerHTML = _bm_audio_muted ? '&#128263;' : (_bm_audio_vol > 50 ? '&#128266;' : '&#128265;');
}

/** Остановливаем при закрытии */
function _bmStopAllMedia() {
  var audio = document.getElementById('bm-audio');
  if (audio) { try { audio.pause(); audio.src = ''; } catch(e){} }
  var bg = document.getElementById('bm-bg');
  if (bg) {
    if (bg.tagName === 'VIDEO') { try { bg.pause(); bg.muted = true; bg.src = ''; } catch(e){} }
    else if (bg.tagName === 'IFRAME') { try { bg.contentWindow.postMessage('{"event":"command","func":"pauseVideo","args":""}', '*'); } catch(e){} }
  }
}
