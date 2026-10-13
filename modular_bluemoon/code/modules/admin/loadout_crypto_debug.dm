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
	var/list/diagnostics = list()
	if(is_decryption)
		result = gear_crypto("decrypt", input, FALSE, diagnostics)
		if(result)
			to_chat(usr, span_notice("Расшифрованный текст: <code>[html_encode(result)]</code>"), confidential = TRUE)
		else
			to_chat(usr, span_warning("Не удалось расшифровать ID. Причина указана в диагностике ниже."), confidential = TRUE)
	else
		result = gear_crypto("encrypt", input, FALSE, diagnostics)
		if(result)
			to_chat(usr, span_notice("Зашифрованный ID: <code>[html_encode(result)]</code>"), confidential = TRUE)
		else
			to_chat(usr, span_warning("Не удалось зашифровать текст. Причина указана в диагностике ниже."), confidential = TRUE)
	if(!result)
		to_chat(usr, span_notice("Loadout crypto: <code>[html_encode(json_encode(diagnostics))]</code>. Расшифровка кодов: tools/loadout_crypto/README.md."), confidential = TRUE)
	// Оставляем в логах шифрованное значение
	log_admin("DEBUG: [key_name_admin(usr)] used Loadout crypto tool[result ? null : " (FAILED)"] ([is_decryption ? "decrypt [input]" : "encrypt[result ? null : " [input]"]"]).")
	var/list/ignore_admin = list()
	for(var/client/admin_cli as anything in GLOB.admins)
		if(!QDELETED(admin_cli) && !check_rights_for(admin_cli, R_DEBUG))
			ignore_admin += admin_cli.key
	// Админам с правами отправляем оригинальное сообщение
	message_admins("DEBUG: [key_name_admin(usr)][ADMIN_FLW(src.mob)] used Loadout crypto tool[result ? null : " (FAILED)"] ([is_decryption ? "decrypt [result ? result : input]" : "encrypt[result ? null : " [input]"]"]).", ignore_ckey = ignore_admin)

