/mob/dead/new_player
	var/bm_lobby_ready = FALSE
	var/bm_bg_slot = 0
	var/bm_assets_sent = FALSE  // asset cache уже отправлен этому клиенту
	COOLDOWN_DECLARE(bm_ready_cd)
	var/bm_lobby_music_path = ""
	var/bm_lobby_track_name = ""

/mob/dead/new_player/Login()
	. = ..()
	bm_show_lobby()
	SStitle_bm?.update_player_counts_all()

/mob/dead/new_player/Destroy()
	// Must run BEFORE parent Destroy: we override base new_player/Destroy, so we must remove ourselves.
	// on_player_ready_change must run before ..() - otherwise we invoke SStitle_bm during/after
	// destruction when we're invalid, causing "illegal operation" crash in GC (REF/Queue chain).
	GLOB.new_player_list -= src
	var/was_ready = ready
	if(was_ready && SStitle_bm)
		SStitle_bm.on_player_ready_change(-1)
	else
		SStitle_bm?.update_player_counts_all()
	return ..()

/mob/dead/new_player/proc/bm_show_lobby()
	if(!client)
		return
	if(spawning || new_character)
		return

	winset(client, null, "map.is-visible=false;status_bar.is-visible=false;bm_lobby_browser.is-disabled=false;bm_lobby_browser.is-visible=false")
	// asset cache: отправляем только один раз за сессию клиента
	if(!bm_assets_sent)
		bm_assets_sent = TRUE
		var/datum/asset/simple/bm_lobby/lobby_asset = get_asset_datum(/datum/asset/simple/bm_lobby)
		lobby_asset.send(src)

	if(!SSticker || SSticker.current_state <= GAME_STATE_STARTUP)
		var/loading_rsc = SStitle_bm?.loading_image
		if(loading_rsc)
			src << browse(loading_rsc, "file=bm_stub_bg.gif;display=0")
		src << browse(_bm_build_loading_stub(), "window=bm_lobby_browser")
		winset(client, "bm_lobby_browser", "is-visible=true")
		return

	var/img_to_send = _bm_get_current_image()
	if(img_to_send)
		src << browse(img_to_send, "file=loading_screen.gif;display=0")
	src << browse(_bm_build_html(), "window=bm_lobby_browser")
	winset(client, "bm_lobby_browser", "is-visible=true")

/mob/dead/new_player/proc/bm_update_lobby_html()
	if(!client)
		return
	bm_lobby_ready = FALSE
	src << browse(_bm_build_html(), "window=bm_lobby_browser")

/mob/dead/new_player/proc/bm_push_menu_update(ingame = FALSE)
	if(!client || !bm_lobby_ready)
		return
	client << output("[ingame ? 1 : 0]", "bm_lobby_browser:bm_rebuild_menu")

/// Возвращает текущий rsc фона для этого игрока. Вызывается только после STARTUP (SStitle_bm гарантированно initialized).
/mob/dead/new_player/proc/_bm_get_current_image()
	var/show_nsfw = client?.prefs?.bm_lobby_show_nsfw || FALSE
	var/show_admin_bg = !client?.prefs || client.prefs.bm_lobby_show_admin_bg
	return SStitle_bm?.get_image_for_player(show_nsfw, show_admin_bg)

/mob/dead/new_player/proc/bm_hide_lobby()
	if(!client)
		return
	bm_lobby_ready = FALSE
	winset(client, null, "bm_lobby_browser.is-disabled=true;bm_lobby_browser.is-visible=false;map.is-visible=true;status_bar.is-visible=true")
	client << browse(null, "window=bm_lobby_browser")

/mob/dead/new_player/proc/bm_push_background()
	if(!client || !bm_lobby_ready)
		return
	var/show_admin_bg = !client.prefs || client.prefs.bm_lobby_show_admin_bg
	if(SStitle_bm?.current_video_payload && show_admin_bg)
		client << output(SStitle_bm.current_video_payload, "bm_lobby_browser:bm_set_background")
		return
	var/show_nsfw = client.prefs?.bm_lobby_show_nsfw || FALSE
	var/img_to_send = SStitle_bm?.get_image_for_player(show_nsfw, show_admin_bg)
	if(!img_to_send)
		return
	bm_bg_slot = bm_bg_slot ? 0 : 1
	var/filename = "bm_bg_[bm_bg_slot].gif"
	src << browse(img_to_send, "file=[filename];display=0")
	client << output(filename, "bm_lobby_browser:bm_set_background")

/mob/dead/new_player/proc/_bm_build_loading_stub()
	// Фон — bm_stub_bg.gif, отправленный через browse() до этого вызова.
	return {"<!DOCTYPE html><html><head><meta charset='UTF-8'>
<style>
*{box-sizing:border-box;margin:0;padding:0;}
body,html{width:100%;height:100%;overflow:hidden;background:#000;font-family:'Courier New',monospace;color:#4af;}
.bg{position:fixed;top:0;left:0;width:100%;height:100%;object-fit:cover;z-index:0;}
.overlay{position:fixed;top:0;left:0;width:100%;height:100%;background:rgba(0,0,10,0.25);z-index:1;}
.wrap{position:fixed;top:0;left:0;width:100%;height:100%;z-index:2;display:flex;flex-direction:column;align-items:center;}
.top{flex:1;display:flex;flex-direction:column;align-items:center;justify-content:center;padding-bottom:6vmin;}
.title{font-size:clamp(18px,4.5vmin,42px);letter-spacing:6px;text-shadow:0 0 18px rgba(80,180,255,0.9);margin-bottom:1.2vmin;}
.sub{font-size:clamp(9px,1.6vmin,15px);letter-spacing:3px;color:rgba(80,140,220,0.7);}
.bottom{width:100%;padding:0 8vmin 4vmin;}
.bar-label{font-size:clamp(8px,1.2vmin,12px);letter-spacing:2px;color:rgba(80,140,220,0.55);margin-bottom:1.2vmin;}
.bar-track{width:100%;height:3px;background:rgba(40,100,255,0.12);border-radius:2px;overflow:hidden;}
.bar-fill{height:100%;position:relative;}
.bar-fill::before{content:'';position:absolute;top:0;bottom:0;width:40%;left:0;background:linear-gradient(90deg,transparent,#4af,transparent);animation:bm-ray 1.6s ease-in-out infinite;}
.bar-fill::after{content:'';position:absolute;top:0;bottom:0;width:20%;left:0;background:linear-gradient(90deg,transparent,#adf,transparent);animation:bm-ray 1.6s ease-in-out 0.5s infinite;}
@keyframes bm-ray{from{transform:translateX(-100%)}to{transform:translateX(350%)}}
</style></head>
<body>
<img class='bg' src='bm_stub_bg.gif' alt=''>
<div class='overlay'></div>
<div class='wrap'>
  <div class='top'>
    <div class='title'>BLUEMOON STATION</div>
    <div class='sub'>SPACE STATION 13</div>
  </div>
  <div class='bottom'>
    <div class='bar-label'>LOADING<span id='d'></span></div>
    <div class='bar-track'><div class='bar-fill' id='bar'></div></div>
  </div>
</div>
<script>
var _i=0;setInterval(function(){var s=_i%4;document.getElementById('d').textContent=s===1?' .':s===2?'..':s===3?'...':'';_i++;},400);
</script>
</body></html>"}

/mob/dead/new_player/proc/_bm_build_html()
	var/R = REF(src)
	var/list/parts = list()

	parts += SStitle_bm?.lobby_html || BM_DEFAULT_LOBBY_HTML_PREAMBLE

	// статические части (bg, overlay, toasts, toggle-btn) из кеша подсистемы
	if(SStitle_bm?.cached_static_html != "")
		parts += SStitle_bm.cached_static_html
	else
		parts += {"<img id="bm-bg" class="bg" src="loading_screen.gif" alt=\"\">"}
		parts += {"<div id=\"bm-overlay\"></div>"}
		parts += {"<div id=\"bm-toasts\"></div>"}
		parts += {"<div id=\"bm-toggle-btn\" onclick=\"bmToggleSidebar()\" title=\"Свернуть/развернуть меню\">&#9664;</div>"}

	// динамическая часть
	parts += {"<div id=\"bm-sidebar\">"}
	parts += {"<div id=\"bm-logo\">
  <div class=\"bm-title-text\">BLUEMOON<br>STATION</div>
  <div class=\"bm-subtitle-text\">SPACE STATION 13</div>
  <button id=\"bm-settings-btn\" onclick=\"bmToggleSettings()\">&#9881; НАСТРОЙКИ</button>
  <div id=\"bm-settings-panel\">
    <div class=\"bm-settings-title\">НАСТРОЙКИ ЛОББИ</div>
    <a class="bm-settings-row" href='?src=[R];bm_lobby_action=toggle_nsfw' style="cursor:pointer">
      <span class="bm-s-label">NSFW КОНТЕНТ</span>
      <span class="bm-s-value" id="bm-s-nsfw">ВЫКЛ</span>
    </a>
    <a class="bm-settings-row" href='?src=[R];bm_lobby_action=toggle_admin_bg' style="cursor:pointer">
      <span class="bm-s-label">МЕДИА ОТ АДМИНОВ</span>
      <span class="bm-s-value" id="bm-s-adminbg">ВКЛ</span>
    </a>
  </div>
  <div id=\"bm-player-count\">&#183; &#183; &#183;</div>
</div>"}
	parts += {"<div id=\"bm-menu\">"}
	parts += _bm_build_menu()
	parts += "</div>"

	var/char_name = html_encode(uppertext(client?.prefs?.real_name || ""))
	parts += {"<div id=\"bm-footer\">
  <div id=\"bm-char-name\">[char_name ? char_name : "\u2014 \u2014 \u2014"]</div>
  <div id=\"bm-count-row\">
    <span class=\"bm-count-lbl\">В ЛОББИ&nbsp;<span class=\"bm-count-val\" id=\"bm-count-online\">&#8212;</span></span>
    <span id=\"bm-count-ready-wrap\" class=\"bm-count-lbl\">ГОТОВЫ&nbsp;<span class=\"bm-count-val\" id=\"bm-count-ready\">&#8212;</span></span>
  </div>
</div>"}
	parts += {"<div id=\"bm-countdown-row\" style=\"display:none\">
  <span class=\"bm-countdown-label\">ДО СТАРТА</span>&nbsp;<span id=\"bm-countdown-val\">—</span>
</div>"}
	parts += {"<div id=\"bm-audio-bar\">
  <div id=\"bm-audio-row\">
    <button class=\"bm-audio-btn\" id=\"bm-btn-play\" onclick=\"bmAudioPlay()\">&#9654;</button>
    <div id=\"bm-audio-track\">нет трека</div>
    <button class=\"bm-audio-btn\" id=\"bm-btn-mute\" onclick=\"bmAudioMute()\">&#128264;</button>
    <input type=\"range\" id=\"bm-audio-vol\" min=\"0\" max=\"100\" value=\"35\" oninput=\"bmAudioVolume(this.value)\" onchange=\"bmAudioVolume(this.value)\" title=\"Громкость\">
  </div>
  <div id=\"bm-video-row\" style=\"display:none\">
    <button class=\"bm-audio-btn\" id=\"bm-btn-video-mute\" onclick=\"bmVideoMute()\">&#128263;</button>
    <div id=\"bm-video-label\">ВИДЕО</div>
    <input type=\"range\" id=\"bm-video-vol\" min=\"0\" max=\"100\" value=\"0\" oninput=\"bmVideoVolume(this.value)\" onchange=\"bmVideoVolume(this.value)\" title=\"Громкость видео\">
  </div>
</div>
<audio id=\"bm-audio\" loop></audio></div>"}

	var/show_nsfw = client?.prefs?.bm_lobby_show_nsfw || FALSE
	var/show_admin_bg = !client?.prefs || client.prefs.bm_lobby_show_admin_bg
	var/notice_js = SStitle_bm?.cached_notice_js || ""
	var/admin_js = "bm_set_admin([check_rights_for(client, R_SERVER) ? 1 : 0]);"
	var/registered_js = "bm_set_registered([(!is_guest_key(src.key) && client?.prefs) ? 1 : 0]);"
	var/antag_js = "_bm_antag_state=[!(client?.prefs?.toggles & NO_ANTAG) ? 1 : 0];"

	var/js_url = SStitle_bm?.cached_js_url
	if(!js_url)
		var/datum/asset/simple/bm_lobby/lobby_asset = get_asset_datum(/datum/asset/simple/bm_lobby)
		js_url = lobby_asset.get_url_mappings()["bm_lobby.js"]
		if(SStitle_bm)
			SStitle_bm.cached_js_url = js_url // кешируем, чтобы не пересчитывать каждый раз
	// async — не блокирует парсинг HTML; page_ready отправляется только после загрузки скрипта
	// при кеш-хите (typeof bm_set_admin==='function') init срабатывает сразу синхронно
	parts += {"<script src=\"[js_url]\" async id=\"bm-js\"></script>"}
	parts += {"<script>
(function(){
  var _src='[R]';
  function __bm_init(){
    window._BM_SRC=_src;
    bm_update_nsfw_indicator([show_nsfw ? 1 : 0]);
    bm_update_admin_bg_indicator([show_admin_bg ? 1 : 0]);
    [admin_js]
    [registered_js]
    [antag_js]
    [notice_js]
    if(!window.__bm_page_ready_sent){window.__bm_page_ready_sent=true;location.href='?src='+_src+';bm_lobby_action=page_ready';}
  }
  if(typeof bm_set_admin==='function'){__bm_init();}
  else{document.getElementById('bm-js').addEventListener('load',__bm_init);}
})();
</script>"}

	parts += "</body></html>"
	return parts.Join("")

/mob/dead/new_player/proc/_bm_build_menu()
	var/list/parts = list()
	var/R = REF(src)

	if(!SSticker || SSticker.current_state <= GAME_STATE_PREGAME)
		parts += {"<a id='bm-btn-ready' class='bm-btn' href='?src=[R];bm_lobby_action=toggle_ready'>"}
		parts += ready ? {"<span class='bm-checked'>☑</span> ГОТОВНОСТЬ"} : {"<span class='bm-unchecked'>☒</span> ГОТОВНОСТЬ"}
		parts += "</a>"
	else
		parts += {"<a class='bm-btn' href='?src=[R];bm_lobby_action=late_join'>ВОЙТИ В ИГРУ</a>"}
		parts += {"<a class='bm-btn' href='?src=[R];bm_lobby_action=view_manifest'>СПИСОК ЭКИПАЖА</a>"}
		parts += {"<a class='bm-btn' href='?src=[R];bm_lobby_action=character_directory'>БИБЛИОТЕКА ПЕРСОНАЖЕЙ</a>"}

	parts += {"<a class='bm-btn' href='?src=[R];bm_lobby_action=observe'>БЫТЬ НАБЛЮДАТЕЛЕМ</a>"}

	parts += "<div class='bm-divider'></div>"

	parts += {"<a class='bm-btn' href='?src=[R];bm_lobby_action=character_setup'>НАСТРОЙКА ПЕРСОНАЖА</a>"}
	parts += {"<a class='bm-btn' href='?src=[R];bm_lobby_action=game_options'>ПАРАМЕТРЫ ИГРЫ</a>"}

	var/is_antag_opted = !(client?.prefs?.toggles & NO_ANTAG)
	parts += {"<a id='bm-btn-antag' class='bm-btn' href='?src=[R];bm_lobby_action=toggle_antag'>"}
	parts += is_antag_opted ? {"<span class='bm-checked'>☑</span> РОЛЬ АНТАГОНИСТА"} : {"<span class='bm-unchecked'>☒</span> РОЛЬ АНТАГОНИСТА"}
	parts += "</a>"

	if(!is_guest_key(src.key) && client?.prefs)
		parts += {"<a class='bm-btn' href='?src=[R];bm_lobby_action=changelog'>ПОСЛЕДНИЕ ОБНОВЛЕНИЯ</a>"}
		parts += {"<a class='bm-btn' href='?src=[R];bm_lobby_action=polls_menu'>ОПРОСЫ СЕРВЕРА</a>"}

	if((!SSticker || SSticker.current_state <= GAME_STATE_PREGAME) && check_rights_for(client, R_SERVER))
		parts += {"<div class='bm-start-game-wrap'><a class='bm-btn bm-btn-admin' href='?src=[R];bm_lobby_action=start_game'>&#9889; СТАРТ ИГРЫ</a></div>"}

	return parts.Join("")

// ===========================
// ОБРАБОТКА HREF-ЗАПРОСОВ
// ===========================

/mob/dead/new_player/Topic(href, href_list[])
	if(src != usr)
		return FALSE
	if(!client)
		return FALSE

	if(!href_list["bm_lobby_action"])
		return ..()

	var/action = href_list["bm_lobby_action"]

	switch(action)
		if("page_ready")
			bm_lobby_ready = TRUE
			bm_push_background()
			SStitle_bm?.push_player_count_to(src)
			if(bm_lobby_music_path != "" || SSticker?.login_music)
				client.bm_push_lobby_music()
			return

		if("toggle_ready")
			_bm_play_click_sound()
			if(!COOLDOWN_FINISHED(src, bm_ready_cd))
				return FALSE
			COOLDOWN_START(src, bm_ready_cd, 0.6 SECONDS)
			if(!ready && !check_preferences())
				// check_preferences уже выставил ready = PLAYER_NOT_READY и ineligible_for_roles
				client << output("Выберите хотя бы одну профессию в настройках персонажа, иначе вы не сможете войти в раунд.", "bm_lobby_browser:bm_show_notice")
				client << output(FALSE, "bm_lobby_browser:bm_toggle_ready")
				return FALSE
			if(!ready && client.prefs && !(client.prefs.toggles & NO_ANTAG))
				if(alert(src, "У вас включена возможность стать антагонистом. Вы уверены, что не хотите выключить её?", "...Клянусь, что не сдам роль...", "Я готов", "Прошу временно отключить") == "Прошу временно отключить")
					if(QDELETED(src) || !client)
						return
					client.prefs.toggles ^= NO_ANTAG
					to_chat(src, "<span class='redtext'>На этот раунд, у вас отключена возможность стать антагонистом (её можно включить через кнопку роли антагониста).</span>")
					client << output(!(client.prefs.toggles & NO_ANTAG), "bm_lobby_browser:bm_toggle_antag")
			if(QDELETED(src) || !client)
				return
			ready = !ready
			SStitle_bm?.on_player_ready_change(ready ? 1 : -1)
			client << output(ready, "bm_lobby_browser:bm_toggle_ready")
			return

		if("toggle_antag")
			_bm_play_click_sound()
			var/datum/preferences/prefs = client.prefs
			if(prefs)
				prefs.toggles ^= NO_ANTAG
				var/antag_on = !(prefs.toggles & NO_ANTAG)
				if(antag_on)
					prefs.toggles |= MIDROUND_ANTAG
				else
					prefs.toggles &= ~MIDROUND_ANTAG
				prefs.save_preferences()
				client << output(antag_on, "bm_lobby_browser:bm_toggle_antag")
			return

		if("toggle_nsfw")
			if(client?.prefs)
				client.prefs.bm_lobby_show_nsfw = !client.prefs.bm_lobby_show_nsfw
				client.prefs.save_preferences()
				client << output(client.prefs.bm_lobby_show_nsfw, "bm_lobby_browser:bm_update_nsfw_indicator")
				bm_push_background()
			return

		if("toggle_admin_bg")
			if(client?.prefs)
				client.prefs.bm_lobby_show_admin_bg = !client.prefs.bm_lobby_show_admin_bg
				client.prefs.save_preferences()
				client << output(client.prefs.bm_lobby_show_admin_bg, "bm_lobby_browser:bm_update_admin_bg_indicator")
				bm_push_background()
			return

		if("observe")
			_bm_play_click_sound()
			var/prev_ready = ready
			make_me_an_observer()
			if(!QDELETED(src) && client && !spawning && ready != prev_ready)
				if(prev_ready && !ready)
					SStitle_bm?.on_player_ready_change(-1)
				client << output(ready, "bm_lobby_browser:bm_toggle_ready")
			return

		if("late_join")
			_bm_play_click_sound()
			LateChoices()
			return

		if("view_manifest")
			_bm_play_click_sound()
			ViewManifest()
			return

		if("character_directory")
			_bm_play_click_sound()
			client.show_character_directory()
			return

		if("character_setup")
			_bm_play_click_sound()
			client.prefs.current_tab = SETTINGS_TAB
			client.prefs.ShowChoices(src)
			return

		if("game_options")
			_bm_play_click_sound()
			client.prefs.current_tab = PREFERENCES_TAB
			client.prefs.ShowChoices(src)
			return

		if("polls_menu")
			if(is_guest_key(src.key))
				return
			_bm_play_click_sound()
			if(SSvote?.mode)
				SSvote.ui_interact(src)
			else
				client << output("Активных голосований нет.", "bm_lobby_browser:bm_show_notice")
			return

		if("changelog")
			_bm_play_click_sound()
			if(!GLOB.changelog_tgui)
				GLOB.changelog_tgui = new /datum/changelog()
			GLOB.changelog_tgui.ui_interact(src)
			return

		if("start_game")
			if(!check_rights_for(client, R_SERVER))
				return
			if(!SSticker || SSticker.current_state != GAME_STATE_PREGAME)
				return
			_bm_play_click_sound()
			if(tgui_alert(src, "Вы действительно хотите начать игру?", "Старт раунда", list("Да", "Нет")) != "Да")
				return
			if(QDELETED(src) || !client)
				return
			if(!SSticker || SSticker.current_state != GAME_STATE_PREGAME)
				return
			SSticker.start_immediately = TRUE
			log_admin("[key_name(src)] запустил раунд через HTML-лобби.")
			message_admins("[key_name_admin(src)] запустил раунд через HTML-лобби.")
			return

		if("video_reject")
			if(!check_rights_for(client, R_FUN))
				return
			if(!SStitle_bm?.current_video_payload)
				return
			log_admin("[key_name(src)] убрал видео с лобби (подтверждение не прошло).")
			message_admins("[key_name_admin(src)] убрал видео с лобби (видео работало некорректно).")
			SStitle_bm.change_image(null)
			return

	return ..()

/mob/dead/new_player/proc/_bm_play_click_sound()
	SEND_SOUND(src, sound('sound/misc/menu/ui_select1.ogg'))

/datum/asset/simple/bm_lobby
	assets = list(
		"bm_lobby.js" = 'modular_bluemoon/assets/js/bm_lobby.js'
	)
