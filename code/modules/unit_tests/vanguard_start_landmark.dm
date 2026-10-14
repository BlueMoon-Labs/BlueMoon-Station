/// Точка появления Авангарда находится по названию должности.
/datum/unit_test/vanguard_start_landmark

/datum/unit_test/vanguard_start_landmark/Run()
	var/obj/effect/landmark/start/expeditor/landmark = allocate(/obj/effect/landmark/start/expeditor)
	var/datum/job/expeditor/job = SSjob.GetJobType(/datum/job/expeditor)
	TEST_ASSERT_NOTNULL(job, "Нет должности /datum/job/expeditor")
	TEST_ASSERT_EQUAL(job.get_default_roundstart_spawn_point(), landmark, "Должность [job.title] не находит лендмарк [landmark.name]")
