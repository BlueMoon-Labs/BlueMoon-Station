/datum/round_event_control/meteor_wave/major_dust
	name = "Major Space Dust"
	typepath = /datum/round_event/meteor_wave/major_dust
	weight = 10
	category = EVENT_CATEGORY_SPACE

/datum/round_event/meteor_wave/major_dust
	wave_name = "space dust"

/datum/round_event/meteor_wave/major_dust/announce(fake)
	if(!fake)
		notify_market()
	var/reason = pick(
		"Станция проходит сквозь облако мусора, ожидается незначительное повреждение внешнего оборудования и кострукций.",
		"Подразделение супероружия NanoTrasen проводит испытания нового прототипа [pick("метафизической","ониксовой","взрывной","супер-коллизионной","реактивной")] \
		[pick("пушки","артиллерии","боярки","крейсерной обшивки","\[REDACTED\]")], \
		ожидается небольшой мусор.",
		"Соседняя станция бросает в вас камни. (Возможно, они устали от ваших сообщений.)")
	if(prob(50))
		priority_announce(pick(reason), "Опасность Столкновения", has_important_message = prob(75))
	else
		print_command_report("[pick(reason)]", "Опасность Столкновения")
