/// Учёт висящих нативных промптов (input()/alert()).
/// BYOND хранит промпт - и спящий фрейм прока вместе с ним - до ответа игрока,
/// ДАЖЕ если игрок отключился (переподключившимся диалоги показываются заново).
/// Такой фрейм пинит usr/src/локали невидимо для любых ref-сканов: это главный
/// подозреваемый в "внешних ссылок: 1, найдено 0" по обсерверам/new_player на проде.
/// Обёртки инкрементят счётчик на мобе; GC-отчёты (warnfail-лог, панель, итог
/// ref-скана) выводят его, опознавая класс держателя без гаданий.
///
/// Возвращает моба, на котором засчитан промпт - его же нужно передать в
/// end_native_prompt: за время диалога user может смениться (ключ ушёл в другое
/// тело), а фрейм пинит именно моба на момент открытия.
/proc/begin_native_prompt(user)
	var/mob/prompt_mob = user
	if(istype(user, /client))
		var/client/prompt_client = user
		prompt_mob = prompt_client.mob
	if(!istype(prompt_mob))
		return null
	prompt_mob.pending_native_prompts++
	return prompt_mob

/proc/end_native_prompt(mob/prompt_mob)
	if(istype(prompt_mob) && prompt_mob.pending_native_prompts > 0)
		prompt_mob.pending_native_prompts--
