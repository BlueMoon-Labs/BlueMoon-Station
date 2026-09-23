/datum/unit_test/ntnet_responses
	var/list/saved_state
	var/saved_host

/datum/unit_test/ntnet_responses/Destroy()
	for(var/var_name in saved_state)
		SSntnet.vars[var_name] = saved_state[var_name]
	saved_state = null
	CONFIG_SET(string/ntnet_sandbox_host, saved_host)
	return ..()

/datum/unit_test/ntnet_responses/Run()
	var/datum/controller/subsystem/ntnet/network = SSntnet
	saved_state = list()
	for(var/var_name in list("sites", "catalog", "pages", "page_retry", "pending", "available", "index_pending", "next_refresh"))
		saved_state[var_name] = network.vars[var_name]
	saved_host = CONFIG_GET(string/ntnet_sandbox_host)
	CONFIG_SET(string/ntnet_sandbox_host, "sandbox.wiki-ss13.space")
	network.sites = list()
	network.catalog = list()
	network.pages = list()
	network.page_retry = list()
	network.pending = list()

	var/list/site = list("id" = "test", "domain" = "test.bm", "title" = "Test", "version" = "1", "pages" = list(list("slug" = "index", "title" = "Index")))
	network.on_index(list("status_code" = 200, "body" = json_encode(list("sites" = list(site)))))
	TEST_ASSERT(network.available, "Valid catalog was rejected")
	TEST_ASSERT(network.has_page("test", "index"), "Catalog page is missing")
	TEST_ASSERT(!network.has_page("test", "../secret"), "Unlisted page was accepted")
	TEST_ASSERT(!network.has_page(list("test"), "index"), "Malformed site ID was accepted")

	network.on_index(list("status_code" = 200, "body" = json_encode(list("sites" = list(list("id" = "broken"))))))
	TEST_ASSERT(!(network.available), "Malformed catalog was accepted")
	network.on_index(list("status_code" = 200, "body" = json_encode(list("sites" = list(site)))))

	var/cache_key = json_encode(list("test", "index"))
	var/list/document = list("site_id" = "test", "slug" = "index", "version" = "1", "tree" = list("type" = "text", "text" = "hello"))
	network.on_page("test", "index", list("status_code" = 200, "body" = json_encode(document)))
	var/list/cached_page = network.pages[cache_key]
	TEST_ASSERT_NOTNULL(cached_page, "Valid page was not cached")
	TEST_ASSERT_NULL(cached_page["frame"], "Missing interactive field was invented")
	TEST_ASSERT_EQUAL(cached_page["text"], "hello", "Fallback text was not collected")

	var/address = "https://sandbox.wiki-ss13.space/i/0123456789abcdef0123456789abcdef/index"
	document["interactive"] = list("url" = address)
	network.pages -= cache_key
	network.page_retry -= cache_key
	network.on_page("test", "index", list("status_code" = 200, "body" = json_encode(document)))
	cached_page = network.pages[cache_key]
	TEST_ASSERT_EQUAL(cached_page["frame"], address, "Sandbox address was not kept")

	document["interactive"] = list("url" = "https://evil.example/i/0123456789abcdef0123456789abcdef/index")
	network.pages -= cache_key
	network.page_retry -= cache_key
	network.on_page("test", "index", list("status_code" = 200, "body" = json_encode(document)))
	cached_page = network.pages[cache_key]
	TEST_ASSERT_NULL(cached_page["frame"], "Foreign frame address was accepted")

	network.pages -= cache_key
	network.page_retry -= cache_key
	document["version"] = "0"
	network.on_page("test", "index", list("status_code" = 200, "body" = json_encode(document)))
	TEST_ASSERT_NULL(network.pages[cache_key], "Stale page was cached")
	TEST_ASSERT(!network.page_failed("test", "index"), "Stale page blocked an immediate retry")
	document["version"] = "junk"
	network.on_page("test", "index", list("status_code" = 200, "body" = json_encode(document)))
	TEST_ASSERT(network.page_failed("test", "index"), "Junk version was not treated as a broken response")
	network.page_retry -= cache_key
	network.next_refresh = INFINITY
	document["version"] = "2"
	network.on_page("test", "index", list("status_code" = 200, "body" = json_encode(document)))
	TEST_ASSERT_NOTNULL(network.pages[cache_key], "Page saved after the catalog refresh was rejected")
	TEST_ASSERT_EQUAL(network.next_refresh, 0, "Newer page did not schedule a catalog refresh")
	network.pages -= cache_key
	network.on_page("test", "index", list("status_code" = 404, "body" = ""))
	TEST_ASSERT(network.available, "Missing page took the whole network offline")
	TEST_ASSERT(network.page_failed("test", "index"), "Missing page was not reported as failed")
	network.on_page("test", "index", null)
	TEST_ASSERT(!(network.available), "Lost connection was not reported")

	TEST_ASSERT_EQUAL(network.viewer_token_value(list("status_code" = 201, "body" = json_encode(list("token" = "eyJzIjoiYSJ9.c2ln_-", "expires_in" = 3600)))), "eyJzIjoiYSJ9.c2ln_-", "Valid viewer token was rejected")
	for(var/bad_body in list("oops", json_encode(list("token" = "a.b", "expires_in" = 60)), json_encode(list("token" = "a.b.c", "expires_in" = 3600)), json_encode(list("token" = "a'.b", "expires_in" = 3600))))
		TEST_ASSERT_NULL(network.viewer_token_value(list("status_code" = 201, "body" = bad_body)), "Malformed viewer token was accepted")

	for(var/bad_address in list("byond://?src=admin", "javascript:alert(1)", "http://sandbox.wiki-ss13.space/i/0123456789abcdef0123456789abcdef/index"))
		TEST_ASSERT(!(network.frame_address(bad_address)), "Junk frame address [bad_address] was accepted")

	TEST_ASSERT(network.media_address("https://media.wiki-ss13.space/0123456789abcdef0123456789abcdef/0123456789abcdef.png"), "Media address was rejected")
	TEST_ASSERT(!(network.media_address("https://media.wiki-ss13.space/0123456789abcdef0123456789abcdef/0123456789abcdef.svg")), "Svg icon was accepted")
	TEST_ASSERT(!(network.media_address("javascript:alert(1)")), "Junk icon was accepted")

	var/list/results = list(
		list("site_id" = "test", "slug" = "index", "title" = "Index", "snippet" = "hello"),
		list("site_id" = "test", "slug" = "missing", "title" = "Missing", "snippet" = "hello"),
		list("site_id" = "test", "slug" = "index"),
	)
	var/list/found = network.search_results(list("status_code" = 200, "body" = json_encode(list("results" = results))))
	TEST_ASSERT_EQUAL(length(found), 1, "Search results were not filtered against the catalog")
	TEST_ASSERT_NULL(network.search_results(list("status_code" = 500, "body" = "")), "Failed search was treated as a result")

	TEST_ASSERT_EQUAL(network.login_code(list("status_code" = 201, "body" = json_encode(list("code" = "2345-6789-ABCD", "expires_in" = 900)))), "2345-6789-ABCD", "Valid login code was rejected")
	TEST_ASSERT_NULL(network.login_code(list("status_code" = 201, "body" = json_encode(list("code" = "2345-6789-ABCD", "expires_in" = 60)))), "Login code with a foreign lifetime was accepted")
	TEST_ASSERT_NULL(network.login_code(list("status_code" = 201, "body" = json_encode(list("code" = "oops", "expires_in" = 900)))), "Malformed login code was accepted")
