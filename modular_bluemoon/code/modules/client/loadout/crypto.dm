/// Reversible loadout encryption shared by the loadout whitelist and admin tools.
/proc/gear_ckey_id(key)
	if(!istext(key) || !length_char(ckey(key)) || length_char(key) > 256)
		return
	return gear_crypto("encrypt", key)

/proc/gear_ckey_from_id(id)
	return gear_crypto("decrypt", id)

/// Cached bridge to Node's authenticated encryption. The secret is read directly from config.
/proc/gear_crypto(operation, value, use_cache = TRUE)
	if(!config)
		return
	var/secret = CONFIG_GET(string/loadout_ckey_secret)
	if(!length_char(secret))
		return
	var/node_executable = CONFIG_GET(string/loadout_crypto_node)
	var/static/regex/unsafe_executable = regex(@"[^A-Za-zА-Яа-яЁё0-9_ ./\\:\-]")
	if(!length_char(node_executable) || unsafe_executable.Find(node_executable))
		return
	var/state = "[secret]|[node_executable]"
	var/static/cached_state
	var/static/list/encrypted = list()
	var/static/list/decrypted = list()
	if(state != cached_state)
		encrypted = list()
		decrypted = list()
		cached_state = state
	if(operation != "encrypt" && operation != "decrypt")
		return
	var/is_batch = islist(value)
	if(is_batch)
		if(operation != "decrypt")
			return
		if(use_cache)
			var/list/pending = list()
			for(var/id in value)
				if(istext(id) && !(id in decrypted))
					pending |= id
			if(!length(pending))
				return
			value = pending
	else
		if(!istext(value) || !length_char(value))
			return
		if(operation == "encrypt")
			if(length_char(value) > 256)
				return
			if(use_cache && encrypted[value])
				return encrypted[value]
		else
			if(length_char(value) > 1408 || !findtextEx(value, "enc1:", 1, 6))
				return
			if(use_cache && (value in decrypted))
				return decrypted[value]
	var/request_id = rustg_csprng_chacha20(RUSTG_RNG_FORMAT_HEX, LOADOUT_CRYPTO_REQUEST_ID_BYTES)
	var/static/regex/valid_request_id = regex("^\[a-f0-9]{[LOADOUT_CRYPTO_REQUEST_ID_HEX_LENGTH]}$")
	if(!valid_request_id.Find(request_id))
		return
	var/request_file = "tmp/[LOADOUT_CRYPTO_TMP_FILENAME]_[request_id].json"
	var/response_file = "[request_file].out"
	if(!text2file(json_encode(list("operation" = operation, "value" = value, "secret" = secret)), request_file))
		return
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
		return
	if(!result["ok"])
		if(use_cache && operation == "decrypt" && !is_batch)
			decrypted[value] = null
		return
	if(use_cache && operation == "encrypt")
		encrypted[value] = result["value"]
	else if(use_cache && operation == "decrypt" && !is_batch)
		decrypted[value] = result["value"]
	else if(is_batch && use_cache)
		var/list/ids = value
		var/list/keys = result["value"]
		if(!islist(keys) || length(keys) != length(ids))
			return
		for(var/index in 1 to length(ids))
			decrypted[ids[index]] = keys[index]
	return result["value"]
