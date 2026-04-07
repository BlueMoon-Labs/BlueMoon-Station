/proc/setup_silicon_law_prefs(mob/living/silicon/Silicon, client/player_client)
	if(!CONFIG_GET(flag/allow_silicon_choosing_laws))
		return

	var/list/config_laws = CONFIG_GET(keyed_list/choosable_laws)
	if(!length(config_laws))
		return

	var/selected_lawset_name = player_client.prefs.silicon_lawset
	if(!selected_lawset_name)
		selected_lawset_name = pick(config_laws)

	var/player_lawset = config_laws[selected_lawset_name]
	if(!player_lawset)
		selected_lawset_name = pick(config_laws)
		player_lawset = config_laws[selected_lawset_name]

	if(player_lawset)
		Silicon.laws = new player_lawset
		Silicon.laws.associate(Silicon) //BM add
		var/admin_warning = "[player_client] / [Silicon] ([initial(Silicon.name)]) has joined with the [selected_lawset_name] ([player_lawset]) lawset.<br>"
		admin_warning += "Laws:<br>"
		admin_warning += english_list(Silicon.laws.get_law_list(TRUE), "No laws", "<br>", "<br>")
		Silicon.laws.show_laws(player_client)
		message_admins(examine_block(admin_warning))
