// Lobby UI Library сука ебанный бобот мне теперь для тебя прийдется писать пояснения для каждого пука.
// Статический JS, загружается через asset cache.

// СОСТОЯНИЕ
var _bm_sidebar_open  = true;
var _bm_settings_open = false;
var _bm_audio_playing = false;
var _bm_audio_muted   = false;
var _bm_audio_vol     = 35;
var _bm_countdown_s   = -1; // секунд до старта; -1 = неактивен
var _bm_countdown_iv  = null; // setInterval handle

function _bm_countdown_tick() {
  if (_bm_countdown_s > 0) _bm_countdown_s--;
  _bm_countdown_render();
  if (_bm_countdown_s <= 0) {
    clearInterval(_bm_countdown_iv); _bm_countdown_iv = null;
  }
}

function _bm_countdown_render() {
  var el_cd = document.getElementById('bm-countdown-row');
  var el_cv = document.getElementById('bm-countdown-val');
  if (el_cd) el_cd.style.display = (_bm_countdown_s > 0) ? 'flex' : 'none';
  if (el_cv && _bm_countdown_s > 0) {
    var m = Math.floor(_bm_countdown_s / 60), s = _bm_countdown_s % 60;
    el_cv.textContent = m + ':' + (s < 10 ? '0' : '') + s;
  }
} // Ебать, если хоть кто-то из будущих поколений поймет как эта хуйня работает, это будет такой восторг.


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

var _bm_is_registered = false;
function bm_set_registered(val) {
  _bm_is_registered = !!Number(val);
}

function bm_rebuild_menu(state) {
  var el = document.getElementById('bm-menu');
  var src = window._BM_SRC || '';
  if (!el || !src) return;
  var ingame = Number(state) > 0;
  var h = [];
  if (!ingame) {
    h.push('<a id="bm-btn-ready" class="bm-btn" href="?src=' + src + ';bm_lobby_action=toggle_ready">'
      + (_bm_ready_state ? '<span class="bm-checked">&#9745;</span>' : '<span class="bm-unchecked">&#9746;</span>')
      + ' \u0413\u041e\u0422\u041e\u0412\u041d\u041e\u0421\u0422\u042c</a>');
  } else {
    h.push('<a class="bm-btn" href="?src=' + src + ';bm_lobby_action=late_join">\u0412\u041e\u0419\u0422\u0418 \u0412 \u0418\u0413\u0420\u0423</a>');
    h.push('<a class="bm-btn" href="?src=' + src + ';bm_lobby_action=view_manifest">\u0421\u041f\u0418\u0421\u041e\u041a \u042d\u041a\u0418\u041f\u0410\u0416\u0410</a>');
    h.push('<a class="bm-btn" href="?src=' + src + ';bm_lobby_action=character_directory">\u0411\u0418\u0411\u041b\u0418\u041e\u0422\u0415\u041a\u0410 \u041f\u0415\u0420\u0421\u041e\u041d\u0410\u0416\u0415\u0419</a>');
  }
   h.push('<a class="bm-btn" href="?src=' + src + ';bm_lobby_action=observe">\u0411\u042b\u0422\u042c \u041d\u0410\u0411\u041b\u042e\u0414\u0410\u0422\u0415\u041b\u0415\u041c</a>');
  // BM_METASHOP_RAINBOW_P (0–100): 100 = всегда радуга — см. modular_bluemoon/code/modules/lobby/__lobby_defines.dm
  var BM_METASHOP_RAINBOW_P = 100;
  var _msRain = BM_METASHOP_RAINBOW_P >= 100 || Math.random() * 100 < BM_METASHOP_RAINBOW_P;
  h.push('<div class="bm-metashop-slot">');
  h.push('<div class="bm-metashop-nullspace" aria-hidden="true"></div>');
  h.push('<a class="bm-btn bm-metashop' + (_msRain ? ' bm-ms-rainbow' : '') + '" href="?src=' + src + ';bm_lobby_action=metashop">\u041c\u0410\u0413\u0410\u0417\u0418\u041d</a>');
  h.push('<div class="bm-metashop-nullspace" aria-hidden="true"></div>');
  h.push('</div>');
  h.push('<div class="bm-divider"></div>');
  h.push('<a class="bm-btn" href="?src=' + src + ';bm_lobby_action=character_setup">\u041d\u0410\u0421\u0422\u0420\u041e\u0419\u041a\u0410 \u041f\u0415\u0420\u0421\u041e\u041d\u0410\u0416\u0410</a>');
  h.push('<a class="bm-btn" href="?src=' + src + ';bm_lobby_action=game_options">\u041f\u0410\u0420\u0410\u041c\u0415\u0422\u0420\u042b \u0418\u0413\u0420\u042b</a>');
  h.push('<a id="bm-btn-antag" class="bm-btn" href="?src=' + src + ';bm_lobby_action=toggle_antag">'
    + (_bm_antag_state ? '<span class="bm-checked">&#9745;</span>' : '<span class="bm-unchecked">&#9746;</span>')
    + ' \u0420\u041e\u041b\u042c \u0410\u041d\u0422\u0410\u0413\u041e\u041d\u0418\u0421\u0422\u0410</a>');
  if (_bm_is_registered) {
    h.push('<a class="bm-btn" href="?src=' + src + ';bm_lobby_action=changelog">\u041f\u041e\u0421\u041b\u0415\u0414\u041d\u0418\u0415 \u041e\u0411\u041d\u041e\u0412\u041b\u0415\u041d\u0418\u042f</a>');
    h.push('<a class="bm-btn" href="?src=' + src + ';bm_lobby_action=polls_menu">\u041e\u041f\u0420\u041e\u0421\u042b \u0421\u0415\u0420\u0412\u0415\u0420\u0410</a>');
  }
  if (!ingame && _bm_is_admin) {
    h.push('<div class="bm-start-game-wrap"><a class="bm-btn bm-btn-admin" href="?src=' + src + ';bm_lobby_action=start_game">&#9889; \u0421\u0422\u0410\u0420\u0422 \u0418\u0413\u0420\u042b</a></div>');
  }
  el.innerHTML = h.join('');
}

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

function bm_update_counts(p1, p2, p3, p4, p5) {
  // Формат: "total_online,lobby,ready,timer_s,is_pregame"
  var total_online, lobby, ready, timer_s, is_pregame;
  if (p2 === undefined && typeof p1 === 'string' && p1.indexOf(',') >= 0) {
    var _parts = p1.split(',');
    total_online = _parts[0]; lobby = _parts[1]; ready = _parts[2];
    timer_s = _parts[3]; is_pregame = parseInt(_parts[4]) || 0;
  } else {
    total_online = p1; lobby = p2; ready = p3; timer_s = p4; is_pregame = parseInt(p5) || 0;
  }
  // Верхний счётчик — всего онлайн
  var el_h = document.getElementById('bm-player-count');
  if (el_h) el_h.textContent = (total_online !== undefined ? total_online : '\u2014') + ' \u041e\u041d\u041b\u0410\u0419\u041d';
  // Нижний левый — игроки в лобби
  var el_o = document.getElementById('bm-count-online');
  if (el_o) el_o.textContent = (lobby !== undefined) ? lobby : '\u2014';
  // Нижний правый — готовы (виден только в прегейме)
  var el_r = document.getElementById('bm-count-ready');
  var el_w = document.getElementById('bm-count-ready-wrap');
  if (el_r) el_r.textContent = (ready !== undefined) ? ready : '\u2014';
  if (el_w) el_w.style.display = is_pregame ? 'inline' : 'none';
  // Таймер — синхронизируем значение с сервера, считаем клиентски
  var t = parseInt(timer_s);
  if (is_pregame && t > 0) {
    _bm_countdown_s = t;
    if (!_bm_countdown_iv)
      _bm_countdown_iv = setInterval(_bm_countdown_tick, 1000);
  } else {
    _bm_countdown_s = -1;
    if (_bm_countdown_iv) { clearInterval(_bm_countdown_iv); _bm_countdown_iv = null; }
  }
  _bm_countdown_render();
}

var _bm_is_admin = false;
function bm_set_admin(val) {
  _bm_is_admin = !!Number(val);
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
    var _prev_bg = bg.cloneNode(false);
    var _prev_media_type = bg.tagName === 'VIDEO' ? 'video' : (bg.tagName === 'IFRAME' ? 'iframe' : null);
    var fr = document.createElement('iframe');
    fr.id = 'bm-bg';
    fr.className = 'bg-video';
    fr.src = url;
    fr.allow = 'autoplay; encrypted-media';
    fr.setAttribute('allowfullscreen', '');
    fr.setAttribute('data-bm-src', url);
    fr.style.pointerEvents = 'none';
    // YouTube IFrame API: коды ошибок 101 и 150
    var _yt_msg_handler = function(e) {
      try {
        var d = typeof e.data === 'string' ? JSON.parse(e.data) : e.data;
        if (d.event === 'infoDelivery' && d.info && d.info.error) {
          if (d.info.error === 101 || d.info.error === 150) {
            window.removeEventListener('message', _yt_msg_handler);
            _bm_video_confirm_dismiss();
            var cur = document.getElementById('bm-bg');
            if (cur && cur.tagName === 'IFRAME') {
              var img = document.createElement('img');
              img.id = 'bm-bg'; img.className = 'bg'; img.src = 'loading_screen.gif';
              cur.parentNode.replaceChild(img, cur);
            }
            bm_show_volume_panel(null);
            bm_show_toast('Видео недоступно для встраивания', 'warning', 6000);
          }
        }
      } catch(ex) {}
    };
    window.addEventListener('message', _yt_msg_handler);
    bg.parentNode.replaceChild(fr, bg);
    bm_show_volume_panel('iframe');
    // Показываем диалог подтверждения сразу только для админов
    if (_bm_is_admin) _bm_video_confirm_show(function() {
      // «Нет» — откатываем к предыдущему фону
      location.href = '?src=' + (window._BM_SRC || '') + ';bm_lobby_action=video_reject';
      window.removeEventListener('message', _yt_msg_handler);
      var cur2 = document.getElementById('bm-bg');
      if (cur2) cur2.parentNode.replaceChild(_prev_bg, cur2);
      bm_show_volume_panel(_prev_media_type);
    });
  }
}

// === ДИАЛОГ ПОДТВЕРЖДЕНИЯ ВИДЕО ===
var _bm_vc_timer = null;
function _bm_video_confirm_show(onNo) {
  _bm_video_confirm_dismiss(); // на случай если старый ещё висит
  var el = document.createElement('div');
  el.id = 'bm-video-confirm';
  el.innerHTML =
    '<span class="bm-vc-text">Видео работает правильно?</span>' +
    '<button class="bm-vc-btn bm-vc-yes">Да</button>' +
    '<button class="bm-vc-btn bm-vc-no">Нет</button>';
  el.querySelector('.bm-vc-yes').addEventListener('click', function() {
    _bm_video_confirm_dismiss();
  });
  el.querySelector('.bm-vc-no').addEventListener('click', function() {
    _bm_video_confirm_dismiss();
    if (onNo) onNo();
  });
  document.body.appendChild(el);
  // Автоматически закрываем через 20 сек если игрок не ответил (считаем что всё ок)
  _bm_vc_timer = setTimeout(_bm_video_confirm_dismiss, 20000);
}
function _bm_video_confirm_dismiss() {
  if (_bm_vc_timer) { clearTimeout(_bm_vc_timer); _bm_vc_timer = null; }
  var el = document.getElementById('bm-video-confirm');
  if (!el) return;
  el.classList.add('dismiss');
  setTimeout(function() { if (el.parentNode) el.parentNode.removeChild(el); }, 300);
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
