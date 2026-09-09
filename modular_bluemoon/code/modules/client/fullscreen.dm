/client/proc/ToggleFullscreen()
	if(prefs.fullscreen)
		winset(src, "mainwindow", "is-maximized=false;can-resize=false;titlebar=false;menu=\"\"")
		winset(src, "mainwindow", "is-maximized=true")
	else
		winset(src, "mainwindow", "is-maximized=false;can-resize=true;titlebar=true;menu=menu")
		winset(src, "mainwindow", "is-maximized=true")
	// Задержка обязана стоять аргументом addtimer: внутри CALLBACK она уходит
	// в сам верб, и подгонка вьюпорта срабатывает мгновенно, дёргая winget.
	addtimer(CALLBACK(src, VERB_REF(fit_viewport)), 1 SECONDS)

/datum/keybinding/client/fullscreen_toggle
	hotkey_keys = list("F11")
	name = "fullscreen_toggle"
	full_name = "Fullscreen"
	description = "Разворачивает игру на весь экран, либо сворачивает обратно в нормальное положение."
	keybind_signal = COMSIG_KB_CLIENT_FULLSCREEN

/datum/keybinding/client/fullscreen_toggle/down(client/user)
	. = ..()
	if(.)
		return
	user.prefs.fullscreen = !user.prefs.fullscreen
	user.ToggleFullscreen()
	return TRUE
