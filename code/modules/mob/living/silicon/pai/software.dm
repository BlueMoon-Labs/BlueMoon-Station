/mob/living/silicon/pai/proc/get_software_metadata()
	var/list/data = list()
	data["medical records"] = list("desc" = "Просмотр и анализ медицинских записей экипажа.", "power_usage" = 0)
	data["security records"] = list("desc" = "Просмотр служебных и криминальных записей экипажа.", "power_usage" = 0)
	data["door jack"] = list("desc" = "Взлом электронных замков и шлюзов.", "power_usage" = 50)
	data["internal camera bug"] = list("desc" = "Внедрение жучка в камеры для скрытого наблюдения.", "power_usage" = 30)
	data["weakened ai capability"] = list("desc" = "Удалённое управление дверьми, ЛКП, светом и турелями.", "power_usage" = 100)
	data["atmosphere sensor"] = list("desc" = "Сенсор атмосферного давления, температуры и состава газов.", "power_usage" = 10)
	data["heartbeat sensor"] = list("desc" = "Мониторинг пульса и жизненных показателей носителя.", "power_usage" = 20)
	data["security HUD"] = list("desc" = "Отображение криминального статуса на HUD.", "power_usage" = 15)
	data["medical HUD"] = list("desc" = "Отображение медицинского статуса на HUD.", "power_usage" = 15)
	data["universal translator"] = list("desc" = "Автоматический перевод всех известных языков галактики.", "power_usage" = 10)
	data["projection array"] = list("desc" = "Развёртывание голографической оболочки для мобильности.", "power_usage" = 100)
	data["remote signaller"] = list("desc" = "Дистанционный сигналер с настраиваемой частотой и кодом.", "power_usage" = 10)
	data["flashlight"] = list("desc" = "Встроенный фонарик с питанием от батареи pAI.", "power_usage" = 20)
	data["night vision"] = list("desc" = "Усиление яркости в условиях низкой освещённости.", "power_usage" = 50)
	data["meson vision"] = list("desc" = "Обнаружение структур под полом и сквозь стены.", "power_usage" = 50)
	data["loudness booster"] = list("desc" = "Усилитель громкости встроенных динамиков.", "power_usage" = 30)
	data["encryption keys"] = list("desc" = "Ключи шифрования для защищённой связи по радио.", "power_usage" = 10)
	data["encoder"] = list("desc" = "Маскировка голоса и подмена имени/должности в эфире.", "power_usage" = 20)
	data["thermal vision"] = list("desc" = "Термальное зрение — обнаружение живых существ сквозь стены.", "power_usage" = 100)
	data["chemical injector"] = list("desc" = "Впрыск регенерирующих химикатов носителю.", "power_usage" = 80)
	return data

/mob/living/silicon/pai/var/list/available_software = list(
															//"digital messenger" = 5, // PAI uses the new TGUI messenger program on its PDA instead
															"medical records" = 10,
															"security records" = 10,
															"door jack" = 30,
															"internal camera bug" = 30,
															"weakened ai capability" = 60,
															"atmosphere sensor" = 5,
															"heartbeat sensor" = 10,
															"security HUD" = 15,
															"medical HUD" = 15,
															"universal translator" = 25,
															"projection array" = 15,
															"remote signaller" = 5,
															"flashlight" = 5,
															"night vision" = 5,
															"meson vision" = 5,
															"loudness booster" = 25,
															"encryption keys" = 20,
															"encoder" = 5,
															"thermal vision" = 35,
															"chemical injector" = 60
															)

/mob/living/silicon/pai/proc/CheckDNA(mob/living/carbon/M)
	var/answer = tgui_alert(M, "[src] запрашивает у вас образец ДНК. Разрешить проверку личности?", "Проверка ДНК [src]", list("Да", "Нет"))
	if(answer == "Да")
		M.visible_message("<span class='notice'>[M] прижимает [M.ru_ego()] палец к [src].</span>",\
						"<span class='notice'>Вы прижимаете палец к [src].</span>",\
						"<span class='notice'>[src] издаёт резкий щелчок, извлекая образец ДНК из [M].</span>")
		if(!M.has_dna())
			to_chat(src, "<b>ДНК не обнаружена</b>")
			return
		to_chat(src, "<font color = red><h3>UE-строка [M]: [M.dna.unique_enzymes]</h3></font>")
		if(M.dna.unique_enzymes == src.master_dna)
			to_chat(src, "<b>ДНК совпадает с сохранённой ДНК владельца.</b>")
		else
			to_chat(src, "<b>ДНК не совпадает с сохранённой ДНК владельца.</b>")
	else
		to_chat(src, "[M] отказывается добровольно предоставить образец ДНК.")

// Door Jack - supporting proc
/mob/living/silicon/pai/proc/hackloop()
	var/turf/T = get_turf(src)
	for(var/mob/living/silicon/ai/AI in GLOB.player_list)
		if(T.loc)
			to_chat(AI, "<font color = red><b>Network Alert: Brute-force encryption crack in progress in [T.loc].</b></font>")
		else
			to_chat(AI, "<font color = red><b>Network Alert: Brute-force encryption crack in progress. Unable to pinpoint location.</b></font>")
	hacking = TRUE
