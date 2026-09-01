// Отдельное окно справочника по атмосу.
//
// До этого справочник был доступен ровно из одного места - приложения AtmoZphere
// на КПК, - то есть попадался на глаза только тому, кто и так знал, что он
// существует. Инженеру у консоли и атмос-технику с газоанализатором в руках он
// был не виден вообще.
//
// Датум глобальный и без хоста осознанно: справочник ничему не принадлежит, и
// консоль, анализатор и КПК открывают ровно один и тот же текст. Заводить
// ui_interact на каждой поверхности значило бы копировать одно и то же четыре
// раза и однажды разойтись в формулировках.

/datum/atmos_handbook

/datum/atmos_handbook/ui_state(mob/user)
	// Книга, а не пульт: справочник не завязан на машину, поэтому и права на
	// него не зависят от того, дотягивается ли игрок до консоли.
	return GLOB.always_state

/datum/atmos_handbook/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(ui)
		return
	ui = new(user, src, "AtmosHandbook", "Справочник по атмосферным системам")
	ui.open()

/datum/atmos_handbook/ui_static_data(mob/user)
	return return_atmos_handbooks()

GLOBAL_DATUM_INIT(atmos_handbook, /datum/atmos_handbook, new)

/// Открывает справочник. Точки входа зовут только это, чтобы окно всюду было
/// одним и тем же.
/proc/open_atmos_handbook(mob/user)
	if(!user?.client)
		return FALSE
	GLOB.atmos_handbook.ui_interact(user)
	return TRUE
