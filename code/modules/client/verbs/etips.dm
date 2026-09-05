/client/verb/toggle_tips()
	set name = "Toggle examine tooltips"
	set desc = "Toggles examine hover-over tooltips"
	set category = "Preferences.Game"

	prefs.enable_tips = !prefs.enable_tips
	prefs.save_pref_var("enable_tips")
	to_chat(usr, "<span class='danger'>Examine tooltips [prefs.enable_tips ? "en" : "dis"]abled.</span>")

/client/verb/change_tip_delay()
	set name = "Set examine tooltip delay"
	set desc = "Sets the delay in milliseconds before examine tooltips appear"
	set category = "Preferences.Game"

	var/indelay = stripped_input(usr, "Enter the tooltip delay in milliseconds (default: 500)", "Enter tooltip delay", "", 10)
	indelay = text2num(indelay)
	if(usr)//is this what you mean?
		prefs.tip_delay = max(indelay, 0.01)
		prefs.save_pref_var("tip_delay")
		to_chat(usr, "<span class='danger'>Tooltip delay set to [indelay] milliseconds.</span>")

/client/verb/toggle_hover_outline()
	set name = "Toggle hover outline"
	set desc = "Toggles hover-over item outline"
	set category = "Preferences.Game"

	prefs.outline_enabled = !prefs.outline_enabled
	prefs.save_pref_var("outline_enabled")
	to_chat(usr, "<span class='danger'>Item outline [prefs.outline_enabled ? "en" : "dis"]abled.</span>")
