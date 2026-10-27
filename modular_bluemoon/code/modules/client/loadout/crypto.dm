/// Reversible loadout encryption shared by the loadout whitelist and admin tools.
/proc/gear_ckey_id(key)
	if(!istext(key) || !length_char(ckey(key)) || length_char(key) > 256)
		return
	return gear_crypto("encrypt", key)

/proc/gear_ckey_from_id(id)
	return gear_crypto("decrypt", id)

/// Diagnostic codes only: never include the secret, plaintext or native exception text.
/proc/gear_crypto_failure(list/diagnostics, error_code)
	if(islist(diagnostics))
		diagnostics["error"] = error_code
	return null

/// Cached bridge to Node's authenticated encryption. Optional diagnostics are caller-owned.
/proc/gear_crypto(operation, value, use_cache = TRUE, list/diagnostics)
	if(islist(diagnostics))
		diagnostics.Cut()
	if(!config)
		return gear_crypto_failure(diagnostics, "config_unavailable")
	var/secret = CONFIG_GET(string/loadout_ckey_secret)
	if(!length_char(secret))
		return gear_crypto_failure(diagnostics, "secret_missing")
	var/static/regex/valid_secret = regex("^\[a-fA-F0-9]{64}$")
	if(!valid_secret.Find(secret))
		return gear_crypto_failure(diagnostics, "invalid_secret_config")
	var/node_executable = CONFIG_GET(string/loadout_crypto_node)
	// Check the in-memory config and caches before resolving Node's path from disk.
	// A changed or removed secret must never reuse plaintext from the old cache.
	var/state = "[secret]|[node_executable]"
	var/static/cached_state
	var/static/list/encrypted = list()
	var/static/list/decrypted = list()
	if(state != cached_state)
		encrypted = list()
		decrypted = list()
		cached_state = state
	if(operation != "encrypt" && operation != "decrypt")
		return gear_crypto_failure(diagnostics, "invalid_request")
	var/is_batch = islist(value)
	if(is_batch)
		if(operation != "decrypt")
			return gear_crypto_failure(diagnostics, "invalid_request")
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
			return gear_crypto_failure(diagnostics, "invalid_text")
		if(operation == "encrypt")
			if(length_char(value) > 256)
				return gear_crypto_failure(diagnostics, "invalid_text")
			if(use_cache && encrypted[value])
				return encrypted[value]
		else
			if(length_char(value) > 1408 || !findtextEx(value, "enc1:", 1, 6))
				return gear_crypto_failure(diagnostics, "invalid_token")
			if(use_cache && (value in decrypted))
				return decrypted[value]
	var/static/regex/unsafe_executable = regex(@"[^A-Za-zА-Яа-яЁё0-9_ ./\\:\-]")
	var/node_source = node_executable == "node" ? "PATH" : "config"
	// The repository build script records process.execPath, including when TGS
	// uses an older installed PreCompile hook that only runs the TGUI build.
	if(node_executable == "node")
		var/path_file_status = "missing"
		if(fexists("tools/loadout_crypto/node_path.txt"))
			var/bootstrap_node = trim(file2text("tools/loadout_crypto/node_path.txt"))
			path_file_status = "invalid"
			if(length_char(bootstrap_node) && !unsafe_executable.Find(bootstrap_node))
				node_executable = bootstrap_node
				node_source = "build"
				path_file_status = "loaded"
		if(islist(diagnostics))
			diagnostics["node_path_file"] = path_file_status
	if(islist(diagnostics))
		diagnostics["node_executable"] = node_executable
		diagnostics["node_source"] = node_source
	if(!length_char(node_executable) || unsafe_executable.Find(node_executable))
		return gear_crypto_failure(diagnostics, "invalid_node_executable")
	if(!fexists("tools/loadout_crypto/crypto.cjs"))
		return gear_crypto_failure(diagnostics, "helper_missing")
	var/request_id
	try
		request_id = rustg_csprng_chacha20(RUSTG_RNG_FORMAT_HEX, LOADOUT_CRYPTO_REQUEST_ID_BYTES)
	catch
		return gear_crypto_failure(diagnostics, "rustg_rng_failed")
	var/static/regex/valid_request_id = regex("^\[a-f0-9]{[LOADOUT_CRYPTO_REQUEST_ID_HEX_LENGTH]}$")
	if(!istext(request_id) || !valid_request_id.Find(request_id))
		return gear_crypto_failure(diagnostics, "rustg_rng_failed")
	var/request_file = "tmp/[LOADOUT_CRYPTO_TMP_FILENAME]_[request_id].json"
	var/response_file = "[request_file].out"
	var/error_file = "[response_file].err"
	if(!text2file(json_encode(list("operation" = operation, "value" = value, "secret" = secret, "diagnostic" = islist(diagnostics))), request_file))
		fdel(request_file)
		return gear_crypto_failure(diagnostics, "request_write_failed")
	var/list/result
	var/failure = "shell_failed"
	try
		var/null_output = world.system_type == MS_WINDOWS ? "NUL" : "/dev/null"
		var/command = "\"[node_executable]\" tools/loadout_crypto/crypto.cjs request [request_file] > [null_output] 2> [error_file]"
		var/exit_code = world.system_type == MS_WINDOWS ? shell("cmd /c \"[command]\"") : shell("sh -c \"[replacetext(command, "\"", "\\\"")]\"")
		if(islist(diagnostics))
			diagnostics["exit_code"] = exit_code
		if(isnull(exit_code))
			failure = "shell_failed"
		else if(exit_code)
			failure = "node_exit_failed"
		else if(!fexists(response_file))
			failure = "response_missing"
		if(!isnull(exit_code) && !exit_code && fexists(response_file))
			failure = "invalid_response"
			result = json_decode(file2text(response_file))
		if(islist(diagnostics) && fexists(error_file))
			var/stderr = lowertext(file2text(error_file))
			// Debug-only callers explicitly requested the original process output.
			diagnostics["stderr"] = file2text(error_file)
			if(findtext(stderr, "not found") || findtext(stderr, "no such file"))
				diagnostics["stderr_code"] = "node_not_found"
			else if(findtext(stderr, "permission denied") || findtext(stderr, "operation not permitted"))
				diagnostics["stderr_code"] = "permission_denied"
			else if(findtext(stderr, "cannot execute") || findtext(stderr, "exec format"))
				diagnostics["stderr_code"] = "node_not_executable"
			else if(length_char(stderr))
				diagnostics["stderr_code"] = "process_stderr"
	catch
		result = null
	fdel(request_file)
	fdel(response_file)
	fdel(error_file)
	if(!islist(result))
		return gear_crypto_failure(diagnostics, failure)
	if(islist(diagnostics))
		var/version = result["node_version"]
		var/static/regex/valid_version = regex("^v\[0-9]+\\.\[0-9]+\\.\[0-9]+$")
		if(istext(version) && valid_version.Find(version))
			diagnostics["node_version"] = version
	if(!result["ok"])
		var/error_code = result["error"]
		if(islist(diagnostics))
			if(istext(result["error_detail"]))
				diagnostics["error_detail"] = result["error_detail"]
		var/static/list/allowed_errors = list("invalid_secret_config", "invalid_text", "invalid_token", "invalid_request", "authentication_failed", "invalid_account", "helper_failed")
		if(!(error_code in allowed_errors))
			error_code = "helper_failed"
		if(use_cache && operation == "decrypt" && !is_batch && (error_code in list("invalid_token", "authentication_failed", "invalid_account")))
			decrypted[value] = null
		return gear_crypto_failure(diagnostics, error_code)
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
