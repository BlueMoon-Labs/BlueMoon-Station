/// Utilities for maintaining reversible loadout IDs. Debug-rights only: decrypted text is sent privately.
/client/proc/loadout_crypto_debug()
	set name = "Loadout crypto"
	set category = "Debug.2) Info"
	if(!check_rights(R_DEBUG))
		return
	var/input = tgui_input_text(usr, "Введите текст или enc1 ID", "Loadout crypto", max_length = 384, multiline = TRUE, encode = FALSE)
	if(isnull(input) || !length(input) || !check_rights(R_DEBUG))
		return
	var/is_decryption = findtextEx(input, "enc1:", 1, 6)
	log_admin("[key_name(usr)] used Loadout crypto debug ([is_decryption ? "decrypt" : "encrypt"]).")
	if(is_decryption)
		var/decrypted = gear_decrypt_text(input)
		if(decrypted)
			to_chat(usr, span_notice("Расшифрованный текст: <code>[html_encode(decrypted)]</code>"), confidential = TRUE)
		else
			to_chat(usr, span_warning("Не удалось расшифровать ID: неверный формат, ключ или повреждённые данные."), confidential = TRUE)
	else
		var/encrypted = gear_encrypt_text(input)
		if(encrypted)
			to_chat(usr, span_notice("Зашифрованный ID: <code>[html_encode(encrypted)]</code>"), confidential = TRUE)
		else
			to_chat(usr, span_warning("Не удалось зашифровать текст: проверьте Node.js и ключ в donator.txt."), confidential = TRUE)
