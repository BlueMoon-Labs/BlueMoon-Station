/**
 * Досборка ассетов после инита.
 *
 * Батчёвые спрайтшиты встают в очередь вместо того, чтобы собираться на старте
 * мира: пока игроки сидят в лобби, rust-g досчитывает листы в своих потоках, а МК
 * занят остальным. Если ассет запросят раньше, чем дойдёт очередь, get_asset_datum
 * дособерёт его на месте (см. ensure_ready).
 *
 * Порт из /tg/station.
 */
SUBSYSTEM_DEF(asset_loading)
	name = "Asset Loading"
	priority = FIRE_PRIORITY_ASSETS
	flags = SS_NO_INIT
	runlevels = RUNLEVEL_LOBBY|RUNLEVELS_DEFAULT
	/// Ассеты, ждущие сборки.
	var/list/datum/asset/generate_queue = list()
	/// Сколько задач сейчас считает rust-g.
	var/assets_generating = 0
	/// Длина очереди на прошлом проходе - по ней видно, что очередь только что опустела.
	var/last_queue_len = 0

/datum/controller/subsystem/asset_loading/stat_entry(msg)
	msg = "Q:[length(generate_queue)] Gen:[assets_generating]"
	return ..()

/datum/controller/subsystem/asset_loading/fire(resumed)
	while(length(generate_queue))
		var/datum/asset/to_load = generate_queue[length(generate_queue)]

		last_queue_len = length(generate_queue)
		generate_queue.len--

		to_load.queued_generation()

		if(MC_TICK_CHECK)
			return

	// Очередь только что опустела - отдаём память, занятую кэшем иконок в rust.
	if(last_queue_len && !length(generate_queue) && !assets_generating)
		last_queue_len = 0
		rustg_iconforge_cleanup()

/datum/controller/subsystem/asset_loading/proc/queue_asset(datum/asset/queue)
#ifdef DO_NOT_DEFER_ASSETS
	stack_trace("[queue.type] встал в очередь на отложенную сборку, хотя отложенная сборка выключена")
#endif
	generate_queue |= queue

/datum/controller/subsystem/asset_loading/proc/dequeue_asset(datum/asset/queue)
	generate_queue -= queue
