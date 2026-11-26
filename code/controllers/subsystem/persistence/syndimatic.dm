#define SYNDIMATIC_DIRECTORY "data/persistence/syndimatic/"
#define SYNDIMATIC_POSTS "[SYNDIMATIC_DIRECTORY]posts/"
#define SYNDIMATIC_PROFILES "[SYNDIMATIC_DIRECTORY]profiles/"
#define SYNDIMATIC_ROUND_FILE "[SYNDIMATIC_DIRECTORY]round.json"
#define SYNDIMATIC_BLOCKS_FILE "[SYNDIMATIC_DIRECTORY]blocks.json"
#define SYNDIMATIC_POST_LIFETIME 5
#define SYNDIMATIC_MIN_POSTS 10

/datum/controller/subsystem/persistence
	var/syndimatic_round = 0
	var/syndimatic_round_started = FALSE
	// Ключи публикаций упорядочены от новых к старым.
	var/list/syndimatic_posts = list()
	var/list/syndimatic_posts_by_author = list()
	var/list/syndimatic_thumbnails = list()
	var/list/syndimatic_profiles = list()
	var/list/syndimatic_viewers = list()
	var/list/syndimatic_blocks = list()
	var/list/datum/weakref/syndimatic_subscribers = list()
	var/list/syndimatic_feed = list()
	var/list/syndimatic_feed_photos = list()

/datum/controller/subsystem/persistence/proc/load_syndimatic()
	syndimatic_blocks = read_syndimatic_record(SYNDIMATIC_BLOCKS_FILE) || list()
	var/list/round_record = read_syndimatic_record(SYNDIMATIC_ROUND_FILE)
	syndimatic_round = round_record?["round"] || 0
	var/static/regex/post_file = regex("^(\[0-9a-f-\]{36})\\.json(\\.bak)?$")
	var/list/ids = list()
	for(var/filename in flist(SYNDIMATIC_POSTS))
		if(post_file.Find(filename))
			ids[post_file.group[1]] = TRUE
	sortTim(ids, GLOBAL_PROC_REF(cmp_text_dsc), associative = TRUE)
	for(var/id in ids)
		var/list/post = read_syndimatic_record("[SYNDIMATIC_POSTS][id].json")
		if(!isnum(post?["round"]) || !istext(post["author"]) || !islist(post["likes"]) || !islist(post["comments"]))
			continue
		if(!post["photo_hash"])
			var/datum/picture/photo = read_pda_cloud_photo("[SYNDIMATIC_POSTS][id].sav", TRUE)
			if(photo)
				post["photo_hash"] = syndimatic_photo_hash(photo)
				qdel(photo)
		syndimatic_posts[id] = post
		var/author = post["author"]
		LAZYADD(syndimatic_posts_by_author[author], id)
		syndimatic_round = max(syndimatic_round, post["round"])
	rebuild_syndimatic_feed()

/datum/controller/subsystem/persistence/proc/rebuild_syndimatic_feed()
	var/list/feed = list()
	var/list/photos = list()
	for(var/id in syndimatic_posts)
		var/list/post = syndimatic_posts[id]
		var/list/blocks = syndimatic_blocks[post["author"]]
		if(!blocks?["publish"])
			feed[id] = TRUE
			var/hash = post["photo_hash"]
			if(hash)
				photos[hash] = (photos[hash] || 0) + 1
	syndimatic_feed = feed
	syndimatic_feed_photos = photos

/proc/syndimatic_photo_hash(datum/picture/photo)
	if(photo.picture_url)
		return rustg_hash_string(RUSTG_HASH_SHA256, html_decode(photo.picture_url))
	var/image = photo.get_base64()
	if(image)
		return rustg_hash_string(RUSTG_HASH_SHA256, image)
	return null

/datum/controller/subsystem/persistence/proc/get_visible_syndimatic_post(id)
	if(syndimatic_feed[id])
		return syndimatic_posts[id]

/datum/controller/subsystem/persistence/proc/on_syndimatic_round_start()
	SIGNAL_HANDLER
	start_syndimatic_round()
	INVOKE_ASYNC(src, PROC_REF(notify_syndimatic_viewers))

/datum/controller/subsystem/persistence/proc/start_syndimatic_round()
	if(syndimatic_round_started)
		return TRUE
	var/next_round = syndimatic_round + 1
	if(!write_syndimatic_record(SYNDIMATIC_ROUND_FILE, list("round" = next_round)))
		log_game("Syndimatic: не удалось сохранить номер смены.")
		return FALSE
	syndimatic_round = next_round
	syndimatic_round_started = TRUE
	prune_syndimatic_posts()
	return TRUE

/datum/controller/subsystem/persistence/proc/prune_syndimatic_posts()
	while(length(syndimatic_posts) > SYNDIMATIC_MIN_POSTS)
		var/id = syndimatic_posts[length(syndimatic_posts)]
		var/list/post = syndimatic_posts[id]
		if(syndimatic_round - post["round"] < SYNDIMATIC_POST_LIFETIME)
			break
		if(!delete_syndimatic_post(id))
			break

/datum/controller/subsystem/persistence/proc/get_syndimatic_thumbnail(id)
	if(!(id in syndimatic_thumbnails))
		var/list/metadata = read_pda_cloud_photo("[SYNDIMATIC_POSTS][id].sav")
		syndimatic_thumbnails[id] = list(
			"thumbnail" = metadata?["thumbnail"],
			"thumbnailUrl" = metadata?["url"] ? html_decode(metadata["url"]) : null,
		)
	return syndimatic_thumbnails[id]

/datum/controller/subsystem/persistence/proc/get_syndimatic_media(id)
	var/datum/picture/photo = read_pda_cloud_photo("[SYNDIMATIC_POSTS][id].sav", TRUE)
	var/list/media = photo?.photo_ui_media()
	qdel(photo)
	return media

/datum/controller/subsystem/persistence/proc/get_syndimatic_profile(id)
	if(!id)
		return null
	if(!(id in syndimatic_profiles))
		var/static/regex/profile_key = regex("^\[0-9a-f\]{64}$")
		if(!profile_key.Find(id))
			return null
		var/list/profile = read_syndimatic_record("[SYNDIMATIC_PROFILES][id].json")
		if(profile)
			syndimatic_profiles[id] = profile
	return syndimatic_profiles[id]

/datum/controller/subsystem/persistence/proc/set_syndimatic_block(id, kind, blocked)
	var/list/updated = syndimatic_blocks.Copy()
	var/list/blocks = syndimatic_blocks[id]
	blocks = blocks?.Copy() || list()
	if(blocked)
		blocks[kind] = TRUE
	else
		blocks -= kind
	if(length(blocks))
		updated[id] = blocks
	else
		updated -= id
	if(!write_syndimatic_record(SYNDIMATIC_BLOCKS_FILE, updated))
		return FALSE
	syndimatic_blocks = updated
	if(kind == "publish")
		rebuild_syndimatic_feed()
	return TRUE

/datum/controller/subsystem/persistence/proc/save_syndimatic_profile(id, list/profile)
	if(!write_syndimatic_record("[SYNDIMATIC_PROFILES][id].json", profile))
		return FALSE
	syndimatic_profiles[id] = profile
	return TRUE

/datum/controller/subsystem/persistence/proc/ensure_syndimatic_profile(datum/mind/actor)
	var/id = actor.syndimatic_profile_id
	if(get_syndimatic_profile(id))
		return TRUE
	var/list/avatar = actor.syndimatic_first_portrait ? list("url" = actor.syndimatic_first_portrait) : null
	return save_syndimatic_profile(id, list(
		"name" = actor.syndimatic_character_name,
		"description" = "",
		"avatar" = avatar,
	))

/datum/controller/subsystem/persistence/proc/save_syndimatic_post(id, list/post, datum/mind/new_activity)
	var/profile_id = new_activity?.syndimatic_profile_id
	var/created_profile = profile_id && !get_syndimatic_profile(profile_id)
	if(created_profile && !ensure_syndimatic_profile(new_activity))
		return FALSE
	if(!write_syndimatic_record("[SYNDIMATIC_POSTS][id].json", post))
		if(created_profile && delete_pda_cloud_photo("[SYNDIMATIC_PROFILES][profile_id].json"))
			syndimatic_profiles -= profile_id
		return FALSE
	if(!syndimatic_posts[id])
		syndimatic_posts.Insert(1, id)
		var/author = post["author"]
		var/list/blocks = syndimatic_blocks[author]
		if(!blocks?["publish"])
			syndimatic_feed.Insert(1, id)
			syndimatic_feed[id] = TRUE
			var/hash = post["photo_hash"]
			if(hash)
				syndimatic_feed_photos[hash] = (syndimatic_feed_photos[hash] || 0) + 1
		LAZYINITLIST(syndimatic_posts_by_author[author])
		var/list/author_posts = syndimatic_posts_by_author[author]
		author_posts.Insert(1, id)
	syndimatic_posts[id] = post
	return TRUE

/datum/controller/subsystem/persistence/proc/publish_syndimatic_post(datum/mind/actor, datum/picture/photo, caption, photo_hash)
	var/id = rustg_generate_uuid_v7()
	var/path = "[SYNDIMATIC_POSTS][id].sav"
	var/thumbnail = pda_photo_thumbnail(photo.picture_image)
	if(!save_pda_cloud_photo(path, photo, thumbnail))
		return null
	if(!save_syndimatic_post(id, list(
		"round" = syndimatic_round,
		"author" = actor.syndimatic_profile_id,
		"name" = actor.syndimatic_character_name,
		"caption" = caption,
		"photo_hash" = photo_hash,
		"likes" = list(),
		"comments" = list(),
	), actor))
		delete_pda_cloud_photo(path)
		return null
	syndimatic_thumbnails[id] = list(
		"thumbnail" = thumbnail,
		"thumbnailUrl" = photo.picture_url ? html_decode(photo.picture_url) : null,
	)
	prune_syndimatic_posts()
	notify_syndimatic_subscribers(actor)
	return id

/datum/controller/subsystem/persistence/proc/notify_syndimatic_subscribers(datum/mind/author)
	for(var/datum/weakref/subscriber as anything in syndimatic_subscribers)
		var/datum/mind/recipient = subscriber.resolve()
		if(!recipient || recipient == author)
			continue
		var/mob/living/holder = recipient.current
		if(!isliving(holder) || holder.client?.ckey != recipient.syndimatic_owner_ckey)
			continue
		for(var/obj/item/modular_computer/pda/device as anything in holder.GetAllContents(/obj/item/modular_computer/pda))
			if(device.toff)
				continue
			var/list/programs = device.get_all_files()
			var/datum/computer_file/program/syndimatic/program = locate() in programs
			if(!program)
				continue
			program.alert_pending = device.active_program != program
			if(holder.stat < UNCONSCIOUS && holder.is_literate())
				to_chat(holder, span_info("[icon2html(device, holder)] Syndimatic: новая публикация от [html_encode(author.syndimatic_character_name)]."))
			if(!device.silent)
				var/datum/computer_file/program/messenger/messenger = locate() in programs
				device.ring(messenger ? messenger.ringtone : MESSENGER_RINGTONE_DEFAULT, list(holder))
			device.receive_message(null)
			SStgui.update_uis(device)
			break

/datum/controller/subsystem/persistence/proc/delete_syndimatic_post(id)
	var/list/post = syndimatic_posts[id]
	if(!post)
		return FALSE
	var/path = "[SYNDIMATIC_POSTS][id].json"
	if(!delete_pda_cloud_photo(path))
		return FALSE
	var/hash = post["photo_hash"]
	if(syndimatic_feed[id] && hash)
		if(syndimatic_feed_photos[hash] > 1)
			syndimatic_feed_photos[hash]--
		else
			syndimatic_feed_photos -= hash
	syndimatic_posts -= id
	syndimatic_feed -= id
	syndimatic_thumbnails -= id
	var/author = post["author"]
	var/list/author_posts = syndimatic_posts_by_author[author]
	author_posts -= id
	if(!length(author_posts))
		syndimatic_posts_by_author -= author
	if(!delete_pda_cloud_photo("[SYNDIMATIC_POSTS][id].sav"))
		log_game("Syndimatic: не удалось удалить архив публикации [id].")
	return TRUE

/datum/controller/subsystem/persistence/proc/notify_syndimatic_viewers(datum/computer_file/program/syndimatic/source, post_id, profile_id)
	for(var/datum/weakref/viewer_ref as anything in syndimatic_viewers.Copy())
		var/datum/computer_file/program/syndimatic/viewer = viewer_ref.resolve()
		if(!viewer)
			syndimatic_viewers -= viewer_ref
		else if(viewer != source && viewer.shows_syndimatic_change(post_id, profile_id))
			viewer.push_update()

/proc/read_syndimatic_record(path)
	if(fexists(path))
		var/list/data = safe_json_decode(file2text(path), null)
		if(islist(data))
			return data
	var/backup = "[path].bak"
	if(fexists(backup))
		return safe_json_decode(file2text(backup), null)
	return null

/proc/write_syndimatic_record(path, list/data)
	var/temp_path = "[path].tmp"
	fdel(temp_path)
	if(!text2file(json_encode(data), temp_path))
		fdel(temp_path)
		return FALSE
	// Если основной файл повреждён, сохраняем последнюю исправную резервную копию.
	var/backup_ready = !fexists(path) || !islist(safe_json_decode(file2text(path), null)) || fcopy(path, "[path].bak")
	var/saved = backup_ready && fcopy(temp_path, path)
	fdel(temp_path)
	return saved

#undef SYNDIMATIC_DIRECTORY
#undef SYNDIMATIC_POSTS
#undef SYNDIMATIC_PROFILES
#undef SYNDIMATIC_ROUND_FILE
#undef SYNDIMATIC_BLOCKS_FILE
#undef SYNDIMATIC_POST_LIFETIME
#undef SYNDIMATIC_MIN_POSTS
