/mob/living/silicon/robot/examine(mob/user)
	. = list("<span class='info'>Это [icon2html(src, user)] \a <EM>[src]</EM>, [chameleon_module() ? "инженерный" : module_to_ru_adjective(src.module.name)] юнит!")
	if(desc)
		. += "[desc]"

	var/obj/act_module = get_active_held_item()
	if(act_module)
		. += "В его манипуляторах [icon2html(act_module, user)] \a [act_module].\n"
	var/effects_exam = status_effect_examines()
	if(!isnull(effects_exam))
		. += effects_exam
	if (getBruteLoss())
		if (getBruteLoss() < maxHealth*0.5)
			. += "<span class='warning'>Он выглядит слегка повреждённым.</span>\n"
		else
			. += "<span class='warning'><B>Он сильно повреждён!</B></span>\n"
	if (getFireLoss() || getToxLoss())
		var/overall_fireloss = getFireLoss() + getToxLoss()
		if (overall_fireloss < maxHealth * 0.5)
			. += "<span class='warning'>Он выглядит слегка обгоревшим.</span>\n"
		else
			. += "<span class='warning'><B>Он сильно обгорел!</B></span>\n"
	if (health < -maxHealth*0.5)
		. += "<span class='warning'>Он вот-вот отключится.</span>\n"
	if (fire_stacks < 0)
		. += "<span class='warning'>Он вымок в воде.</span>\n"
	else if (fire_stacks > 0)
		. += "<span class='warning'>Он покрыт чем-то горючим.</span>\n"

	if(opened)
		. += "<span class='warning'>Люк техобслуживания открыт, [cell ? "вы видите [icon2html(cell, user)] [cell] внутри " : "батарея отсутствует"].\n</span>"
	else
		. += "Люк техобслуживания закрыт[locked ? "" : ", однако разблокирован"].\n"

	if(cell && cell.charge <= 0)
		. += "<span class='warning'>Индикатор батареи горит красным!</span>\n"

	if(is_servant_of_ratvar(src) && get_dist(user, src) <= 1 && !stat) //To counter pseudo-stealth by using headlamps
		. += "<span class='brass'>Его дисплей горит ярко-жёлтым цветом!</span>\n"

	switch(stat)
		if(CONSCIOUS)
			if(shell)
				. += "Видимо, это [deployed ? "активная" : "пустая"] оболочка ИИ.\n"
			else if(!client)
				. += "Позитронный мозг киборга не отвечает.\n" //afk
		if(UNCONSCIOUS)
			. += "<span class='warning'>Похоже, он временно отключён.</span>\n"
		if(DEAD)
			. += "<span class='deadsay'>Система критически повреждена. Требуется перезагрузка.</span>\n"

	if(LAZYLEN(.) > 1)
		.[2] = "<hr>[.[2]]"

	. += span_boldnotice("Профиль киборга: <a href='?src=\ref[src];cyborg_profile=1'>\[Осмотреть\]</a>")
	SEND_SIGNAL(src, COMSIG_PARENT_EXAMINE, usr, .)

	if(length(.) > 1)
		.[1] += "<br>"

	. += "</span>"

	. += ..()
