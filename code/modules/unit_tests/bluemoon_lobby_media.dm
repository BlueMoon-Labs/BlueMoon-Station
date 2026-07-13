/datum/unit_test/bluemoon_lobby_media/Run()
	TEST_ASSERT_EQUAL(bm_normalize_lobby_media_path("./config\\title_screens\\lobby.gif"), \
		"config/title_screens/lobby.gif", "media paths must use stable manifest keys")
	TEST_ASSERT_NULL(bm_normalize_lobby_media_path('icons/runtime/default_title.dmi'), \
		"compiled resources must use the local fallback")

	var/list/original_urls = SStitle_bm.external_media_urls
	SStitle_bm.external_media_urls = list(
		"config/title_screens/lobby.gif" = "http://cdn.example.test/lobby.gif",
	)
	var/resolved_url = SStitle_bm.get_external_media_url(".\\config\\title_screens\\lobby.gif")
	var/missing_url = SStitle_bm.get_external_media_url("config/title_screens/missing.gif")
	SStitle_bm.external_media_urls = original_urls
	TEST_ASSERT_EQUAL(resolved_url, "http://cdn.example.test/lobby.gif", "known media must resolve to HTTP")
	TEST_ASSERT_NULL(missing_url, "unknown media must retain the local fallback")

	var/list/images = list()
	SStitle_bm._load_images_from_dir("config/title_screens/", images)
	TEST_ASSERT(length(images), "the SFW title image pool must not be empty")
	for(var/image_path in images)
		TEST_ASSERT(istext(image_path), "title pools must keep lazy paths instead of dynamic RSC refs")
		TEST_ASSERT(fexists(image_path), "lazy title image path must exist: [image_path]")
