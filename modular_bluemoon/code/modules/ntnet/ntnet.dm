#define NTNET_REFRESH_INTERVAL (5 MINUTES)
#define NTNET_RETRY_INTERVAL (30 SECONDS)
#define NTNET_STALE_PAGE_RETRY (5 SECONDS)
#define NTNET_IDLE_TIMEOUT (15 MINUTES)
#define NTNET_REQUEST_TIMEOUT (20 SECONDS)
#define NTNET_LOGIN_COOLDOWN (1 MINUTES)
#define NTNET_CODE_LIFETIME (15 MINUTES)
#define NTNET_MAX_INDEX_BYTES (512 * 1024)
#define NTNET_MAX_PAGE_BYTES (96 * 1024)
#define NTNET_MAX_SEARCH_BYTES (64 * 1024)
#define NTNET_MAX_LOGIN_BYTES 4096
#define NTNET_MAX_SITES 500
#define NTNET_MAX_PAGES 20
#define NTNET_CACHE_PAGES 32
#define NTNET_MAX_REQUESTS 6
#define NTNET_MAX_FRAME_URL 200
#define NTNET_MAX_TEXT 4000
#define NTNET_MAX_TREE_DEPTH 12
#define NTNET_SEARCH_MAX_RESULTS 20
#define NTNET_SEARCH_MAX_SNIPPET 400
#define NTNET_VIEWER_TOKEN_TTL (1 HOURS)
#define NTNET_VIEWER_TOKEN_MARGIN (5 MINUTES)
#define NTNET_VIEWER_TOKEN_COOLDOWN (10 SECONDS)
#define NTNET_VIEWER_MAX_TOKENS 16
#define NTNET_VIEWER_MAX_TOKEN_LENGTH 1024
#define NTNET_VIEWER_MAX_NAME 64

SUBSYSTEM_DEF(ntnet)
	name = "NTnet"
	wait = 1
	flags = SS_NO_INIT | SS_BACKGROUND | SS_TICKER
	runlevels = RUNLEVEL_LOBBY | RUNLEVELS_DEFAULT

	var/list/sites = list()
	var/list/catalog = list()
	var/list/pages = list()
	var/list/page_retry = list()
	var/list/page_wait = list()
	var/list/pending = list()
	var/list/requests = list()
	var/list/deadlines = list()
	var/available = FALSE
	var/index_pending = FALSE
	var/next_refresh = 0
	var/last_used = -INFINITY
	var/generation = 0
	var/viewer_answers = 0

/datum/controller/subsystem/ntnet/fire(resumed = FALSE)
	collect_requests()
	if(world.time > last_used + NTNET_IDLE_TIMEOUT)
		return
	refresh_index()

/datum/controller/subsystem/ntnet/proc/is_enabled()
	return CONFIG_GET(flag/ntnet_enabled) && CONFIG_GET(string/ntnet_api_url) && CONFIG_GET(string/ntnet_server_key)

/datum/controller/subsystem/ntnet/proc/request(method, url, body, datum/callback/answer)
	if(length(requests) >= NTNET_MAX_REQUESTS)
		return FALSE
	var/headers = json_encode(list("X-Server-Key" = CONFIG_GET(string/ntnet_server_key), "Content-Type" = "application/json"))
	var/job = rustg_http_request_async(method, url, body, headers, "")
	if(isnull(text2num(job)))
		return FALSE
	requests[job] = answer
	deadlines[job] = world.time + NTNET_REQUEST_TIMEOUT
	return TRUE

/datum/controller/subsystem/ntnet/proc/collect_requests()
	for(var/job in requests.Copy())
		var/result = rustg_http_check_request(job)
		if(result == RUSTG_JOB_NO_RESULTS_YET && world.time < deadlines[job])
			continue
		var/datum/callback/answer = requests[job]
		requests -= job
		deadlines -= job
		answer.InvokeAsync(decode_response(result))

/datum/controller/subsystem/ntnet/proc/decode_response(result)
	if(!istext(result) || result == RUSTG_JOB_NO_RESULTS_YET || result == RUSTG_JOB_NO_SUCH_JOB || result == RUSTG_JOB_ERROR)
		return
	var/list/document = decode_json(result)
	if(!islist(document) || !isnum(document["status_code"]) || !istext(document["body"]))
		return
	return document

/datum/controller/subsystem/ntnet/proc/decode_json(source)
	if(!istext(source))
		return
	try
		return json_decode(source)
	catch
		return

/datum/controller/subsystem/ntnet/proc/api_url(path)
	return "[CONFIG_GET(string/ntnet_api_url)]/api/v1/[path]"

/datum/controller/subsystem/ntnet/proc/refresh_index()
	if(world.time < next_refresh || index_pending || !is_enabled())
		return
	if(!request(RUSTG_HTTP_METHOD_GET, api_url("catalog"), "", CALLBACK(src, PROC_REF(on_index))))
		return
	index_pending = TRUE
	next_refresh = world.time + NTNET_REFRESH_INTERVAL

/datum/controller/subsystem/ntnet/proc/on_index(list/response)
	index_pending = FALSE
	available = FALSE
	next_refresh = world.time + NTNET_RETRY_INTERVAL
	if(!islist(response) || response["status_code"] != 200 || length(response["body"]) > NTNET_MAX_INDEX_BYTES)
		return
	var/list/document = decode_json(response["body"])
	if(!islist(document) || !islist(document["sites"]))
		return
	var/list/entries = document["sites"]
	if(length(entries) > NTNET_MAX_SITES)
		return
	var/list/new_sites = list()
	for(var/list/site as anything in entries)
		if(!islist(site) || !istext(site["id"]) || !length(site["id"]) || length(site["id"]) > 64)
			return
		if(!istext(site["domain"]) || !istext(site["title"]) || !istext(site["version"]) || !isnum(text2num(site["version"])) || !islist(site["pages"]))
			return
		var/list/site_pages = site["pages"]
		if(new_sites[site["id"]] || !length(site_pages) || length(site_pages) > NTNET_MAX_PAGES)
			return
		var/list/slugs = list()
		for(var/list/page as anything in site_pages)
			if(!islist(page) || !istext(page["slug"]) || !length(page["slug"]) || length(page["slug"]) > 64)
				return
			if(!istext(page["title"]) || (page["slug"] in slugs))
				return
			slugs += page["slug"]
		if(!isnull(site["icon"]) && !media_address(site["icon"]))
			site -= "icon"
		new_sites[site["id"]] = site
	sites = new_sites
	catalog = entries
	for(var/cache_key in pages.Copy())
		var/list/cached = pages[cache_key]
		var/list/site = sites[cached["site_id"]]
		if(!site || text2num(cached["version"]) < text2num(site["version"]))
			pages -= cache_key
	page_retry.Cut()
	page_wait.Cut()
	generation++
	next_refresh = world.time + NTNET_REFRESH_INTERVAL
	available = TRUE

/datum/controller/subsystem/ntnet/proc/force_refresh(site_id, slug)
	next_refresh = 0
	refresh_index()
	if(!site_id)
		return
	var/cache_key = json_encode(list(site_id, slug))
	pages -= cache_key
	page_retry -= cache_key
	page_wait -= cache_key
	request_page(site_id, slug)

/datum/controller/subsystem/ntnet/proc/has_page(site_id, slug)
	if(!istext(site_id) || !istext(slug))
		return FALSE
	var/list/site = sites[site_id]
	if(!site)
		return FALSE
	for(var/list/page as anything in site["pages"])
		if(page["slug"] == slug)
			return TRUE
	return FALSE

/datum/controller/subsystem/ntnet/proc/resolve(address)
	if(!istext(address))
		return
	var/domain = lowertext(trim(address))
	var/slug = "index"
	var/divider = findtext(domain, "/")
	if(divider)
		slug = copytext(domain, divider + 1)
		domain = copytext(domain, 1, divider)
	if(!length(domain) || !length(slug))
		return
	for(var/site_id in sites)
		var/list/site = sites[site_id]
		if(site["domain"] != domain)
			continue
		if(!has_page(site_id, slug))
			return
		return list(site_id, slug)

/datum/controller/subsystem/ntnet/proc/request_page(site_id, slug)
	if(!is_enabled() || !has_page(site_id, slug))
		return
	var/cache_key = json_encode(list(site_id, slug))
	if(pages[cache_key] || pending[cache_key] || world.time < page_retry[cache_key] || world.time < page_wait[cache_key])
		return
	var/url = api_url("sites/[url_encode(site_id)]/pages/[url_encode(slug)]")
	if(!request(RUSTG_HTTP_METHOD_GET, url, "", CALLBACK(src, PROC_REF(on_page), site_id, slug)))
		return
	pending[cache_key] = TRUE

/datum/controller/subsystem/ntnet/proc/page_failed(site_id, slug)
	var/cache_key = json_encode(list(site_id, slug))
	return !pages[cache_key] && world.time < page_retry[cache_key]

/datum/controller/subsystem/ntnet/proc/on_page(site_id, slug, list/response)
	var/cache_key = json_encode(list(site_id, slug))
	pending -= cache_key
	if(!islist(response) || response["status_code"] >= 500)
		available = FALSE
		page_retry[cache_key] = world.time + NTNET_RETRY_INTERVAL
		return
	available = TRUE
	if(response["status_code"] == 404)
		next_refresh = min(next_refresh, world.time + NTNET_RETRY_INTERVAL)
	if(response["status_code"] != 200 || length(response["body"]) > NTNET_MAX_PAGE_BYTES)
		page_retry[cache_key] = world.time + NTNET_RETRY_INTERVAL
		return
	if(!has_page(site_id, slug))
		return
	var/list/site = sites[site_id]
	var/list/document = decode_json(response["body"])
	var/document_version = islist(document) && istext(document["version"]) ? text2num(document["version"]) : null
	if(!islist(document) || document["site_id"] != site_id || document["slug"] != slug || !isnum(document_version))
		page_retry[cache_key] = world.time + NTNET_RETRY_INTERVAL
		return
	var/catalog_version = text2num(site["version"])
	if(document_version < catalog_version)
		page_wait[cache_key] = world.time + NTNET_STALE_PAGE_RETRY
		return
	if(document_version > catalog_version)
		next_refresh = 0
	var/list/frame = document["interactive"]
	var/address = islist(frame) ? frame["url"] : null
	var/list/stored = list(
		"site_id" = site_id,
		"slug" = slug,
		"version" = document["version"],
		"title" = istext(document["title"]) ? document["title"] : slug,
		"frame" = (CONFIG_GET(flag/ntnet_interactive) && frame_address(address)) ? address : null,
		"text" = text_from_tree(document["tree"]),
	)
	if(length(pages) >= NTNET_CACHE_PAGES)
		pages.Cut(1, 2)
	pages[cache_key] = stored
	page_retry -= cache_key
	page_wait -= cache_key

/datum/controller/subsystem/ntnet/proc/text_from_tree(list/node, depth = 0)
	if(depth > NTNET_MAX_TREE_DEPTH || !islist(node))
		return ""
	var/list/words = list()
	if(node["type"] == "text" && istext(node["text"]))
		words += node["text"]
	else if(node["type"] == "image" && istext(node["alt"]))
		words += node["alt"]
	if(islist(node["children"]))
		for(var/list/child as anything in node["children"])
			words += text_from_tree(child, depth + 1)
	var/joined = jointext(words, " ")
	return depth ? joined : copytext(joined, 1, NTNET_MAX_TEXT)

/datum/controller/subsystem/ntnet/proc/media_address(address)
	var/static/regex/media = regex(@"^https://[a-z0-9.-]{4,64}/[a-f0-9]{32}/[a-f0-9]{16}\.(?:png|jpg|gif|webp)$")
	return istext(address) && length(address) <= NTNET_MAX_FRAME_URL && media.Find(address)

/datum/controller/subsystem/ntnet/proc/frame_address(address)
	if(!istext(address) || length(address) > NTNET_MAX_FRAME_URL)
		return FALSE
	var/static/regex/frame = regex(@"^https://([a-z0-9.-]{4,64})/i/[a-f0-9]{32}/[a-z0-9][a-z0-9-]{0,62}$")
	if(!frame.Find(address))
		return FALSE
	return frame.group[1] == CONFIG_GET(string/ntnet_sandbox_host)

/datum/controller/subsystem/ntnet/proc/search(query, datum/callback/answer)
	if(!is_enabled())
		return FALSE
	return request(RUSTG_HTTP_METHOD_GET, api_url("search?q=[url_encode(query)]"), "", answer)

/datum/controller/subsystem/ntnet/proc/search_results(list/response)
	if(!islist(response) || response["status_code"] != 200 || length(response["body"]) > NTNET_MAX_SEARCH_BYTES)
		return
	var/list/document = decode_json(response["body"])
	if(!islist(document) || !islist(document["results"]) || length(document["results"]) > NTNET_SEARCH_MAX_RESULTS)
		return
	var/list/found = list()
	for(var/list/entry as anything in document["results"])
		if(!islist(entry) || !istext(entry["site_id"]) || !istext(entry["slug"]) || !istext(entry["title"]) || !istext(entry["snippet"]))
			continue
		if(length(entry["snippet"]) > NTNET_SEARCH_MAX_SNIPPET || !has_page(entry["site_id"], entry["slug"]))
			continue
		found += list(entry)
	return found

/datum/controller/subsystem/ntnet/proc/viewer_token(client/user, site_id)
	if(!user)
		return null
	var/list/entry = user.ntnet_viewer_tokens[site_id]
	if(!entry || world.time > entry["expires"])
		return null
	return entry["token"]

/datum/controller/subsystem/ntnet/proc/request_viewer_token(client/user, site_id, character_name, renew = FALSE)
	if(!user || !is_enabled() || !CONFIG_GET(flag/ntnet_interactive) || !istext(site_id) || !sites[site_id])
		return
	var/list/entry = user.ntnet_viewer_tokens[site_id]
	if(renew && entry)
		entry["expires"] = 0
	if(viewer_token(user, site_id))
		answer_viewer(entry)
		return
	if(entry && entry["pending"])
		return
	if(entry && world.time < entry["retry"])
		if(!entry["error"])
			entry["error"] = "Слишком частые запросы к базе сайта. Попробуйте ещё раз."
		answer_viewer(entry)
		return
	if(!entry && length(user.ntnet_viewer_tokens) >= NTNET_VIEWER_MAX_TOKENS)
		user.ntnet_viewer_tokens.Cut(1, 2)
	entry = list("retry" = world.time + NTNET_VIEWER_TOKEN_COOLDOWN)
	user.ntnet_viewer_tokens[site_id] = entry
	if(IsGuestKey(user.key))
		entry["error"] = "Для базы сайта нужен BYOND-аккаунт."
		answer_viewer(entry)
		return
	var/body = json_encode(list("ckey" = user.ckey, "site_id" = site_id, "name" = copytext_char(character_name, 1, NTNET_VIEWER_MAX_NAME + 1)))
	if(!request(RUSTG_HTTP_METHOD_POST, api_url("viewer-token"), body, CALLBACK(src, PROC_REF(on_viewer_token), user.ckey, site_id)))
		entry["error"] = "NTnet занят. Попробуйте ещё раз."
		answer_viewer(entry)
		return
	entry["pending"] = TRUE

/datum/controller/subsystem/ntnet/proc/answer_viewer(list/entry)
	entry["answer"] = ++viewer_answers

/datum/controller/subsystem/ntnet/proc/on_viewer_token(user_ckey, site_id, list/response)
	var/client/user = GLOB.directory[user_ckey]
	if(!user)
		return
	var/list/entry = user.ntnet_viewer_tokens[site_id]
	if(!entry || !entry["pending"])
		return
	entry["pending"] = FALSE
	answer_viewer(entry)
	var/token = viewer_token_value(response)
	if(!token)
		entry["error"] = "Не удалось получить доступ к базе сайта."
		return
	entry -= "error"
	entry["token"] = token
	entry["expires"] = world.time + NTNET_VIEWER_TOKEN_TTL - NTNET_VIEWER_TOKEN_MARGIN

/datum/controller/subsystem/ntnet/proc/viewer_token_value(list/response)
	if(!islist(response) || response["status_code"] != 201 || length(response["body"]) > NTNET_MAX_LOGIN_BYTES)
		return
	var/list/document = decode_json(response["body"])
	if(!islist(document) || !istext(document["token"]) || length(document["token"]) > NTNET_VIEWER_MAX_TOKEN_LENGTH)
		return
	if(document["expires_in"] != NTNET_VIEWER_TOKEN_TTL / (1 SECONDS))
		return
	var/static/regex/pattern = regex(@"^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$")
	return pattern.Find(document["token"]) ? document["token"] : null

/datum/controller/subsystem/ntnet/proc/request_login(client/user)
	if(!user || !is_enabled() || user.ntnet_login_pending || world.time < user.ntnet_login_retry)
		return
	if(IsGuestKey(user.key))
		user.ntnet_login_error = "Для входа нужен BYOND-аккаунт."
		return
	user.ntnet_code = null
	user.ntnet_code_expires = 0
	user.ntnet_login_error = null
	user.ntnet_login_request++
	var/body = json_encode(list("ckey" = user.ckey))
	var/datum/callback/answer = CALLBACK(src, PROC_REF(on_login), user.ckey, user.ntnet_login_request)
	if(!request(RUSTG_HTTP_METHOD_POST, api_url("device/new"), body, answer))
		user.ntnet_login_error = "NTnet занят. Попробуйте ещё раз."
		return
	user.ntnet_login_pending = TRUE
	user.ntnet_login_retry = world.time + NTNET_LOGIN_COOLDOWN

/datum/controller/subsystem/ntnet/proc/on_login(user_ckey, request_id, list/response)
	var/client/user = GLOB.directory[user_ckey]
	if(!user || !user.ntnet_login_pending || user.ntnet_login_request != request_id)
		return
	user.ntnet_login_pending = FALSE
	user.ntnet_login_error = "Не удалось получить код. Попробуйте снова через минуту."
	var/code = login_code(response)
	if(!code)
		return
	user.ntnet_code = code
	user.ntnet_code_expires = world.time + NTNET_CODE_LIFETIME - NTNET_REQUEST_TIMEOUT
	user.ntnet_login_error = null
	var/editor = html_encode(CONFIG_GET(string/ntnet_editor_url))
	to_chat(user, span_notice("NTnet: ваш одноразовый код — [user.ntnet_code]. Действует до 15 минут. <a href='[editor]'>Открыть редактор</a>. Не передавайте код другим игрокам."))

/datum/controller/subsystem/ntnet/proc/login_code(list/response)
	if(!islist(response) || response["status_code"] != 201 || length(response["body"]) > NTNET_MAX_LOGIN_BYTES)
		return
	var/list/document = decode_json(response["body"])
	if(!islist(document) || !istext(document["code"]) || length(document["code"]) != 14)
		return
	if(document["expires_in"] != NTNET_CODE_LIFETIME / (1 SECONDS))
		return
	var/static/regex/pattern = regex(@"^[23456789ABCDEFGHJKLMNPQRSTUVWXYZ]{4}-[23456789ABCDEFGHJKLMNPQRSTUVWXYZ]{4}-[23456789ABCDEFGHJKLMNPQRSTUVWXYZ]{4}$")
	return pattern.Find(document["code"]) ? document["code"] : null

#undef NTNET_REFRESH_INTERVAL
#undef NTNET_RETRY_INTERVAL
#undef NTNET_STALE_PAGE_RETRY
#undef NTNET_IDLE_TIMEOUT
#undef NTNET_REQUEST_TIMEOUT
#undef NTNET_LOGIN_COOLDOWN
#undef NTNET_CODE_LIFETIME
#undef NTNET_MAX_INDEX_BYTES
#undef NTNET_MAX_PAGE_BYTES
#undef NTNET_MAX_SEARCH_BYTES
#undef NTNET_MAX_LOGIN_BYTES
#undef NTNET_MAX_SITES
#undef NTNET_MAX_PAGES
#undef NTNET_CACHE_PAGES
#undef NTNET_MAX_REQUESTS
#undef NTNET_MAX_FRAME_URL
#undef NTNET_MAX_TEXT
#undef NTNET_MAX_TREE_DEPTH
#undef NTNET_SEARCH_MAX_RESULTS
#undef NTNET_SEARCH_MAX_SNIPPET
#undef NTNET_VIEWER_TOKEN_TTL
#undef NTNET_VIEWER_TOKEN_MARGIN
#undef NTNET_VIEWER_TOKEN_COOLDOWN
#undef NTNET_VIEWER_MAX_TOKENS
#undef NTNET_VIEWER_MAX_TOKEN_LENGTH
#undef NTNET_VIEWER_MAX_NAME
