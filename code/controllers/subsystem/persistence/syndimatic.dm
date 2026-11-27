#define SYNDIMATIC_DIRECTORY "data/persistence/syndimatic/"
#define SYNDIMATIC_POSTS "[SYNDIMATIC_DIRECTORY]posts/"
#define SYNDIMATIC_PROFILES "[SYNDIMATIC_DIRECTORY]profiles/"
#define SYNDIMATIC_FOLLOWS "[SYNDIMATIC_DIRECTORY]follows/"
#define SYNDIMATIC_BLOCKS_FILE "[SYNDIMATIC_DIRECTORY]blocks.json"
// Временные параметры для публикаций без ключа аккаунта. Удалить после истечения их срока.
#define SYNDIMATIC_LEGACY_ROUND_FILE "[SYNDIMATIC_DIRECTORY]round.json"
#define SYNDIMATIC_LEGACY_POST_LIFETIME 5
#define SYNDIMATIC_MEDIA_CACHE_SIZE 12

/datum/controller/subsystem/persistence
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
	var/list/syndimatic_media = list()
	var/list/syndimatic_ranked_comments = list()
	var/list/syndimatic_posts_by_account = list()
	var/list/syndimatic_accounts_pruning = list()
	// Временный индекс публикаций без ключа аккаунта и их счётчик смен.
	var/list/syndimatic_legacy_posts = list()
	var/syndimatic_legacy_round = 0
	var/list/syndimatic_follows = list()
	var/list/syndimatic_follower_counts = list()
	var/syndimatic_post_index_version = 0

/datum/controller/subsystem/persistence/proc/get_syndimatic_ranked_comments(id, list/comments)
	if(!syndimatic_ranked_comments[id])
		syndimatic_ranked_comments[id] = sortTim(reverseList(comments), GLOBAL_PROC_REF(cmp_syndimatic_comment_likes))
	return syndimatic_ranked_comments[id]

/proc/cmp_syndimatic_comment_likes(list/left, list/right)
	return length(right["likes"]) - length(left["likes"])

/datum/controller/subsystem/persistence/proc/load_syndimatic()
	syndimatic_blocks = read_syndimatic_record(SYNDIMATIC_BLOCKS_FILE) || list()
	var/static/regex/post_file = regex("^(\[0-9a-f-\]{36})\\.json(\\.bak)?$")
	var/list/ids = list()
	for(var/filename in flist(SYNDIMATIC_POSTS))
		CHECK_TICK
		if(post_file.Find(filename))
			ids[post_file.group[1]] = TRUE
	sortTim(ids, GLOBAL_PROC_REF(cmp_text_dsc))
	for(var/id in ids)
		CHECK_TICK
		var/list/post = read_syndimatic_record("[SYNDIMATIC_POSTS][id].json")
		if(!istext(post?["author"]) || !islist(post["likes"]) || !islist(post["comments"]))
			continue
		var/account = post["account"]
		// После перехода на квоты при загрузке можно требовать ключ аккаунта у каждого поста.
		if(account ? !istext(account) : !isnum(post["round"]))
			continue
		if(!post["photo_hash"])
			var/datum/picture/photo = read_pda_cloud_photo("[SYNDIMATIC_POSTS][id].sav", TRUE)
			if(photo)
				post["photo_hash"] = syndimatic_photo_hash(photo)
				qdel(photo)
		syndimatic_posts[id] = post
		var/author = post["author"]
		LAZYADD(syndimatic_posts_by_author[author], id)
		if(account)
			LAZYADD(syndimatic_posts_by_account[account], id)
		else
			// Временная ветка загрузки постов, сохранённых до перехода на квоты.
			syndimatic_legacy_posts += id
			syndimatic_legacy_round = max(syndimatic_legacy_round, post["round"])
	if(length(syndimatic_legacy_posts))
		var/list/legacy_round = read_syndimatic_record(SYNDIMATIC_LEGACY_ROUND_FILE)
		if(isnum(legacy_round?["round"]))
			syndimatic_legacy_round = max(syndimatic_legacy_round, legacy_round["round"])
	rebuild_syndimatic_feed()
	load_syndimatic_follows()

/datum/controller/subsystem/persistence/proc/load_syndimatic_follows()
	var/static/regex/follow_file = regex("^(\[0-9a-f\]{64})\\.json(\\.bak)?$")
	var/list/accounts = list()
	for(var/filename in flist(SYNDIMATIC_FOLLOWS))
		CHECK_TICK
		if(follow_file.Find(filename))
			accounts[follow_file.group[1]] = TRUE
	for(var/account in accounts)
		CHECK_TICK
		var/list/saved = read_syndimatic_record("[SYNDIMATIC_FOLLOWS][account].json")
		if(!length(saved))
			continue
		var/list/follows = list()
		for(var/id in saved)
			if(!istext(id) || length(id) != 64)
				continue
			switch(saved[id])
				if(SYNDIMATIC_FOLLOW_NOTIFY_DEFAULT, SYNDIMATIC_FOLLOW_NOTIFY_ON, SYNDIMATIC_FOLLOW_NOTIFY_OFF)
					follows[id] = saved[id]
					syndimatic_follower_counts[id] = (syndimatic_follower_counts[id] || 0) + 1
		if(length(follows))
			syndimatic_follows[account] = follows

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
	syndimatic_post_index_version++

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
	INVOKE_ASYNC(src, PROC_REF(refresh_syndimatic_on_round_start))

/datum/controller/subsystem/persistence/proc/refresh_syndimatic_on_round_start()
	prune_legacy_syndimatic_posts()
	notify_syndimatic_viewers()

// Временная очистка по возрасту только для постов старого формата. Удалить прок и его вызов после перехода.
/datum/controller/subsystem/persistence/proc/prune_legacy_syndimatic_posts()
	if(!length(syndimatic_legacy_posts))
		return
	var/next_round = syndimatic_legacy_round + 1
	if(!write_syndimatic_record(SYNDIMATIC_LEGACY_ROUND_FILE, list("round" = next_round)))
		log_game("Syndimatic: не удалось обновить номер смены для очистки старых публикаций.")
		return
	syndimatic_legacy_round = next_round
	while(length(syndimatic_legacy_posts))
		var/id = syndimatic_legacy_posts[length(syndimatic_legacy_posts)]
		var/list/post = syndimatic_posts[id]
		if(syndimatic_legacy_round - post["round"] < SYNDIMATIC_LEGACY_POST_LIFETIME || !delete_syndimatic_post(id))
			break
		CHECK_TICK

/proc/syndimatic_post_limit(account_ckey)
	if(IS_CKEY_DONATOR_GROUP(account_ckey, DONATOR_GROUP_TIER_2))
		return SYNDIMATIC_TIER_2_LIMIT
	if(IS_CKEY_DONATOR_GROUP(account_ckey, DONATOR_GROUP_TIER_1))
		return SYNDIMATIC_TIER_1_LIMIT
	return SYNDIMATIC_ACCOUNT_LIMIT

/proc/syndimatic_post_limit_options(maximum)
	var/static/list/regular_options = list(SYNDIMATIC_ACCOUNT_LIMIT)
	var/static/list/tier_1_options = list(SYNDIMATIC_ACCOUNT_LIMIT, SYNDIMATIC_TIER_1_LIMIT)
	var/static/list/tier_2_options = list(SYNDIMATIC_ACCOUNT_LIMIT, SYNDIMATIC_TIER_1_LIMIT, SYNDIMATIC_TIER_2_LIMIT)
	switch(maximum)
		if(SYNDIMATIC_TIER_2_LIMIT)
			return tier_2_options
		if(SYNDIMATIC_TIER_1_LIMIT)
			return tier_1_options
	return regular_options

/proc/syndimatic_effective_post_limit(maximum, preferred_limit)
	if(maximum == SYNDIMATIC_ACCOUNT_LIMIT || !preferred_limit)
		return maximum
	// Старые числовые настройки округляем вниз до доступного варианта, минимум до 20.
	var/list/options = syndimatic_post_limit_options(maximum)
	for(var/index = length(options), index > 1, index--)
		if(preferred_limit >= options[index])
			return options[index]
	return SYNDIMATIC_ACCOUNT_LIMIT

/datum/controller/subsystem/persistence/proc/get_syndimatic_thumbnail(id)
	if(!(id in syndimatic_thumbnails))
		var/list/metadata = read_pda_cloud_photo("[SYNDIMATIC_POSTS][id].sav")
		syndimatic_thumbnails[id] = list(
			"thumbnail" = metadata?["thumbnail"],
			"thumbnailUrl" = metadata?["url"] ? html_decode(metadata["url"]) : null,
		)
	return syndimatic_thumbnails[id]

/datum/controller/subsystem/persistence/proc/get_syndimatic_media(id)
	if(id in syndimatic_media)
		return syndimatic_media[id]
	var/datum/picture/photo = read_pda_cloud_photo("[SYNDIMATIC_POSTS][id].sav", TRUE)
	var/list/media = photo?.photo_ui_media()
	qdel(photo)
	syndimatic_media[id] = media
	if(length(syndimatic_media) > SYNDIMATIC_MEDIA_CACHE_SIZE)
		syndimatic_media.Cut(1, 2)
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

/proc/syndimatic_account_id(account_ckey)
	return rustg_hash_string(RUSTG_HASH_SHA256, "syndimatic/account/[account_ckey]")

/datum/controller/subsystem/persistence/proc/set_syndimatic_follow(account, target_id, following)
	var/list/follows = syndimatic_follows[account]
	var/list/updated = follows?.Copy() || list()
	if(following)
		updated[target_id] = SYNDIMATIC_FOLLOW_NOTIFY_DEFAULT
	else
		updated -= target_id
	if(!write_syndimatic_record("[SYNDIMATIC_FOLLOWS][account].json", updated))
		return FALSE
	if(length(updated))
		syndimatic_follows[account] = updated
	else
		syndimatic_follows -= account
	var/count = (syndimatic_follower_counts[target_id] || 0) + (following ? 1 : -1)
	if(count > 0)
		syndimatic_follower_counts[target_id] = count
	else
		syndimatic_follower_counts -= target_id
	return TRUE

/datum/controller/subsystem/persistence/proc/cycle_syndimatic_follow_notification(account, target_id)
	var/list/follows = syndimatic_follows[account]
	var/mode = follows?[target_id]
	switch(mode)
		if(SYNDIMATIC_FOLLOW_NOTIFY_DEFAULT)
			mode = SYNDIMATIC_FOLLOW_NOTIFY_ON
		if(SYNDIMATIC_FOLLOW_NOTIFY_ON)
			mode = SYNDIMATIC_FOLLOW_NOTIFY_OFF
		if(SYNDIMATIC_FOLLOW_NOTIFY_OFF)
			mode = SYNDIMATIC_FOLLOW_NOTIFY_DEFAULT
		else
			return FALSE
	var/list/updated = follows.Copy()
	updated[target_id] = mode
	if(!write_syndimatic_record("[SYNDIMATIC_FOLLOWS][account].json", updated))
		return FALSE
	// Состав подписок прежний, поэтому кэш публикаций можно сохранить.
	follows[target_id] = mode
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
	var/list/previous_post = syndimatic_posts[id]
	if(!previous_post)
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
		var/account = post["account"]
		LAZYINITLIST(syndimatic_posts_by_account[account])
		var/list/account_posts = syndimatic_posts_by_account[account]
		account_posts.Insert(1, id)
		syndimatic_post_index_version++
	if(previous_post?["comments"] != post["comments"])
		syndimatic_ranked_comments -= id
	syndimatic_posts[id] = post
	return TRUE

/datum/controller/subsystem/persistence/proc/publish_syndimatic_post(datum/mind/actor, datum/picture/photo, caption, photo_hash, preferred_limit)
	var/account_ckey = actor.syndimatic_owner_ckey
	var/account = syndimatic_account_id(account_ckey)
	if(syndimatic_accounts_pruning[account])
		return null
	var/id = rustg_generate_uuid_v7()
	var/path = "[SYNDIMATIC_POSTS][id].sav"
	var/thumbnail = pda_photo_thumbnail(photo.picture_image)
	if(!save_pda_cloud_photo(path, photo, thumbnail))
		return null
	if(!save_syndimatic_post(id, list(
		"account" = account,
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
	var/limit = syndimatic_effective_post_limit(syndimatic_post_limit(account_ckey), preferred_limit)
	if(!prune_syndimatic_account_posts(account, limit))
		// Если старый пост не удалился, откатываем новый, чтобы не превысить квоту.
		if(!syndimatic_posts[id] || delete_syndimatic_post(id))
			INVOKE_ASYNC(src, PROC_REF(notify_syndimatic_viewers))
			return null
		log_game("Syndimatic: не удалось освободить место и отменить публикацию [id].")
	if(!syndimatic_posts[id])
		return null
	var/list/published_post = get_visible_syndimatic_post(id)
	if(published_post)
		notify_syndimatic_subscribers(id, published_post)
	return id

/datum/controller/subsystem/persistence/proc/prune_syndimatic_account_posts(account, limit)
	var/list/account_posts = syndimatic_posts_by_account[account]
	if(length(account_posts) <= limit)
		return TRUE
	// Пока очистка уступает тик, другая публикация этого аккаунта не меняет его индекс.
	syndimatic_accounts_pruning[account] = TRUE
	. = TRUE
	try
		while(length(account_posts) > limit)
			if(!delete_syndimatic_post(account_posts[length(account_posts)]))
				. = FALSE
				break
			CHECK_TICK
	catch(var/exception/error)
		log_game("Syndimatic: ошибка очистки публикаций по квоте: [error.name]")
		. = FALSE
	syndimatic_accounts_pruning -= account

/datum/controller/subsystem/persistence/proc/notify_syndimatic_subscribers(id, list/post)
	var/author_id = post["author"]
	var/author_account = post["account"]
	var/author_name = html_encode(post["name"])
	for(var/datum/weakref/subscriber as anything in syndimatic_subscribers)
		var/datum/mind/recipient = subscriber.resolve()
		if(!recipient || recipient.syndimatic_owner_account == author_account)
			continue
		var/mob/living/holder = recipient.current
		if(!isliving(holder) || holder.client?.ckey != recipient.syndimatic_owner_ckey)
			continue
		var/list/follows = syndimatic_follows[recipient.syndimatic_owner_account]
		var/mode = follows?[author_id]
		var/follow_notification = mode == SYNDIMATIC_FOLLOW_NOTIFY_ON || (mode == SYNDIMATIC_FOLLOW_NOTIFY_DEFAULT && holder.client.prefs?.syndimatic_follow_notifications)
		if(!follow_notification && !recipient.syndimatic_notifications)
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
				var/link = "byond://?src=[REF(program)];syndimatic_open="
				var/message
				if(follow_notification)
					message = "Новая публикация по подписке от [author_name]. <a href='[link]post;post=[id]'>Открыть публикацию</a>"
				else
					message = "Новая публикация от [author_name]. <a href='[link]feed'>Открыть ленту</a>"
				to_chat(holder, span_info("[icon2html(device, holder)] Syndimatic: [message]"))
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
	syndimatic_post_index_version++
	syndimatic_thumbnails -= id
	syndimatic_media -= id
	syndimatic_ranked_comments -= id
	var/author = post["author"]
	var/list/author_posts = syndimatic_posts_by_author[author]
	author_posts -= id
	if(!length(author_posts))
		syndimatic_posts_by_author -= author
	var/account = post["account"]
	if(account)
		var/list/account_posts = syndimatic_posts_by_account[account]
		account_posts -= id
		if(!length(account_posts))
			syndimatic_posts_by_account -= account
	else
		// Временная ветка удаления публикаций старого формата.
		syndimatic_legacy_posts -= id
	if(!delete_pda_cloud_photo("[SYNDIMATIC_POSTS][id].sav"))
		log_game("Syndimatic: не удалось удалить архив публикации [id].")
	return TRUE

/datum/controller/subsystem/persistence/proc/notify_syndimatic_viewers(datum/computer_file/program/syndimatic/source, post_id, profile_id, follow_account_id)
	for(var/datum/weakref/viewer_ref as anything in syndimatic_viewers.Copy())
		var/datum/computer_file/program/syndimatic/viewer = viewer_ref.resolve()
		if(!viewer)
			syndimatic_viewers -= viewer_ref
		else if(viewer == source)
			continue
		else if(follow_account_id)
			if(viewer.viewer_account_id == follow_account_id || (profile_id && viewer.profile_id == profile_id))
				viewer.update_syndimatic_view()
		else if(viewer.shows_syndimatic_change(post_id, profile_id))
			viewer.update_syndimatic_view(post_id, profile_id)

/proc/read_syndimatic_record(path)
	if(fexists(path))
		var/list/data = safe_json_decode(file2text(path), null)
		if(islist(data))
			return data
	var/backup = "[path].bak"
	if(fexists(backup))
		var/list/data = safe_json_decode(file2text(backup), null)
		if(islist(data))
			return data
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
#undef SYNDIMATIC_FOLLOWS
#undef SYNDIMATIC_BLOCKS_FILE
#undef SYNDIMATIC_LEGACY_ROUND_FILE
#undef SYNDIMATIC_LEGACY_POST_LIFETIME
#undef SYNDIMATIC_MEDIA_CACHE_SIZE
