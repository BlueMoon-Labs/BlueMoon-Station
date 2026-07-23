/datum/http_request
	var/id
	var/in_progress = FALSE

	var/method
	var/body
	var/headers
	var/url
	/// If present response body will be saved to this file.
	var/output_file

	var/_raw_response

/datum/http_request/proc/prepare(method, url, body = "", list/headers, output_file)
	if (!length(headers))
		headers = ""
	else
		headers = json_encode(headers)

	src.method = method
	src.url = url
	src.body = body
	src.headers = headers
	src.output_file = output_file

/datum/http_request/proc/execute_blocking()
	_raw_response = rustg_http_request_blocking(method, url, body, headers, build_options())

/datum/http_request/proc/begin_async()
	if (in_progress)
		CRASH("Attempted to re-use a request object.")

	id = rustg_http_request_async(method, url, body, headers, build_options())

	if (isnull(text2num(id)))
		stack_trace("Proc error: [id]")
		_raw_response = "Proc error: [id]"
	else
		in_progress = TRUE

/datum/http_request/proc/build_options()
	if(output_file)
		return json_encode(list("output_filename"=output_file,"body_filename"=null))
	return null

/datum/http_request/proc/is_complete()
	if (isnull(id))
		return TRUE

	if (!in_progress)
		return TRUE

	var/r = rustg_http_check_request(id)

	if (r == RUSTG_JOB_NO_RESULTS_YET)
		return FALSE
	else
		_raw_response = r
		in_progress = FALSE
		return TRUE

/datum/http_request/proc/into_response()
	var/datum/http_response/R = new()

	try
		var/list/L = json_decode(_raw_response)
		R.status_code = L["status_code"]
		R.headers = L["headers"]
		R.body = L["body"]
	catch
		R.errored = TRUE
		R.error = _raw_response

	return R

/datum/http_response
	var/status_code
	var/body
	var/list/headers

	var/errored = FALSE
	var/error

/// Замена world.Export("http://...") для GET-запросов: world.Export исполняет запрос
/// на главном потоке и держит ВЕСЬ мир до ответа удалённого сервера или таймаута
/// (waitfor = FALSE не спасает - блок происходит внутри нативного вызова, до всякого
/// сна). Здесь запрос уходит в rustg, вызывающий прок спит на поллинге, мир тикает.
/// Возвращает /datum/http_response или null, если ответ не пришёл за timeout.
/proc/world_safe_http_get(url, timeout = 30 SECONDS)
	var/datum/http_request/request = new()
	request.prepare(RUSTG_HTTP_METHOD_GET, url)
	request.begin_async()
	var/deadline = world.time + timeout
	while(!request.is_complete())
		if(world.time > deadline)
			return null
		stoplag()
	return request.into_response()

/// Fire-and-forget вариант: вызывающий не ждёт (отцепляемся на первом сне), а ответ
/// всё равно добирается поллингом, чтобы rustg не копил завершённые джобы вечно.
/proc/world_safe_http_get_async(url)
	set waitfor = FALSE
	world_safe_http_get(url)
