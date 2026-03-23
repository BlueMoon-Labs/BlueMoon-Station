/client/proc/discordnulls()
	set category = "Debug.3) Fixing"
	set name = "Delete Discord Nulls"
	set desc = "Delete rows in the database where discord_id is NULL."
	if(!SSdiscord)
		return
	SSdiscord.delete_nulls()
	message_admins("[key_name(usr)] has attempted to clear NULLs from the discord database")
	log_admin("[key_name(usr)] has attempted to clear NULLs from the discord database")
