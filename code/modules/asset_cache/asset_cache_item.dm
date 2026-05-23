/**
 * # asset_cache_item
 *
 * An internal datum containing info on items in the asset cache. Mainly used to cache md5 info for speed.
 */
/datum/asset_cache_item
	/// the name of this asset item, becomes the key in SSassets.cache list
	var/name
	/// md5() of the file this asset item represents.
	var/hash
	/// the file this asset represents
	var/resource
	/// our file extension e.g. .png, .gif, etc
	var/ext = ""
	/// Should this file also be sent via the legacy browse_rsc system
	/// when cdn transports are enabled?
	var/legacy = FALSE
	/// Used by the cdn system to keep legacy css assets with their parent
	/// css file. (css files resolve urls relative to the css file, so the
	/// legacy system can't be used if the css file itself could go out over
	/// the cdn)
	var/namespace = null
	/// True if this is the parent css or html file for an asset's namespace
	var/namespace_parent = FALSE
	/// TRUE for keeping local asset names when browse_rsc backend is used
	var/keep_local_name = FALSE

/// Pass in a valid file_hash if you have one to skip rehashing the file.
/// Pass in a valid dmi file path string e.g. "icons/path/to/dmi_file.dmi" to use the
/// cheap md5(rsc_ref) path instead of the expensive md5asfile() workaround.
/datum/asset_cache_item/New(name, file, file_hash, dmi_file_path)
	if (!isfile(file))
		file = fcopy_rsc(file)

	hash = file_hash

	if(!hash)
		// Icons compiled in from a dmi file path are stable in the rsc and md5 their
		// rsc reference correctly. /icon datums generated at runtime do not — they
		// need the md5asfile() workaround for http://www.byond.com/forum/post/2611357
		if(dmi_file_path)
			hash = md5(file)
		else
			hash = md5asfile(file)

	if (!hash)
		CRASH("invalid asset sent to asset cache")
	src.name = name
	var/extstart = findlasttext(name, ".")
	if (extstart)
		ext = ".[copytext(name, extstart+1)]"
	resource = file

/datum/asset_cache_item/vv_edit_var(var_name, var_value)
	return FALSE

/datum/asset_cache_item/CanProcCall(procname)
	return FALSE
