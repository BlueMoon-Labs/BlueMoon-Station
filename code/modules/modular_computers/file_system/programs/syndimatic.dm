#define SYNDIMATIC_PAGE_SIZE 12
#define SYNDIMATIC_FEED_BATCH_SIZE 6
#define SYNDIMATIC_COMMENT_PAGE_SIZE 20

/datum/mind/proc/set_syndimatic_character(datum/preferences/prefs, account_key, mob/living/carbon/human/character)
	if(!prefs.path || !account_key)
		return
	var/character_id = prefs.syndimatic_character_id
	if(!character_id)
		// Старые резервные копии могут не успеть получить поле при штатном пересохранении.
		character_id = rustg_hash_string(RUSTG_HASH_SHA256, "syndimatic/[prefs.path]/[prefs.default_slot]")
	syndimatic_profile_id = rustg_hash_string(RUSTG_HASH_SHA256, "[account_key]/[character_id]")
	syndimatic_owner_ckey = account_key
	syndimatic_character_name = character.real_name
	set_syndimatic_notifications(prefs.syndimatic_notifications)
	for(var/portrait in character.dna.headshot_links)
		syndimatic_first_portrait = html_decode(sanitize_headshot_link(html_decode(portrait)))
		if(syndimatic_first_portrait)
			break

/datum/mind/proc/set_syndimatic_notifications(enabled)
	syndimatic_notifications = enabled
	if(enabled)
		SSpersistence.syndimatic_subscribers |= WEAKREF(src)
	else
		SSpersistence?.syndimatic_subscribers?.Remove(weak_reference)

/datum/computer_file/program/syndimatic
	filename = "Syndimatic"
	filedesc = "Syndimatic"
	program_icon = "images"
	category = PROGRAM_CATEGORY_CREW
	extended_desc = "Общая лента фотографий с профилями, отметками «Нравится» и комментариями."
	usage_flags = PROGRAM_PDA
	size = 2
	tgui_id = "NtosSyndimatic"

	var/datum/weakref/viewer_ref
	var/datum/weakref/viewer_ui_ref
	var/viewer_profile_id
	var/profile_id
	var/post_id
	var/list/post_media
	var/gallery_page = 1
	var/comment_page = 0
	var/comment_serial = 0
	var/draft_kind
	var/draft_id
	var/datum/picture/draft_photo
	var/editing_profile = FALSE
	var/viewing_blocks = FALSE
	var/viewing_gallery = FALSE
	var/feed_limit = SYNDIMATIC_FEED_BATCH_SIZE
	var/comment_sort = "oldest"
	var/list/feed_sent_ids

/datum/computer_file/program/syndimatic/Destroy()
	close_syndimatic_window()
	return ..()

/datum/computer_file/program/syndimatic/kill_program(forced = FALSE)
	close_syndimatic_window()
	return ..()

/datum/computer_file/program/syndimatic/ui_interact(mob/user, datum/tgui/ui)
	if(!can_view_syndimatic(user))
		return
	var/datum/tgui/current_ui = viewer_ui_ref?.resolve()
	var/datum/mind/actor = get_syndimatic_actor(user)
	if(current_ui?.user == user && viewer_profile_id == actor?.syndimatic_profile_id)
		if(!current_ui.initialized || SStgui.try_update_ui(user, src, current_ui))
			return
	if(current_ui)
		close_syndimatic_window()
	open_syndimatic_ui(user)

/datum/computer_file/program/syndimatic/ui_status(mob/user, datum/ui_state/state)
	if(!user?.client || viewer_ref?.resolve() != user || computer?.active_program != src || !computer.enabled)
		return UI_CLOSE
	var/datum/mind/actor = get_syndimatic_actor(user)
	if(viewer_profile_id != actor?.syndimatic_profile_id)
		return UI_CLOSE
	return ..()

/datum/computer_file/program/syndimatic/ui_close(mob/user, datum/tgui/ui)
	if(viewer_ui_ref?.resolve() == ui)
		clear_syndimatic_session()
	return ..()

/datum/computer_file/program/syndimatic/proc/can_view_syndimatic(mob/user)
	if(!user?.client || !istype(computer, /obj/item/modular_computer/pda) || !computer.enabled || computer.active_program != src)
		return FALSE
	if(IsAdminGhost(user))
		return TRUE
	if(!isliving(user))
		return FALSE
	var/datum/ui_state/state = ui_state(user)
	return state.can_use_topic(computer, user) == UI_INTERACTIVE

/datum/computer_file/program/syndimatic/proc/get_syndimatic_actor(mob/user)
	var/datum/mind/actor = user?.mind
	if(actor?.syndimatic_profile_id && user.client?.ckey == actor.syndimatic_owner_ckey)
		return actor
	return null

/datum/computer_file/program/syndimatic/proc/open_syndimatic_ui(mob/user)
	viewer_ref = WEAKREF(user)
	var/datum/mind/actor = get_syndimatic_actor(user)
	viewer_profile_id = actor?.syndimatic_profile_id
	var/list/profile = SSpersistence.get_syndimatic_profile(viewer_profile_id)
	if(profile && profile["name"] != actor.syndimatic_character_name)
		var/list/updated_profile = profile.Copy()
		updated_profile["name"] = actor.syndimatic_character_name
		if(SSpersistence.save_syndimatic_profile(viewer_profile_id, updated_profile))
			SSpersistence.notify_syndimatic_viewers(src, profile_id = viewer_profile_id)
	var/datum/tgui/ui = new(user, src, tgui_id, filedesc)
	viewer_ui_ref = WEAKREF(ui)
	RegisterSignal(user, COMSIG_MOB_CLIENT_LOGOUT, PROC_REF(on_syndimatic_logout))
	RegisterSignal(ui, COMSIG_PARENT_QDELETING, PROC_REF(on_syndimatic_ui_deleted))
	SSpersistence.syndimatic_viewers |= WEAKREF(src)
	ui.set_autoupdate(FALSE)
	if(ui.open())
		ui.send_asset(get_asset_datum(/datum/asset/simple/headers))
	else
		qdel(ui)

/datum/computer_file/program/syndimatic/proc/on_syndimatic_logout()
	SIGNAL_HANDLER
	close_syndimatic_window()

/datum/computer_file/program/syndimatic/proc/on_syndimatic_ui_deleted()
	SIGNAL_HANDLER
	clear_syndimatic_session()

/datum/computer_file/program/syndimatic/proc/close_syndimatic_window()
	if(!viewer_ui_ref)
		return
	var/datum/tgui/ui = viewer_ui_ref.resolve()
	clear_syndimatic_session()
	ui?.close()

/datum/computer_file/program/syndimatic/proc/clear_syndimatic_session()
	var/mob/viewer = viewer_ref?.resolve()
	if(viewer)
		UnregisterSignal(viewer, COMSIG_MOB_CLIENT_LOGOUT)
	var/datum/tgui/ui = viewer_ui_ref?.resolve()
	if(ui)
		UnregisterSignal(ui, COMSIG_PARENT_QDELETING)
	SSpersistence.syndimatic_viewers -= WEAKREF(src)
	viewer_ref = null
	viewer_ui_ref = null
	viewer_profile_id = null
	profile_id = null
	post_id = null
	post_media = null
	gallery_page = 1
	comment_page = 0
	comment_serial = 0
	comment_sort = "oldest"
	editing_profile = FALSE
	viewing_blocks = FALSE
	viewing_gallery = FALSE
	feed_limit = SYNDIMATIC_FEED_BATCH_SIZE
	feed_sent_ids = null
	clear_syndimatic_draft()

/datum/computer_file/program/syndimatic/proc/clear_syndimatic_draft()
	draft_kind = null
	draft_id = null
	QDEL_NULL(draft_photo)

/datum/computer_file/program/syndimatic/proc/shows_syndimatic_change(changed_post_id, changed_profile_id)
	if(changed_profile_id)
		// Имена авторов используются также в ленте и комментариях.
		return TRUE
	if(draft_photo || editing_profile)
		return FALSE
	if(!changed_post_id)
		return TRUE
	if(post_id)
		return post_id == changed_post_id
	var/list/post = SSpersistence.syndimatic_posts[changed_post_id]
	return !profile_id || profile_id == post?["author"]

/datum/computer_file/program/syndimatic/ui_static_data(mob/user)
	return list(
		"captionLimit" = PHOTO_CAPTION_LIMIT,
		"descriptionLimit" = PHOTO_DESCRIPTION_LIMIT,
	)

/datum/computer_file/program/syndimatic/ui_data(mob/user)
	var/list/data = get_header_data()
	var/datum/mind/actor = get_syndimatic_actor(user)
	var/is_admin = check_rights_for(user?.client, R_ADMIN)
	add_syndimatic_profile_status(data)
	data["isAdmin"] = !!is_admin
	data["canSetNotifications"] = !!actor
	data["notifications"] = !!actor?.syndimatic_notifications
	data["view"] = viewing_gallery ? "gallery" : "feed"
	if(viewing_blocks && is_admin)
		var/list/rows = list()
		for(var/id in SSpersistence.syndimatic_blocks)
			var/list/profile = SSpersistence.get_syndimatic_profile(id)
			if(profile)
				rows += list(list("id" = id, "name" = profile["name"]))
		data["view"] = "blocks"
		data["blocks"] = rows
		return data
	if(draft_photo)
		data["view"] = draft_kind
		data["draftId"] = draft_id
		data["media"] = draft_photo.photo_ui_media()
		return data
	if(post_id)
		var/list/post = SSpersistence.get_visible_syndimatic_post(post_id)
		if(post)
			data["view"] = "post"
			data["post"] = syndimatic_post_summary(post_id, post, include_avatar = TRUE)
			data["ownPost"] = viewer_profile_id == post["author"]
			data["commentsDisabled"] = !!post["comments_disabled"]
			data["media"] = post_media
			var/list/likes = post["likes"]
			data["liked"] = viewer_profile_id && !!likes[viewer_profile_id]
			data["commentsOpen"] = comment_page > 0
			if(comment_page)
				var/list/comments = post["comments"]
				if(comment_sort == "popular" && length(comments) > 1)
					comments = SSpersistence.get_syndimatic_ranked_comments(post_id, comments)
				var/pages = max(1, CEILING(length(comments) / SYNDIMATIC_COMMENT_PAGE_SIZE, 1))
				comment_page = clamp(comment_page, 1, pages)
				var/start = (comment_page - 1) * SYNDIMATIC_COMMENT_PAGE_SIZE + 1
				var/list/rows = list()
				for(var/index = start to min(start + SYNDIMATIC_COMMENT_PAGE_SIZE - 1, length(comments)))
					var/list/comment = comments[comment_sort == "oldest" ? length(comments) - index + 1 : index]
					var/list/author_profile = SSpersistence.get_syndimatic_profile(comment["author"])
					var/list/comment_likes = comment["likes"]
					var/list/comment_dislikes = comment["dislikes"]
					var/vote = viewer_profile_id ? (comment_likes?[viewer_profile_id] ? 1 : (comment_dislikes?[viewer_profile_id] ? -1 : 0)) : 0
					rows += list(list(
						"id" = comment["id"],
						"authorId" = comment["author"],
						"author" = author_profile?["name"] || comment["name"],
						"avatar" = author_profile?["avatar"],
						"text" = comment["text"],
						"likes" = length(comment_likes),
						"dislikes" = length(comment_dislikes),
						"vote" = vote,
						"ownComment" = viewer_profile_id == comment["author"],
					))
				data["comments"] = rows
				data["commentSerial"] = comment_serial
				data["commentSort"] = comment_sort
				data["page"] = comment_page
				data["pages"] = pages
			return data
		post_id = null
		post_media = null
		comment_page = 0
	if(profile_id)
		var/list/profile = SSpersistence.get_syndimatic_profile(profile_id)
		if(profile)
			data["view"] = "profile"
			data["profile"] = profile
			data["ownProfile"] = profile_id == viewer_profile_id
			data["editingProfile"] = editing_profile
			var/list/profile_blocks = SSpersistence.syndimatic_blocks[profile_id]
			data["profileId"] = profile_id
			data["profilePublishBlocked"] = !!profile_blocks?["publish"]
			data["profileCommentBlocked"] = !!profile_blocks?["comment"]
			if(editing_profile || profile_blocks?["publish"])
				return data
		else
			profile_id = null

	var/list/posts = SSpersistence.syndimatic_posts
	var/list/ids = profile_id ? SSpersistence.syndimatic_posts_by_author[profile_id] : SSpersistence.syndimatic_feed
	if(data["view"] == "feed")
		data += syndimatic_feed_data(full = TRUE)
		return data

	var/pages = max(1, CEILING(length(ids) / SYNDIMATIC_PAGE_SIZE, 1))
	gallery_page = clamp(gallery_page, 1, pages)
	var/start = (gallery_page - 1) * SYNDIMATIC_PAGE_SIZE + 1
	var/list/gallery = list()
	for(var/index = start to min(start + SYNDIMATIC_PAGE_SIZE - 1, length(ids)))
		var/id = ids[index]
		var/list/summary = syndimatic_post_summary(id, posts[id], include_avatar = !profile_id)
		summary += SSpersistence.get_syndimatic_thumbnail(id)
		gallery += list(summary)
	data["posts"] = gallery
	data["page"] = gallery_page
	data["pages"] = pages
	return data

/datum/computer_file/program/syndimatic/proc/add_syndimatic_profile_status(list/data)
	var/list/blocks = viewer_profile_id ? SSpersistence.syndimatic_blocks[viewer_profile_id] : null
	data["canWrite"] = !!viewer_profile_id && SSticker.HasRoundStarted()
	data["publishBlocked"] = !!blocks?["publish"]
	data["commentBlocked"] = !!blocks?["comment"]
	data["myProfile"] = !!SSpersistence.get_syndimatic_profile(viewer_profile_id)

/datum/computer_file/program/syndimatic/proc/syndimatic_feed_data(full = FALSE, changed_profile_id)
	var/list/feed = SSpersistence.syndimatic_feed
	var/feed_size = min(feed_limit, length(feed))
	var/list/ids = list()
	var/list/sent_ids = list()
	var/list/data = list("feedIds" = ids, "feedLimit" = feed_limit, "feedHasMore" = feed_size < length(feed))
	for(var/index in 1 to feed_size)
		var/id = feed[index]
		var/list/post = SSpersistence.syndimatic_posts[id]
		ids += id
		sent_ids[id] = TRUE
		if(full || !feed_sent_ids?[id] || changed_profile_id == post["author"])
			data["feedPost:[id]"] = syndimatic_feed_post(id, post)
	for(var/id in feed_sent_ids)
		if(!sent_ids[id])
			data["feedPost:[id]"] = null
			data["feedPhoto:[id]"] = null
	feed_sent_ids = sent_ids
	return data

/datum/computer_file/program/syndimatic/proc/syndimatic_feed_post(id, list/post)
	var/list/summary = syndimatic_post_summary(id, post, include_avatar = TRUE)
	var/list/likes = post["likes"]
	summary["liked"] = viewer_profile_id && !!likes[viewer_profile_id]
	return summary

/datum/computer_file/program/syndimatic/proc/update_syndimatic_view(changed_post_id, changed_profile_id)
	var/datum/tgui/ui = viewer_ui_ref?.resolve()
	if(!ui)
		return
	if(!ui.initialized)
		ui.update_on_ready = TRUE
		return
	if(!is_viewing_syndimatic_feed() || !feed_sent_ids)
		push_update()
		return
	if(changed_post_id && !changed_profile_id)
		if(feed_sent_ids[changed_post_id])
			var/list/post = SSpersistence.get_visible_syndimatic_post(changed_post_id)
			if(post)
				ui.send_update(list("feedPost:[changed_post_id]" = syndimatic_feed_post(changed_post_id, post)))
		return
	var/list/data = syndimatic_feed_data(changed_profile_id = changed_profile_id)
	if(changed_post_id && feed_sent_ids[changed_post_id])
		var/list/post = SSpersistence.get_visible_syndimatic_post(changed_post_id)
		if(post)
			data["feedPost:[changed_post_id]"] = syndimatic_feed_post(changed_post_id, post)
	add_syndimatic_profile_status(data)
	ui.send_update(data)

/datum/computer_file/program/syndimatic/proc/syndimatic_post_summary(id, list/post, include_avatar = FALSE)
	var/list/profile = SSpersistence.get_syndimatic_profile(post["author"])
	. = list(
		"id" = id,
		"authorId" = post["author"],
		"author" = profile?["name"] || post["name"],
		"caption" = post["caption"],
		"likes" = length(post["likes"]),
		"comments" = length(post["comments"]),
	)
	if(include_avatar)
		.["avatar"] = profile?["avatar"]

/datum/computer_file/program/syndimatic/proc/is_viewing_syndimatic_feed()
	return !viewing_gallery && !viewing_blocks && !profile_id && !post_id && !draft_photo

/datum/computer_file/program/syndimatic/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	var/mob/user = ui?.user
	if(viewer_ui_ref?.resolve() != ui || !can_view_syndimatic(user))
		return FALSE
	. = ..()
	if(.)
		return
	var/datum/mind/actor = get_syndimatic_actor(user)
	if(viewer_profile_id != actor?.syndimatic_profile_id)
		return FALSE
	var/is_feed = is_viewing_syndimatic_feed()
	var/target_id = post_id
	if(action == "like" && is_feed && istext(params["id"]))
		target_id = params["id"]
	var/list/post = target_id ? SSpersistence.get_visible_syndimatic_post(target_id) : null
	switch(action)
		if("feed", "gallery", "profile", "blocks")
			if(action == "blocks" && !check_rights_for(user.client, R_ADMIN))
				return FALSE
			var/id
			if(action == "profile")
				id = params["id"] || viewer_profile_id
				if(!istext(id) || !SSpersistence.get_syndimatic_profile(id))
					return FALSE
			clear_syndimatic_draft()
			post_id = null
			post_media = null
			comment_page = 0
			gallery_page = 1
			editing_profile = FALSE
			viewing_blocks = action == "blocks"
			if(action == "feed" || action == "gallery")
				viewing_gallery = action == "gallery"
			profile_id = id
		if("feed_more")
			var/feed_size = length(SSpersistence.syndimatic_feed)
			var/known_limit = params["limit"]
			if(!is_feed || !isnum(known_limit) || known_limit > feed_limit)
				return FALSE
			if(known_limit == feed_limit && feed_limit < feed_size)
				feed_limit = min(feed_limit + SYNDIMATIC_FEED_BATCH_SIZE, feed_size)
				ui.send_update(syndimatic_feed_data())
			else
				// Если ответ потерялся, восстанавливаем снимок ленты для отставшего клиента.
				ui.send_update(syndimatic_feed_data(full = known_limit != feed_limit))
			return FALSE
		if("feed_photo")
			var/id = params["id"]
			var/list/feed = SSpersistence.syndimatic_feed
			if(!is_feed || !istext(id) || !feed.Find(id, 1, min(feed_limit, length(feed)) + 1))
				return FALSE
			// Передаём полноразмерный снимок отдельно от обновлений счётчиков.
			var/list/media = SSpersistence.get_syndimatic_media(id)
			ui.send_update(list("feedPhoto:[id]" = media || list("image" = null)))
			return FALSE
		if("open_post")
			var/id = params["id"]
			if(draft_photo || editing_profile || !istext(id) || !SSpersistence.get_visible_syndimatic_post(id))
				return FALSE
			post_id = id
			post_media = SSpersistence.get_syndimatic_media(id)
			comment_page = 1
		if("back")
			clear_syndimatic_draft()
			editing_profile = FALSE
			post_id = null
			post_media = null
			comment_page = 0
		if("page")
			var/page = params["page"]
			if(!isnum(page))
				return FALSE
			if(post)
				if(!comment_page)
					return FALSE
				comment_page = round(page)
			else
				gallery_page = round(page)
		if("show_comments")
			if(!post || params["id"] != post_id)
				return FALSE
			comment_page = comment_page ? 0 : 1
		if("sort_comments")
			var/order = params["order"]
			if(!post || !comment_page || params["id"] != post_id || !(order in list("oldest", "newest", "popular")) || order == comment_sort)
				return FALSE
			comment_sort = order
			comment_page = 1
		if("pick_post")
			var/list/blocks = viewer_profile_id ? SSpersistence.syndimatic_blocks[viewer_profile_id] : null
			if(blocks?["publish"])
				return FALSE
			return actor && SSticker.HasRoundStarted() && open_syndimatic_picker(user, "compose")
		if("pick_avatar")
			return actor && SSticker.HasRoundStarted() && profile_id == viewer_profile_id && SSpersistence.get_syndimatic_profile(profile_id) && open_syndimatic_picker(user, "avatar")
		if("edit_profile")
			if(!actor || profile_id != viewer_profile_id || post_id || !SSpersistence.get_syndimatic_profile(profile_id))
				return FALSE
			editing_profile = TRUE
		if("publish", "save_avatar", "save_profile", "like", "comment")
			return actor && SSticker.HasRoundStarted() && change_syndimatic_data(action, params, user, actor, post, target_id)
		if("vote_comment")
			return actor && SSticker.HasRoundStarted() && vote_on_syndimatic_comment(params, user, post, actor)
		if("delete_post", "delete_comment", "set_comments", "set_block")
			return moderate_syndimatic(action, params, user, post)
		if("notifications")
			var/enabled = params["enabled"]
			var/permanent = params["permanent"]
			if(!actor || !isnum(enabled) || (enabled != TRUE && enabled != FALSE) || !isnum(permanent) || (permanent != TRUE && permanent != FALSE))
				return FALSE
			var/datum/preferences/prefs = user.client.prefs
			if(permanent)
				if(!prefs?.path || prefs.player_save_blocked)
					to_chat(user, span_warning("Не удалось сохранить настройку уведомлений."))
					return FALSE
				prefs.syndimatic_notifications = enabled
				prefs.save_pref_var("syndimatic_notifications")
			actor.set_syndimatic_notifications(enabled)
		else
			return FALSE
	return TRUE

/datum/computer_file/program/syndimatic/proc/open_syndimatic_picker(mob/user, kind)
	var/datum/computer_file/program/pda_camera/camera = locate() in computer.get_all_files()
	if(!camera)
		to_chat(user, span_warning("На ПДА нет приложения камеры."))
		return FALSE
	var/datum/ui_state/camera_state = camera.ui_state(user)
	if(camera_state.can_use_topic(computer, user) != UI_INTERACTIVE || !computer.switch_program(camera, user))
		return FALSE
	camera.open_camera_ui(user, syndimatic = src, syndimatic_kind = kind)
	return TRUE

/datum/computer_file/program/syndimatic/proc/return_from_syndimatic_picker(mob/user, kind, datum/picture/photo)
	var/datum/mind/actor = get_syndimatic_actor(user)
	if(!actor || !computer?.enabled)
		return FALSE
	var/datum/ui_state/state = ui_state(user)
	if(state.can_use_topic(computer, user) != UI_INTERACTIVE)
		return FALSE
	var/photo_url = photo?.picture_url ? sanitize_headshot_link(html_decode(photo.picture_url)) : null
	if(photo && !photo.picture_image && !photo_url)
		to_chat(user, span_warning("Не удалось открыть снимок для Syndimatic."))
		return FALSE
	// При переключении камера удаляет выбранный облачный снимок.
	var/datum/picture/selected
	if(photo)
		selected = new(image = photo.picture_image ? icon(photo.picture_image) : null)
		selected.picture_url = photo_url
	if(!computer.switch_program(src, user))
		qdel(selected)
		return FALSE
	profile_id = kind == "avatar" ? actor.syndimatic_profile_id : null
	if(selected)
		draft_photo = selected
		draft_id = rustg_generate_uuid_v4()
		draft_kind = kind
	open_syndimatic_ui(user)
	return TRUE

/datum/computer_file/program/syndimatic/proc/change_syndimatic_data(action, list/params, mob/user, datum/mind/actor, list/post, target_id)
	if(!SSpersistence.start_syndimatic_round())
		to_chat(user, span_warning("Syndimatic пока недоступен."))
		return FALSE
	var/actor_id = actor.syndimatic_profile_id
	var/list/blocks = SSpersistence.syndimatic_blocks[actor_id]
	var/changed_post
	var/changed_profile
	var/saved = FALSE
	switch(action)
		if("publish")
			if(blocks?["publish"])
				to_chat(user, span_warning("Публикация в Syndimatic заблокирована."))
				return FALSE
			if(!draft_photo || draft_kind != "compose" || params["id"] != draft_id || !istext(params["caption"]))
				return FALSE
			var/photo_hash = syndimatic_photo_hash(draft_photo)
			if(!photo_hash)
				to_chat(user, span_warning("Не удалось прочитать снимок."))
				return FALSE
			if(SSpersistence.syndimatic_feed_photos[photo_hash])
				to_chat(user, span_warning("Этот снимок уже опубликован в ленте Syndimatic."))
				return FALSE
			var/id = SSpersistence.publish_syndimatic_post(actor, draft_photo, trim(params["caption"], PHOTO_CAPTION_LIMIT + 1), photo_hash)
			if(id)
				post_id = id
				post_media = draft_photo.photo_ui_media()
				comment_page = 1
				clear_syndimatic_draft()
				saved = TRUE
		if("save_avatar", "save_profile")
			var/list/profile = SSpersistence.get_syndimatic_profile(actor_id)
			if(profile_id != actor_id || !profile)
				return FALSE
			profile = profile.Copy()
			if(action == "save_avatar")
				if(!draft_photo || draft_kind != "avatar" || params["id"] != draft_id)
					return FALSE
				var/thumbnail = pda_photo_thumbnail(draft_photo.picture_image)
				profile["avatar"] = thumbnail ? list("image" = thumbnail) : draft_photo.photo_ui_media()
			else
				if(!editing_profile || !istext(params["description"]))
					return FALSE
				profile["description"] = trim(params["description"], PHOTO_DESCRIPTION_LIMIT + 1)
			if(SSpersistence.save_syndimatic_profile(actor_id, profile))
				clear_syndimatic_draft()
				editing_profile = FALSE
				changed_profile = actor_id
				saved = TRUE
		if("like", "comment")
			if(!post || params["id"] != target_id || SSpersistence.get_visible_syndimatic_post(target_id) != post)
				return FALSE
			var/list/updated_post = post.Copy()
			var/datum/mind/new_activity = actor
			if(action == "like")
				var/liked = params["liked"]
				if(!isnum(liked) || (liked != TRUE && liked != FALSE))
					return FALSE
				var/list/likes = post["likes"]
				if(!!likes[actor_id] == liked)
					return !is_viewing_syndimatic_feed()
				likes = likes.Copy()
				if(liked)
					likes[actor_id] = TRUE
				else
					likes -= actor_id
					new_activity = null
				updated_post["likes"] = likes
			else
				if(blocks?["comment"] || post["comments_disabled"])
					to_chat(user, span_warning("Оставить комментарий к этой публикации сейчас нельзя."))
					return FALSE
				var/draft_serial = params["commentSerial"]
				if(!comment_page || !istext(params["text"]) || !isnum(draft_serial) || draft_serial != comment_serial)
					return FALSE
				var/message = trim(params["text"], PHOTO_CAPTION_LIMIT + 1)
				if(!length(message))
					return FALSE
				var/list/comments = post["comments"]
				comments = comments.Copy()
				comments.Insert(1, list(list(
					"id" = rustg_generate_uuid_v7(),
					"author" = actor_id,
					"name" = actor.syndimatic_character_name,
					"text" = message,
				)))
				updated_post["comments"] = comments
			var/creates_profile = new_activity && !SSpersistence.get_syndimatic_profile(actor_id)
			saved = SSpersistence.save_syndimatic_post(target_id, updated_post, new_activity)
			if(saved && creates_profile)
				changed_profile = actor_id
			if(saved && action == "comment")
				if(comment_sort == "oldest")
					comment_page = CEILING(length(updated_post["comments"]) / SYNDIMATIC_COMMENT_PAGE_SIZE, 1)
				else if(comment_sort == "newest")
					comment_page = 1
				comment_serial++
			changed_post = target_id
	if(!saved)
		to_chat(user, span_warning("Не удалось сохранить изменения в Syndimatic."))
		return FALSE
	SSpersistence.notify_syndimatic_viewers(src, changed_post, changed_profile)
	if(changed_post && is_viewing_syndimatic_feed())
		update_syndimatic_view(changed_post, changed_profile)
		return FALSE
	return TRUE

/datum/computer_file/program/syndimatic/proc/syndimatic_comment_index(list/comments, comment_id)
	if(istext(comment_id))
		for(var/index in 1 to length(comments))
			var/list/comment = comments[index]
			if(comment["id"] == comment_id)
				return index
	return 0

/datum/computer_file/program/syndimatic/proc/vote_on_syndimatic_comment(list/params, mob/user, list/post, datum/mind/actor)
	var/vote = params["vote"]
	if(!post || post_id != params["id"] || !comment_page || !isnum(vote) || (vote != -1 && vote != 0 && vote != 1))
		return FALSE
	var/list/comments = post["comments"]
	var/index = syndimatic_comment_index(comments, params["comment"])
	if(!index)
		return FALSE
	var/list/comment = comments[index]
	if(comment["author"] == viewer_profile_id)
		return FALSE

	var/list/likes = comment["likes"]
	var/list/dislikes = comment["dislikes"]
	var/previous_vote = likes?[viewer_profile_id] ? 1 : (dislikes?[viewer_profile_id] ? -1 : 0)
	if(previous_vote == vote)
		return TRUE

	var/list/updated_comment = comment.Copy()
	if(previous_vote == 1 || vote == 1)
		likes = likes?.Copy() || list()
		if(vote == 1)
			likes[viewer_profile_id] = TRUE
		else
			likes -= viewer_profile_id
		updated_comment["likes"] = likes
	if(previous_vote == -1 || vote == -1)
		dislikes = dislikes?.Copy() || list()
		if(vote == -1)
			dislikes[viewer_profile_id] = TRUE
		else
			dislikes -= viewer_profile_id
		updated_comment["dislikes"] = dislikes

	var/list/updated = post.Copy()
	var/list/updated_comments = comments.Copy()
	updated_comments[index] = updated_comment
	updated["comments"] = updated_comments
	var/datum/mind/new_activity = vote == 1 ? actor : null
	var/creates_profile = new_activity && !SSpersistence.get_syndimatic_profile(viewer_profile_id)
	if(!SSpersistence.save_syndimatic_post(post_id, updated, new_activity))
		to_chat(user, span_warning("Не удалось сохранить оценку комментария."))
		return FALSE
	SSpersistence.notify_syndimatic_viewers(src, post_id, creates_profile ? viewer_profile_id : null)
	return TRUE

/datum/computer_file/program/syndimatic/proc/moderate_syndimatic(action, list/params, mob/user, list/post)
	var/is_admin = check_rights_for(user.client, R_ADMIN)
	var/saved = FALSE
	if(action == "set_block")
		var/kind = params["kind"]
		var/blocked = params["blocked"]
		if(!is_admin || !profile_id || post_id || profile_id != params["id"] || (kind != "publish" && kind != "comment") || !isnum(blocked) || (blocked != TRUE && blocked != FALSE))
			return FALSE
		var/list/profile = SSpersistence.get_syndimatic_profile(profile_id)
		if(!profile)
			return FALSE
		saved = SSpersistence.set_syndimatic_block(profile_id, kind, blocked)
		if(saved)
			log_admin("[key_name(user)] изменил блокировку Syndimatic ([kind], [blocked]) для [profile["name"]] ([profile_id]).")
			SSpersistence.notify_syndimatic_viewers(src, profile_id = profile_id)
	else
		if(!post || post_id != params["id"])
			return FALSE
		var/own_post = viewer_profile_id == post["author"]
		var/id = post_id
		switch(action)
			if("delete_post")
				if(!own_post && !is_admin)
					return FALSE
				saved = SSpersistence.delete_syndimatic_post(id)
				if(saved && is_admin && !own_post)
					log_admin("[key_name(user)] удалил публикацию Syndimatic [id], автор [post["author"]].")
			if("set_comments")
				var/disabled = params["disabled"]
				if(!own_post || !isnum(disabled) || (disabled != TRUE && disabled != FALSE))
					return FALSE
				var/list/updated = post.Copy()
				updated["comments_disabled"] = disabled
				saved = SSpersistence.save_syndimatic_post(id, updated)
			if("delete_comment")
				var/comment_id = params["comment"]
				if(!is_admin || !comment_page)
					return FALSE
				var/list/comments = post["comments"]
				var/index = syndimatic_comment_index(comments, comment_id)
				if(!index)
					return FALSE
				var/list/comment = comments[index]
				var/list/updated = post.Copy()
				var/list/remaining_comments = comments.Copy()
				remaining_comments.Cut(index, index + 1)
				updated["comments"] = remaining_comments
				saved = SSpersistence.save_syndimatic_post(id, updated)
				if(saved)
					log_admin("[key_name(user)] удалил комментарий Syndimatic [comment_id] к публикации [id], автор [comment["author"]].")
		if(saved)
			SSpersistence.notify_syndimatic_viewers(src, action == "delete_post" ? null : id)
	if(!saved)
		to_chat(user, span_warning("Не удалось сохранить изменения в Syndimatic."))
	return saved

#undef SYNDIMATIC_PAGE_SIZE
#undef SYNDIMATIC_FEED_BATCH_SIZE
#undef SYNDIMATIC_COMMENT_PAGE_SIZE
