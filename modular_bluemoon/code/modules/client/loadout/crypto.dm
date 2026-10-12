/// Reversible loadout encryption shared by the loadout whitelist and admin tools.
/proc/gear_ckey_id(key)
	if(!istext(key) || !length(ckey(key)) || length(key) > 256)
		return null
	return gear_crypto("encrypt", key)

/proc/gear_ckey_from_id(id)
	if(!istext(id) || length(id) > 384 || !findtextEx(id, "enc1:", 1, 6))
		return null
	return gear_crypto("decrypt", id)

/proc/gear_encrypt_text(text)
	if(!istext(text) || !length(text) || length(text) > 256)
		return null
	return gear_crypto("encrypt_text", text)

/proc/gear_decrypt_text(id)
	if(!istext(id) || length(id) > 384 || !findtextEx(id, "enc1:", 1, 6))
		return null
	return gear_crypto("decrypt_text", id)

/// Cached bridge to Node's authenticated encryption. The secret is read directly from config.
/proc/gear_crypto(operation, value)
	if(!config)
		return null
	var/secret = CONFIG_GET(string/loadout_ckey_secret)
	if(!length(secret))
		return null
	var/node_executable = CONFIG_GET(string/loadout_crypto_node)
	var/static/regex/unsafe_executable = regex("\[^A-Za-zА-Яа-яЁё0-9_ ./\\\\:\\-]")
	if(!length(node_executable) || unsafe_executable.Find(node_executable))
		return null
	var/state = "[secret]|[node_executable]"
	var/static/cached_state
	var/static/list/encrypted = list()
	var/static/list/decrypted = list()
	if(state != cached_state)
		encrypted = list()
		decrypted = list()
		cached_state = state
	if((operation == "encrypt" || operation == "encrypt_text") && encrypted[value])
		return encrypted[value]
	if((operation == "decrypt" || operation == "decrypt_text") && (value in decrypted))
		return decrypted[value]
	if(operation == "decrypt_many")
		var/list/pending = list()
		for(var/id in value)
			if(!(id in decrypted))
				pending |= id
		if(!length(pending))
			return null
		value = pending
	else if(operation != "encrypt" && operation != "decrypt" && operation != "encrypt_text" && operation != "decrypt_text")
		return null
	var/request_id = rustg_csprng_chacha20(RUSTG_RNG_FORMAT_HEX, 16)
	var/static/regex/valid_request_id = regex("^\[a-f0-9]{32}$")
	if(!valid_request_id.Find(request_id))
		return null
	var/request_file = "tmp/[LOADOUT_CRYPTO_TMP_FILENAME]_[request_id].json"
	var/response_file = "[request_file].out"
	if(!text2file(json_encode(list("operation" = operation, "value" = value, "secret" = secret)), request_file))
		return null
	var/list/result
	try
		var/null_output = world.system_type == MS_WINDOWS ? "NUL" : "/dev/null"
		var/command = "\"[node_executable]\" tools/loadout_crypto/crypto.cjs request [request_file] > [null_output] 2>&1"
		var/exit_code = world.system_type == MS_WINDOWS ? shell("cmd /c \"[command]\"") : shell("sh -c \"[replacetext(command, "\"", "\\\"")]\"")
		if(!exit_code && fexists(response_file))
			result = json_decode(file2text(response_file))
	catch
		result = null
	fdel(request_file)
	fdel(response_file)
	if(!islist(result))
		return null
	if(!result["ok"])
		if(operation == "decrypt" || operation == "decrypt_text")
			decrypted[value] = null
		return null
	if(operation == "encrypt" || operation == "encrypt_text")
		encrypted[value] = result["value"]
	else if(operation == "decrypt" || operation == "decrypt_text")
		decrypted[value] = result["value"]
	else
		var/list/ids = value
		var/list/keys = result["value"]
		if(!islist(keys) || length(keys) != length(ids))
			return null
		for(var/index in 1 to length(ids))
			decrypted[ids[index]] = keys[index]
	return result["value"]
