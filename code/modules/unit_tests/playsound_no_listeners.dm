/// playsound() обязан выйти РАНЬШЕ, чем займёт звуковой канал в SSsounds, если
/// в радиусе слышимости нет ни одного слушателя. Перепись датумов раунда 10060
/// (Delta, 3.5 часа без единого подключившегося игрока) насчитала 1.6 млн /sound
/// за раунд, ~127 штук в секунду: все они строились в playsound(), занимали
/// канал и умирали, не дойдя ни до одного клиента.
///
/// Прибор наблюдения - курсор случайных каналов SSsounds.channel_random_low:
/// random_available_channel() двигает его на каждом вызове, и это единственная
/// снаружи видимая улика того, что playsound() дошёл до выделения канала.
/// Тест не спит ни разу, поэтому сверять этот глобальный счётчик на равенство
/// безопасно: мир однопоточный и без сна никто другой его не подвинет.
/datum/unit_test/playsound_no_listeners
	/// Марионетка, которую во второй фазе кладём в канал CLIENTS спатиал-грида
	var/mob/living/carbon/human/listener

/datum/unit_test/playsound_no_listeners/Run()
	var/turf/source = run_loc_floor_bottom_left
	listener = allocate(/mob/living/carbon/human, source)

	// Фаза 1: моб на месте, но в канале CLIENTS его нет - слушателей ноль.
	var/list/clients_before = SSspatial_grid.orthogonal_range_search(source, SPATIAL_GRID_CONTENTS_TYPE_CLIENTS, SOUND_RANGE)
	TEST_ASSERT_EQUAL(length(clients_before), 0, "на арене теста уже есть мобы в канале CLIENTS - предыдущий тест не убрал за собой, замер бессмысленен")

	var/channel_cursor = SSsounds.channel_random_low
	playsound(source, 'sound/machines/ping.ogg', 50, FALSE)
	TEST_ASSERT_EQUAL(SSsounds.channel_random_low, channel_cursor, "playsound() занял звуковой канал, хотя слушателей в радиусе нет")

	// Фаза 2: тот же турф, тот же звук, изменена ровно одна переменная -
	// марионетка зарегистрирована в канале CLIENTS, слушатель существует.
	listener.enable_client_mobs_in_contents()
	var/list/clients_after = SSspatial_grid.orthogonal_range_search(source, SPATIAL_GRID_CONTENTS_TYPE_CLIENTS, SOUND_RANGE)
	TEST_ASSERT(length(clients_after) > length(clients_before), "марионетка не попала в канал CLIENTS - тест не проверяет путь со слушателем")

	playsound(source, 'sound/machines/ping.ogg', 50, FALSE)
	TEST_ASSERT_NOTEQUAL(SSsounds.channel_random_low, channel_cursor, "playsound() не занял канал при живом слушателе - ранний выход срабатывает слишком рано")

/datum/unit_test/playsound_no_listeners/Destroy()
	// Уборка в Destroy(), а не в хвосте Run(): провалившийся TEST_ASSERT выходит
	// из Run() немедленно и оставил бы марионетку в гриде следующим тестам.
	listener?.clear_important_client_contents()
	listener = null
	return ..()
