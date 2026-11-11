/// Сколько ждать ответа адреса ресурсов.
#define RESOURCE_PROBE_TIMEOUT (20 SECONDS)
/// Архив меньше этой доли локального .rsc - почти наверняка от другой сборки или битый.
#define RESOURCE_PROBE_MIN_ARCHIVE_RATIO 0.3
/// Имя ресурсного файла сборки рядом с .dmb.
#define RESOURCE_PROBE_LOCAL_RSC "tgstation.rsc"
/// Начало вердикта живого адреса.
#define RESOURCE_PROBE_OK "ок"

/**
 * Проверка адресов, которые сервер раздаёт клиентам: внешний архив ресурсов (EXTERNAL_RSC_URLS) и CDN ассетов (ASSET_CDN_URL).
 * Мёртвый архив не виден ни в одной ошибке: клиент молча тянет каждый ресурс по игровому сокету, и эту работу BYOND делает в главном потоке мира.
 * Пишет в asset.log по строке на адрес с вердиктом, плохие адреса - ещё в лог мира и админам.
 */
/proc/probe_client_resource_hosts()
	set waitfor = FALSE
	// length() файла берёт размер с диска, не читая 650 МБ .rsc в память
	var/local_rsc_size = fexists(RESOURCE_PROBE_LOCAL_RSC) ? length(file(RESOURCE_PROBE_LOCAL_RSC)) : 0
	var/list/rsc_urls = CONFIG_GET(keyed_list/external_rsc_urls)
	var/list/problems = list()
#if PRELOAD_RSC != 0
	log_asset("РЕСУРСЫ: PRELOAD_RSC [PRELOAD_RSC] - внешний архив не используется, клиенты получают ресурсы с сервера.")
#else
	if(!length(rsc_urls))
		log_asset("РЕСУРСЫ: EXTERNAL_RSC_URLS пуст - клиенты получают ресурсы с игрового сервера по требованию.")
	for(var/url in rsc_urls)
		var/list/result = resource_probe_head(url)
		var/verdict = resource_probe_verdict(result, TRUE, local_rsc_size)
		log_asset("РЕСУРСЫ: архив [url] - [verdict]")
		if(!resource_probe_verdict_ok(verdict))
			problems += "архив [url] - [verdict]"
#endif
	if(istype(SSassets.transport, /datum/asset_transport/webroot))
		var/probe_url
		for(var/asset_name in SSassets.cache)
			var/datum/asset_cache_item/item = SSassets.cache[asset_name]
			if(istype(item) && !item.legacy && !length(item.namespace))
				probe_url = SSassets.transport.get_asset_url(asset_name, item)
				break
		if(probe_url)
			var/list/result = resource_probe_head(probe_url)
			var/verdict = resource_probe_verdict(result, FALSE, 0)
			log_asset("РЕСУРСЫ: CDN ассетов [probe_url] - [verdict]")
			if(!resource_probe_verdict_ok(verdict))
				problems += "CDN ассетов [probe_url] - [verdict]"
	report_resource_probe_problems(problems)

/// HEAD-запрос через rustg без блокировки мира. Список с ключами code, length, type, modified, error.
/proc/resource_probe_head(url)
	var/datum/http_request/request = new()
	request.prepare(RUSTG_HTTP_METHOD_HEAD, url)
	request.begin_async()
	var/deadline = world.time + RESOURCE_PROBE_TIMEOUT
	while(!request.is_complete())
		if(world.time > deadline)
			return list("error" = "нет ответа за [RESOURCE_PROBE_TIMEOUT / 10] с")
		stoplag()
	var/datum/http_response/response = request.into_response()
	if(response.errored)
		return list("error" = copytext_char("[response.error]", 1, 200))
	var/list/headers = list()
	for(var/header in response.headers)
		headers[lowertext("[header]")] = response.headers[header]
	return list(
		"code" = response.status_code,
		"length" = text2num(headers["content-length"]),
		"type" = headers["content-type"],
		"modified" = headers["last-modified"],
	)

/// Строка для лога по ответу resource_probe_head(). `archive` - ждём zip с .rsc внутри, `local_rsc_size` - размер .rsc сборки (0 - неизвестен).
/proc/resource_probe_verdict(list/result, archive, local_rsc_size)
	if(result["error"])
		return "НЕДОСТУПЕН: [result["error"]]"
	var/code = result["code"]
	var/size = result["length"]
	var/content_type = "[result["type"]]"
	var/list/facts = list("код [code]")
	if(!isnull(size))
		facts += "[round(size / (1024 * 1024), 0.1)] МБ"
	if(length(content_type))
		facts += content_type
	if(result["modified"])
		facts += "изменён [result["modified"]]"
	if(local_rsc_size)
		facts += "локальный .rsc [round(local_rsc_size / (1024 * 1024), 0.1)] МБ"
	var/summary = jointext(facts, ", ")
	if(code != 200)
		return "НЕДОСТУПЕН ([summary])"
	if(archive && findtext(content_type, "text/html"))
		return "ОТДАЁТ HTML ВМЕСТО АРХИВА ([summary])"
	if(archive && local_rsc_size && !isnull(size) && size < local_rsc_size * RESOURCE_PROBE_MIN_ARCHIVE_RATIO)
		return "АРХИВ ПОДОЗРИТЕЛЬНО МАЛ ([summary])"
	return "[RESOURCE_PROBE_OK] ([summary])"

/proc/resource_probe_verdict_ok(verdict)
	return findtext(verdict, "[RESOURCE_PROBE_OK] (") == 1

/// Плохие адреса ресурсов - в лог мира и админам. При инициализации мира админов в игре ещё нет: тогда сообщение ждёт старта раунда.
/proc/report_resource_probe_problems(list/problems)
	if(!length(problems))
		return
	for(var/problem in problems)
		log_world("РЕСУРСЫ: [problem]")
	var/message = "Адреса ресурсов для клиентов не в порядке: [jointext(problems, "; ")]. Подробности в asset.log."
	if(SSticker?.HasRoundStarted())
		message_admins(message)
		return
	new /datum/resource_probe_report(message)

/// Держит сообщение о плохих адресах ресурсов до старта раунда.
/datum/resource_probe_report
	var/message

/datum/resource_probe_report/New(message)
	src.message = message
	RegisterSignal(SSticker, COMSIG_TICKER_ROUND_STARTING, PROC_REF(on_round_starting))

/datum/resource_probe_report/Destroy()
	UnregisterSignal(SSticker, COMSIG_TICKER_ROUND_STARTING)
	return ..()

/datum/resource_probe_report/proc/on_round_starting(datum/source)
	SIGNAL_HANDLER
	message_admins(message)
	qdel(src)

#undef RESOURCE_PROBE_TIMEOUT
#undef RESOURCE_PROBE_MIN_ARCHIVE_RATIO
#undef RESOURCE_PROBE_LOCAL_RSC
#undef RESOURCE_PROBE_OK
