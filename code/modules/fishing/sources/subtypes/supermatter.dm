/datum/fish_source/supermatter
	catalog_description = "Supermatter"
	background = "background_lavaland"
	radial_state = "fryer"
	overlay_state = "portal_fry"
	fish_table = list(
		/obj/item/fish/herring_nobilium = 25,
		/obj/item/fish/matter_ray = 15,
		/mob/living/basic/slime/pyro = 5,
		/obj/item/fish/flux_fish = 5,
	)
//	fish_counts = list(
//		/obj/item/fish/fryish = 10,
//		/obj/item/fish/fryish/fritterish = 4,
//		/obj/item/fish/fryish/nessie = 1,
//	)
//	fish_count_regen = list(
//		/obj/item/fish/fryish = 2 MINUTES,
//		/obj/item/fish/fryish/fritterish = 6 MINUTES,
//		/obj/item/fish/fryish/nessie = 22 MINUTES,
//	)
	fishing_difficulty = FISHING_DEFAULT_DIFFICULTY + 10

/datum/fish_source/supermatter/on_start_fishing(obj/item/fishing_rod/rod, mob/fisherman, atom/parent)
	. = ..()
	var/atom/atom_source = parent
	if(istype(rod.hook, /obj/item/fishing_hook/hypernob))
		to_chat(fisherman, span_notice("Your fishing hook falls into a crevice within the supermatter crystal."))
		return
	to_chat(fisherman, span_danger("The fishing rod turns to dust in a flash of energy and your arm with it!"))
	qdel(rod)
	var/obj/item/bodypart/dust_arm = fisherman.get_active_hand()
	dust_arm.dismember()
	qdel(dust_arm)
	playsound(parent, 'sound/effects/supermatter.ogg', 50, TRUE)
	radiation_pulse(atom_source, max_range = 3, threshold = 0.1, chance = 50)

/mob/living/basic/slime/pyro/Initialize(mapload, new_type = /datum/slime_type/red, new_life_stage = SLIME_LIFE_STAGE_ADULT)
	. = ..()
	var/turf/open/tile = get_turf(src)
	if(istype(tile))
		tile.atmos_spawn_air("[GAS_O2]=500;[GAS_PLASMA]=500;[TURF_TEMPERATURE(1000)]") //Make it hot and burny for the new slime
	src.set_enraged_behaviour()

/obj/item/fish/herring_nobilium
	name = "herring nobilium"
	fish_id = "herringnob"
	desc = "Fish coated in condensed hyper nobilium, a gas taht stops any chchemical reactions and thus saves this herring from perishing within folds of supermatter crystals."
	icon_state = "firefish"

/obj/item/fish/flux_fish
	name = "flux fish"
	fish_id = "fluxfish"
	desc = "Supermatter can't consume your body if you have no physical body to begin with. This fish is a small flux anomaly given life, handle with care!"
	icon_state = "firefish"
	fish_traits = list(
		/datum/fish_trait/inductive,)

/obj/item/fish/matter_ray
	name = "matter ray"
	fish_id = "matterray"
	desc = "Scientists are still unsure how this type of fish came to be and heated debates are held how it even survives within its natural habitat. Discavery of it has been however invaluable to research in field of RCDs and other devices using compressed matter as fuel."
	icon_state = "firefish"

//==============================traits=======================

/datum/fish_trait/inductive
	name = "Inductive"
	catalog_description = "This fish emits electromagnetic field that resonates with humanoid bodies to recharge any devices they might be carrying. Works even from within an aquarium."
	var/range = 10

/datum/fish_trait/inductive/apply_to_fish(obj/item/fish/fish)
	. = ..()
	RegisterSignal(fish, COMSIG_FISH_LIFE, PROC_REF(induce))

/datum/fish_trait/inductive/proc/induce(obj/item/fish/source, seconds_per_tick)
	SIGNAL_HANDLER
	var/list/batteries = list()
	for(var/mob/living/target in range(source.loc, range)) // range
		playsound(target, 'sound/effects/supermatter.ogg', 50, TRUE)
		for(var/obj/item/stock_parts/power_store/C in target.get_all_cells())
			if(C.charge < C.maxcharge)
				batteries += C
	if(batteries.len)
		var/obj/item/stock_parts/power_store/ToCharge = pick(batteries)
		ToCharge.charge += min(ToCharge.maxcharge - ToCharge.charge, ToCharge.maxcharge/10) //10% of the cell, or to maximum.

/datum/fish_trait/inductive/apply_to_mob(mob/living/basic/mob)
	. = ..()
	RegisterSignal(mob, COMSIG_LIVING_HANDLE_BREATHING, PROC_REF(on_non_stasis_life))

/datum/fish_trait/inductive/proc/on_non_stasis_life(mob/living/basic/mob, seconds_per_tick = SSMOBS_DT)
	SIGNAL_HANDLER
	var/list/batteries = list()
	for(var/mob/living/target in range(mob, range)) //range
		playsound(target, 'sound/effects/supermatter.ogg', 50, TRUE)
		for(var/obj/item/stock_parts/power_store/C in target.get_all_cells())
			if(C.charge < C.maxcharge)
				batteries += C
	if(batteries.len)
		var/obj/item/stock_parts/power_store/ToCharge = pick(batteries)
		ToCharge.charge += min(ToCharge.maxcharge - ToCharge.charge, ToCharge.maxcharge/10) //10% of the cell, or to maximum.
