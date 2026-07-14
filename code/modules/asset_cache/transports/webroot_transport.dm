/// CDN Webroot asset transport. 
/datum/asset_transport/webroot
	name = "CDN Webroot asset transport"
	var/asset_manifest_path
	var/asset_manifest_failed = FALSE

/datum/asset_transport/webroot/Load()
	if (validate_config(log = FALSE))
		initialize_asset_manifest()
		load_existing_assets()

/// Opens the cumulative inventory for this exact DMB. Do not truncate it:
/// multiple DreamDaemons may run the same deployment, and retaining their union
/// is safer than racing two startup rewrites.
/datum/asset_transport/webroot/proc/initialize_asset_manifest()
	var/manifest_name = DEPLOYMENT_ASSET_MANIFEST_NAME
	if (!manifest_name)
		return
	asset_manifest_path = "[CONFIG_GET(string/asset_cdn_webroot)].manifests/[manifest_name]"
	var/write_error = rustg_file_append("# browser asset inventory v1\n", asset_manifest_path)
	if (write_error)
		log_asset("WARNING: [type]: Could not initialize browser asset inventory [asset_manifest_path]: [write_error]")
		asset_manifest_path = null

/// Records both newly copied and already present assets. Duplicate entries are
/// harmless and avoid keeping a large in-memory set during initialization.
/datum/asset_transport/webroot/proc/record_asset_path(relative_path)
	if (!asset_manifest_path || asset_manifest_failed)
		return
	var/write_error = rustg_file_append("[relative_path]\n", asset_manifest_path)
	if (write_error)
		asset_manifest_failed = TRUE
		log_asset("WARNING: [type]: Could not update browser asset inventory [asset_manifest_path]: [write_error]")

/// A write can fail after the startup probe (filesystem full, mount lost,
/// permissions changed). Stop issuing CDN URLs and use browse_rsc immediately.
/datum/asset_transport/webroot/proc/fallback_to_simple_transport(failed_path)
	log_asset("ERROR: [type]: Could not publish browser asset [failed_path]. Falling back to simple transport.")
	if (SSassets.transport != src)
		return
	var/datum/asset_transport/simple_transport = new
	SSassets.transport = simple_transport
	simple_transport.Initialize(SSassets.cache)

/// Processes thru any assets that were registered before we were loaded as a transport.
/datum/asset_transport/webroot/proc/load_existing_assets()
	for (var/asset_name in SSassets.cache)
		if (SSassets.transport != src)
			return
		var/datum/asset_cache_item/ACI = SSassets.cache[asset_name]
		save_asset_to_webroot(ACI)

/// Register a browser asset with the asset cache system
/// We also save it to the CDN webroot at this step instead of waiting for send_assets()
/// asset_name - the identifier of the asset
/// asset - the actual asset file or an asset_cache_item datum.
/datum/asset_transport/webroot/register_asset(asset_name, asset, file_hash, dmi_file_path)
	. = ..()
	var/datum/asset_cache_item/ACI = .

	if (istype(ACI) && ACI.hash)
		save_asset_to_webroot(ACI)

/// Saves the asset to the webroot taking into account namespaces and hashes.
/datum/asset_transport/webroot/proc/save_asset_to_webroot(datum/asset_cache_item/ACI)
	var/webroot = CONFIG_GET(string/asset_cdn_webroot)
	var/relative_path = get_asset_suffex(ACI)
	var/newpath = "[webroot][relative_path]"
	if (fexists(newpath))
		record_asset_path(relative_path)
		return TRUE
	if (fexists("[newpath].gz")) //its a common pattern in webhosting to save gzip'ed versions of text files and let the webserver serve them up as gzip compressed normal files, sometimes without keeping the original version.
		record_asset_path(relative_path)
		return TRUE
	if (!fcopy(ACI.resource, newpath))
		fallback_to_simple_transport(newpath)
		return FALSE
	record_asset_path(relative_path)
	return TRUE

/// Returns a url for a given asset.
/// asset_name - Name of the asset.
/// asset_cache_item - asset cache item datum for the asset, optional, overrides asset_name
/datum/asset_transport/webroot/get_asset_url(asset_name, datum/asset_cache_item/asset_cache_item)
	if (!istype(asset_cache_item))
		asset_cache_item = SSassets.cache[asset_name]
	var/url = CONFIG_GET(string/asset_cdn_url) //config loading will handle making sure this ends in a /
	return "[url][get_asset_suffex(asset_cache_item)]"

/datum/asset_transport/webroot/proc/get_asset_suffex(datum/asset_cache_item/asset_cache_item)
	var/base = "[copytext(asset_cache_item.hash, 1, 3)]/"
	var/filename = "asset.[asset_cache_item.hash][asset_cache_item.ext]"
	if (length(asset_cache_item.namespace))
		base = "namespaces/[copytext(asset_cache_item.namespace, 1, 3)]/[asset_cache_item.namespace]/"
		if (!asset_cache_item.namespace_parent)
			filename = "[asset_cache_item.name]"
	return base + filename


/// webroot asset sending - does nothing unless passed legacy assets
/datum/asset_transport/webroot/send_assets(client/client, list/asset_list)
	. = FALSE
	var/list/legacy_assets = list()
	if (!islist(asset_list))
		asset_list = list(asset_list)
	for (var/asset_name in asset_list)
		var/datum/asset_cache_item/ACI = asset_list[asset_name] 
		if (!istype(ACI))
			ACI = SSassets.cache[asset_name]
		if (!ACI)
			legacy_assets += asset_name //pass it on to base send_assets so it can output an error
			continue
		if (ACI.legacy)
			legacy_assets[asset_name] = ACI
	if (length(legacy_assets))
		. = ..(client, legacy_assets)
	

/// webroot slow asset sending - does nothing.
/datum/asset_transport/webroot/send_assets_slow(client/client, list/files, filerate)
	return FALSE

/datum/asset_transport/webroot/validate_config(log = TRUE)
	if (!CONFIG_GET(string/asset_cdn_url))
		if (log)
			log_asset("ERROR: [type]: Invalid Config: ASSET_CDN_URL")
		return FALSE
	var/webroot = CONFIG_GET(string/asset_cdn_webroot)
	if (!webroot)
		if (log)
			log_asset("ERROR: [type]: Invalid Config: ASSET_CDN_WEBROOT")
		return FALSE
	// The deploy hook normally runs as the same service account as DreamDaemon,
	// but validate that assumption in the process which will actually write the
	// assets. Otherwise fcopy() failures leave clients with valid-looking CDN
	// URLs that do not exist on disk.
	var/probe_path = "[webroot].byond-write-test-[world.realtime]-[rand(100000, 999999)]"
	var/write_error = rustg_file_write("asset webroot write test", probe_path)
	if (write_error)
		if (log)
			log_asset("ERROR: [type]: ASSET_CDN_WEBROOT is not writable: [webroot] ([write_error]). Falling back to simple transport.")
		return FALSE
	if (!fdel(probe_path) && log)
		log_asset("WARNING: [type]: Could not remove ASSET_CDN_WEBROOT write probe: [probe_path]")
	return TRUE
