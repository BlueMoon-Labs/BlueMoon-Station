/// "strings list not found: strings/ambitions/supply.json, index=Bitrunner": у должности нет своего ключа в файле амбиций отдела.
/datum/unit_test/ambition_every_job_has_department_ambition/Run()
	var/datum/mind/employee = new /datum/mind("ambition_test")
	var/datum/ambition_objective/ambition = new(employee)
	ambition.chance_generic_ambition = 0
	ambition.chance_other_departament_ambition = 100

	var/list/jobs = GLOB.command_positions | GLOB.engineering_positions | GLOB.law_positions | GLOB.medical_positions 		| GLOB.science_positions | GLOB.supply_positions | GLOB.civilian_positions | GLOB.security_positions | GLOB.nonhuman_positions
	for(var/job in jobs)
		employee.assigned_role = job
		for(var/attempt in 1 to 5)
			TEST_ASSERT(istext(ambition.get_job_departament_ambition()), "[job] остался без амбиции своего отдела")

	employee.assigned_role = "Bitrunner"
	TEST_ASSERT(istext(ambition.get_random_ambition()), "битраннер получает амбицию")
	qdel(employee)
