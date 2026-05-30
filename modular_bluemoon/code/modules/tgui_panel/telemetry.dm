// Proc for sending Suspicious Logins to Admin Chat
/proc/suspect_message_to_admin_chat(msg)
	message_admins(msg)
	var/suspect_chat_channel_tag = CONFIG_GET(string/chat_suspect_login)
	if (suspect_chat_channel_tag)
		var/tgs_msg = new /datum/tgs_message_content(msg)
		send2chat(tgs_msg, suspect_chat_channel_tag)
