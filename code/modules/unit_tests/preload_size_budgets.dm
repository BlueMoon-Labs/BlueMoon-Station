// BLUEMOON: regression guards against bloating the resources we push to every connecting client.
//
// Why these exist: BYOND's browse() queue is single-threaded per client. Anything we push via
// Export("##action=load_rsc", file) or browse_rsc() sits in that queue ahead of the critical UI
// HTML (statbrowser, TGUI windows). If the pre-UI payload grows past a few MB on a slow link,
// the client appears frozen on "Downloading resources" while statbrowser never loads —
// users perceive this as a disconnect and either reconnect or kill BYOND.
//
// See /client/proc/send_resources in client_procs.dm.

/datum/unit_test/vox_preload_size_budget/Run()
#ifdef AI_VOX
	// Current size at time of writing: ~9MB across ~1600 files (sound/vox + sound/vox_fem).
	// Budget set with headroom so the test only fires on a clearly bad regression
	// (e.g. accidental duplication of the catalog, addition of a third full voice set).
	var/budget_mb = 15
	var/budget_bytes = budget_mb * 1024 * 1024
	// Одна точка измерения на тест и на книгу недатумных аллокаций: пока они мерили
	// врозь, колонка ledger_rsc_bytes расходилась с бюджетом впятеро и никто этого
	// не замечал, потому что тест продолжал проходить.
	var/total_bytes = get_vox_preload_bytes()
	var/total_count = 0
	for(var/vox_type in GLOB.vox_types)
		total_count += length(GLOB.vox_types[vox_type])
	if(total_bytes > budget_bytes)
		var/total_mb_rounded = round(total_bytes / 1048576, 0.1)
		TEST_FAIL("VOX preload weighs [total_bytes] bytes (~[total_mb_rounded] MB across [total_count] files) — over the [budget_mb] MB budget. This is shipped to every connecting client by /client/proc/send_resources via Export(\"##action=load_rsc\"); bloating it clogs the browse() queue and stalls logins on \"Downloading resources\". Either trim the VOX catalog or comment out the AI_VOX define in code/__DEFINES/mobs.dm if VOX is no longer used.")
#endif
