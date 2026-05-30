/datum/unit_test/tgui_dev_asset_url/Run()
	// Пустой dev-ip: url не меняется.
	TEST_ASSERT_EQUAL(tgui_resolve_asset_url("tgui.bundle.js", "tgui.bundle.js", ""), \
		"tgui.bundle.js", "пустой dev ip не должен переписывать url")
	// dev-ip задан: бандл уходит на dev-сервер.
	TEST_ASSERT_EQUAL(tgui_resolve_asset_url("tgui.bundle.js", "tgui.bundle.js", "127.0.0.1"), \
		"http://127.0.0.1:3000/tgui.bundle.js", "бандл должен грузиться с dev-сервера")
	// css-бандл панели тоже переписывается.
	TEST_ASSERT_EQUAL(tgui_resolve_asset_url("tgui-panel.bundle.css", "tgui-panel.bundle.css", "127.0.0.1"), \
		"http://127.0.0.1:3000/tgui-panel.bundle.css", "css-бандл панели должен идти на dev-сервер")
	// Прочие ассеты не трогаем даже при заданном dev-ip.
	TEST_ASSERT_EQUAL(tgui_resolve_asset_url("chat.png", "asset.abc123.png", "127.0.0.1"), \
		"asset.abc123.png", "не-бандл ассеты переписывать нельзя")
