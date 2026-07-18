// Публикация новости дёргает newsAlert() на КАЖДОМ ньюскастере станции синхронно в
// Topic публикатора (say + playsound на каждый - ~300мс на новость при сотне машин).
// Теперь озвучка гейтится по наличию игроков рядом (SSspatial_grid), но лампочка
// оповещения обязана работать всегда - её и проверяем в безлюдном CI.

/datum/unit_test/newscaster_alert_without_audience/Run()
	var/obj/machinery/newscaster/caster = allocate(/obj/machinery/newscaster)
	caster.newsAlert("Тестовый канал")
	TEST_ASSERT(caster.alert, "newsAlert обязан включить лампочку оповещения даже без слушателей рядом")
