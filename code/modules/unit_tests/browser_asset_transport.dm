/datum/unit_test/browser_asset_transport/Run()
	var/datum/asset/simple/jquery/jquery_assets = get_asset_datum(/datum/asset/simple/jquery)
	TEST_ASSERT(!jquery_assets.legacy, "jQuery must use the configured asset transport")

	var/datum/asset/simple/namespaced/bluemoon_tooltip/tooltip_assets = get_asset_datum(/datum/asset/simple/namespaced/bluemoon_tooltip)
	var/list/tooltip_urls = tooltip_assets.get_url_mappings()
	TEST_ASSERT(length(tooltip_urls["tooltip.html"]), "tooltip HTML must have a transport URL")
	TEST_ASSERT(length(tooltip_urls["tooltip-jquery.min.js"]), "tooltip jQuery must have a transport URL")
	TEST_ASSERT(length(tooltip_urls["tooltip-SpaceMono.ttf"]), "tooltip font must have a transport URL")

	var/datum/asset/group/irv/irv_assets = get_asset_datum(/datum/asset/group/irv)
	var/list/irv_urls = irv_assets.get_url_mappings()
	TEST_ASSERT(length(irv_urls["jquery.min.js"]), "IRV jQuery must have a transport URL")
	TEST_ASSERT(length(irv_urls["jquery-ui.custom-core-widgit-mouse-sortable-min.js"]), "IRV sortable script must have a transport URL")

	var/datum/asset/simple/namespaced/bluemoon_statbrowser/statbrowser_assets = get_asset_datum(/datum/asset/simple/namespaced/bluemoon_statbrowser)
	var/list/statbrowser_urls = statbrowser_assets.get_url_mappings()
	TEST_ASSERT(length(statbrowser_urls["statbrowser.html"]), "statbrowser HTML must have a transport URL")
