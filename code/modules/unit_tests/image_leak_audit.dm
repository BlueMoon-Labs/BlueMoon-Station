// BLUEMOON DIAGNOSTIC — confirms suspected client.images leak patterns via static AST inspection.
//
// Why these are diagnostic (not regression) tests:
// - /client is a BYOND builtin and cannot be mocked. mob.client is null in unit tests,
//   so the real `M.client.images += X` code path is a no-op at test time.
// - We cannot observe the leak at runtime without a live game session.
// - But the *code shape* that causes the leak is observable in source: we read the
//   relevant proc bodies and check whether they contain the cleanup / cache-the-client
//   patterns required to NOT leak.
//
// Each test FAILS on current code, with a message identifying the bug. Once the
// corresponding fix lands, the test should be inverted (remove "!") so it acts as
// a regression guard going forward.
//
// Gated under IMAGE_LEAK_AUDIT so it doesn't break regular CI. Run via:
//   node tools/build/build.js -D IMAGE_LEAK_AUDIT dm-test

#ifdef IMAGE_LEAK_AUDIT

/// Extracts the body of a single top-level proc declaration from a DM source file.
/// The proc body ends at the first line that begins a new top-level declaration
/// (any line starting with "/" or "#" with no leading indentation).
/proc/_image_audit_extract_proc(source, proc_signature)
	var/list/lines = splittext(source, "\n")
	var/in_proc = FALSE
	var/list/body = list()
	for(var/line in lines)
		if(in_proc)
			// End-of-proc heuristic: a non-indented line that begins a new decl.
			if(length(line) > 0)
				var/first_char = copytext(line, 1, 2)
				if(first_char == "/" || first_char == "#")
					break
			body += line
			continue
		// Match by substring — proc_signature is a literal like
		// "/datum/component/field_of_vision/proc/on_mob_logout"
		if(findtext(line, proc_signature))
			in_proc = TRUE
	return body.Join("\n")


/datum/unit_test/fov_logout_image_leak/Run()
	var/source = file2text('code/datums/components/field_of_vision.dm')
	var/body = _image_audit_extract_proc(source, "/datum/component/field_of_vision/proc/on_mob_logout")
	if(!body)
		TEST_FAIL("could not locate field_of_vision/proc/on_mob_logout in source — refactor moved it?")
		return
	// generate_fov_holder pushes 4 images (shadow_mask, visual_shadow, owner_mask, adj_mask)
	// into client.images. On logout, these must be removed; otherwise they stay attached
	// to the old client, and every mob-switch / re-login adds another 4 orphan images.
	// The proper cleanup pattern is present in UnregisterFromParent — but on_mob_logout
	// only does UnregisterSignal calls and never touches client.images.
	if(findtext(body, "images -=") || findtext(body, "images.Remove"))
		return // cleanup present — no leak
	TEST_FAIL("CONFIRMED LEAK: field_of_vision/on_mob_logout does not remove its 4 images (shadow_mask, visual_shadow, owner_mask, adj_mask) from client.images. Compare with UnregisterFromParent (which does remove them). Every logout / mob-switch piles 4 more orphan images onto the stale client until BYOND OOMs.")


/datum/unit_test/hallucination_simple_destroy_uses_live_client/Run()
	var/source = file2text('code/modules/flufftext/Hallucination.dm')
	var/body = _image_audit_extract_proc(source, "/obj/effect/hallucination/simple/Destroy")
	if(!body)
		TEST_FAIL("could not locate /obj/effect/hallucination/simple/Destroy in source")
		return
	// The bug: Destroy reads target.client live to remove current_image. If the
	// player logged out / cryo'd / was transferred between Initialize and Destroy,
	// target.client is null (or a different client now) — and current_image is
	// stuck in the previous client.images forever.
	//
	// A safe Destroy would use a `var/client/owner_client` cached at Initialize
	// time (with a signal to clear it if that client itself qdels).
	if(findtext(body, "target?.client.images") || findtext(body, "target.client.images"))
		TEST_FAIL("CONFIRMED LEAK: /obj/effect/hallucination/simple/Destroy reads target.client live. If target.client changed (logout / body-transfer / cryo) between Initialize (line ~117) and Destroy, current_image stays in the previous client.images permanently. The base class needs to cache the client reference at creation and remove from THAT cached client on destroy.")


/datum/unit_test/fake_flood_destroy_uses_live_client/Run()
	var/source = file2text('code/modules/flufftext/Hallucination.dm')
	var/body = _image_audit_extract_proc(source, "/datum/hallucination/fake_flood/Destroy")
	if(!body)
		TEST_FAIL("could not locate fake_flood/Destroy in source")
		return
	// fake_flood is a special case of the simple-hallucination leak: it pushes
	// flood_images (up to 100+ images, one per flooded tile) into client.images.
	// If target.client is null at Destroy time, all of them stay orphaned at once —
	// a single failed cleanup can OOM the previous client by itself.
	if(findtext(body, "target.client.images") && !findtext(body, "owner_client") && !findtext(body, "cached_client"))
		TEST_FAIL("CONFIRMED LEAK: /datum/hallucination/fake_flood/Destroy reads target.client live to remove flood_images. fake_flood holds dozens-to-hundreds of images; one missed cleanup (target logged out before Destroy) orphans the whole batch into the old client.images. Cache the client at creation and reuse on Destroy.")


/datum/unit_test/bluemoon_drugs_spawn_uses_live_client/Run()
	var/source = file2text('modular_bluemoon/code/game/objects/items/drugs.dm')
	// Pattern in zvezdochka and pendosovka on_mob_life:
	//   if(M.client)
	//       M.client.images += trip_img
	//   spawn(rand(30,50))
	//       if(M.client)
	//           M.client.images -= trip_img
	// Bug: the M.client read inside the spawn block can resolve to a DIFFERENT
	// client (or null) by the time it runs. trip_img remains on the original
	// client.images forever.
	var/has_add = findtext(source, "M.client.images += trip_img")
	var/has_remove = findtext(source, "M.client.images -= trip_img")
	var/has_spawn = findtext(source, "spawn(rand(30,50))")
	var/has_cache = findtext(source, "var/client/saved") || findtext(source, "var/client/cached") || findtext(source, "var/client/trip_client")
	if(has_add && has_remove && has_spawn && !has_cache)
		TEST_FAIL("CONFIRMED LEAK: zvezdochka/pendosovka drugs in modular_bluemoon/code/game/objects/items/drugs.dm push trip_img to M.client.images and then read M.client again inside a 3-5 sec spawn block. If M.client changes (logout / transfer) in that window, trip_img is orphaned on the previous client. Active drug metabolism fires this loop ~10x per pill — leak scales with usage.")


/datum/unit_test/cult_blood_target_image_recipients_untracked/Run()
	var/source = file2text('code/modules/antagonists/cult/cult_comms.dm')
	var/body = _image_audit_extract_proc(source, "/proc/reset_blood_target")
	if(!body)
		TEST_FAIL("could not locate /proc/reset_blood_target in source")
		return
	// blood_target_image is pushed to the .images of every cultist's CURRENT client
	// when the team marks a target. reset_blood_target removes it by iterating
	// team.members — but a cultist who disconnected (or whose body was transferred
	// to a non-cultist mob) is no longer in team.members in the way we'd want,
	// and the stale ref stays in their old client.images.
	//
	// A safe design tracks the actual list of clients/keys that received the image,
	// independent of current team membership.
	var/iterates_members = findtext(body, "team.members")
	var/tracks_recipients = findtext(body, "image_recipients") || findtext(body, "blood_target_recipients") || findtext(body, "client_recipients")
	if(iterates_members && !tracks_recipients)
		TEST_FAIL("CONFIRMED LEAK (suspected): reset_blood_target iterates only current team.members to remove blood_target_image. Cultists who disconnected or transferred bodies are not in that iteration, and their old client.images keep a reference to the image. A separate recipients list (populated wherever the image is pushed) would close this.")


#endif
