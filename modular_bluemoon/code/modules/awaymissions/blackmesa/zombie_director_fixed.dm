// This is the corrected section for zombie_director.dm lines 227-248
// Replace the existing section with this content

				var/mob_type
				if(difficulty_level >= 4)
					// After trigger4, include acid spitter and charger in rotation
					var/spawn_roll = rand(1, 100)
					if(spawn_roll <= 40)
						mob_type = /mob/living/simple_animal/hostile/infected
					else if(spawn_roll <= 65)
						mob_type = /mob/living/simple_animal/hostile/infected/bruiser
					else if(spawn_roll <= 80)
						mob_type = /mob/living/simple_animal/hostile/infected/bruiser/alt
					else if(spawn_roll <= 95)
						mob_type = /mob/living/simple_animal/hostile/infected/acid_spitter
					else
						mob_type = /mob/living/simple_animal/hostile/infected/charger
				else
					// Before trigger4, only normal zombies and bruisers
					if(prob(70))
						mob_type = /mob/living/simple_animal/hostile/infected
					else
						mob_type = prob(50) ? /mob/living/simple_animal/hostile/infected/bruiser : /mob/living/simple_animal/hostile/infected/bruiser/alt
