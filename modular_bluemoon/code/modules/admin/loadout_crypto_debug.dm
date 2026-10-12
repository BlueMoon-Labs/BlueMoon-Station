/// Utilities for maintaining reversible loadout IDs. Debug-rights only: decrypted text is sent privately.
/client/proc/loadout_crypto_debug()
	set name = "Loadout crypto"
	set category = "Debug.2) Info"
	if(!check_rights(R_DEBUG))
		return
	var/input = tgui_input_text(usr, "Введите текст или enc1 ID", "Loadout crypto", max_length = 1408, multiline = TRUE, encode = FALSE)
	if(isnull(input) || !length_char(input) || !check_rights(R_DEBUG))
		return
	var/is_decryption = findtextEx(input, "enc1:", 1, 6)
	var/result = ""
	if(is_decryption)
		result = gear_crypto("decrypt", input)
		if(result)
			to_chat(usr, span_notice("Расшифрованный текст: <code>[html_encode(result)]</code>"), confidential = TRUE)
		else
			to_chat(usr, span_warning("Не удалось расшифровать ID: неверный формат, ключ или повреждённые данные."), confidential = TRUE)
	else
		result = gear_crypto("encrypt", input, FALSE)
		if(result)
			to_chat(usr, span_notice("Зашифрованный ID: <code>[html_encode(result)]</code>"), confidential = TRUE)
		else
			to_chat(usr, span_warning("Не удалось зашифровать текст: проверьте Node.js и ключ в donator.txt."), confidential = TRUE)
	log_admin("[key_name(usr)] used Loadout crypto debug ([is_decryption ? "decrypt [input]" : "encrypt [result]"]).")
	message_admins("[key_name_admin(usr)] used Loadout crypto debug ([is_decryption ? "decrypt [input]" : "encrypt [result]"]).")
