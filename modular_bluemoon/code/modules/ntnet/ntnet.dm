#define NTNET_REFRESH_INTERVAL (5 MINUTES)
#define NTNET_RETRY_INTERVAL (30 SECONDS)
#define NTNET_IDLE_TIMEOUT (15 MINUTES)
#define NTNET_REQUEST_TIMEOUT (20 SECONDS)
#define NTNET_LOGIN_COOLDOWN (1 MINUTES)
#define NTNET_CODE_LIFETIME (15 MINUTES)
#define NTNET_MAX_INDEX_BYTES (512 * 1024)
#define NTNET_MAX_PAGE_BYTES (64 * 1024)
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

SUBSYSTEM_DEF(ntnet)
	name = "NTnet"
	wait = 1
	flags = SS_NO_INIT | SS_BACKGROUND | SS_TICKER
	runlevels = RUNLEVEL_LOBBY | RUNLEVELS_DEFAULT

	var/list/sites = list()
	var/list/catalog = list()
	var/list/pages = list()
	var/list/page_retry = list()
	var/list/pending = list()
	var/list/requests = list()
	var/list/deadlines = list()
	var/available = FALSE
	var/index_pending = FALSE
	var/next_refresh = 0
	var/last_used = -INFINITY
	var/generation = 0

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
		if(!istext(site["domain"]) || !istext(site["title"]) || !istext(site["version"]) || !islist(site["pages"]))
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
		if(!site || site["version"] != cached["version"])
			pages -= cache_key
	page_retry.Cut()
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
	if(pages[cache_key] || pending[cache_key] || world.time < page_retry[cache_key])
		return
	var/list/site = sites[site_id]
	var/url = api_url("sites/[url_encode(site_id)]/pages/[url_encode(slug)]")
	if(!request(RUSTG_HTTP_METHOD_GET, url, "", CALLBACK(src, PROC_REF(on_page), site_id, slug, site["version"])))
		return
	pending[cache_key] = TRUE

/datum/controller/subsystem/ntnet/proc/on_page(site_id, slug, version, list/response)
	var/cache_key = json_encode(list(site_id, slug))
	pending -= cache_key
	page_retry[cache_key] = world.time + NTNET_RETRY_INTERVAL
	if(!islist(response) || response["status_code"] != 200 || length(response["body"]) > NTNET_MAX_PAGE_BYTES)
		available = FALSE
		return
	var/list/site = sites[site_id]
	if(!site || site["version"] != version || !has_page(site_id, slug))
		return
	var/list/document = decode_json(response["body"])
	if(!islist(document) || document["site_id"] != site_id || document["slug"] != slug || document["version"] != version)
		available = FALSE
		return
	var/list/frame = document["interactive"]
	var/address = islist(frame) ? frame["url"] : null
	var/list/stored = list(
		"site_id" = site_id,
		"slug" = slug,
		"version" = version,
		"title" = istext(document["title"]) ? document["title"] : slug,
		"frame" = (CONFIG_GET(flag/ntnet_interactive) && frame_address(address)) ? address : null,
		"text" = text_from_tree(document["tree"]),
	)
	if(length(pages) >= NTNET_CACHE_PAGES)
		pages.Cut(1, 2)
	pages[cache_key] = stored
	page_retry -= cache_key
	available = TRUE

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
