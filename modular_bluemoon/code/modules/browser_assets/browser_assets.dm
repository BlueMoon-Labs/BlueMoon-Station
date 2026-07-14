/datum/asset/simple/namespaced/bluemoon_statbrowser
	parents = list(
		"statbrowser.html" = 'html/statbrowser.html',
	)

/datum/asset/simple/namespaced/bluemoon_tooltip
	assets = list(
		"tooltip-jquery.min.js" = 'html/jquery/jquery.min.js',
		"tooltip-SpaceMono.ttf" = 'interface/fonts/SpaceMono.ttf',
	)
	parents = list(
		"tooltip.html" = 'code/modules/tooltip/tooltip.html',
	)

/client/proc/load_bluemoon_statbrowser()
	var/datum/asset/simple/namespaced/bluemoon_statbrowser/statbrowser_assets = get_asset_datum(/datum/asset/simple/namespaced/bluemoon_statbrowser)
	statbrowser_assets.send(src)
	src << browse(statbrowser_assets.get_htmlloader("statbrowser.html"), "window=statbrowser")
