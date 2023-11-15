#include <amxmodx>
#include <amxmisc>
#include <rm_api>

new bool:g_bHasmjolnir[MAX_PLAYERS + 1] = {false,...};
new bool:g_bHasstun[MAX_PLAYERS + 1] = {false,...};

new Float:g_vStunVelocity[MAX_PLAYERS + 1][3];
new Float:g_fStun_time[MAX_PLAYERS + 1] = {0.0,...};

new rune_model_id = -1;

new rune_name[] = "rm_mjolnir_item_name";
new rune_descr[] = "rm_mjolnir_item_desc";

new rune_model_path[64] = "models/rm_reloaded/w_mjolnir.mdl";

new Float:g_fCooldown = 3.0;

new g_iCfgSpawnSecondsDelay = 0;

public plugin_init()
{
	register_plugin("RM_MJOLNIR","1.6","Karaulov");
	rm_register_dictionary("runemod_mr_item.txt");
	rm_register_rune(rune_name,rune_descr,Float:{0.0,100.0,0.0}, rune_model_path, _,rune_model_id);
	rm_base_use_rune_as_item( );
	
	RegisterHookChain(RG_CSGameRules_FPlayerCanTakeDamage, "CSGameRules_FPlayerCanTakeDmg_post", .post = true)
	
	RegisterHookChain(RG_PM_Move, "PM_Move", .post =false);
	RegisterHookChain(RG_PM_AirMove, "PM_Move", .post =false);
	
	/* Чтение конфигурации */
	new cost = 7100;
	rm_read_cfg_int(rune_name,"COST_MONEY",cost,cost);
	rm_base_set_rune_cost(cost);
	
	/* Чтение конфигурации */
	rm_read_cfg_flt(rune_name,"COOLDOWN",g_fCooldown,g_fCooldown);
	
	// Максимальное количество предметов/рун которые могут быть на карте в одно время
	new max_count = 10;
	rm_read_cfg_int(rune_name,"MAX_COUNT_ON_MAP",max_count,max_count);
	rm_base_set_max_count( max_count );
	
	// Задержка между спавнами
	rm_read_cfg_int(rune_name,"DELAY_BETWEEN_NEXT_SPAWN",g_iCfgSpawnSecondsDelay,g_iCfgSpawnSecondsDelay);
}

new Float:flLastSpawnTime = 0.0;

public rm_spawn_rune(iEnt)
{
	if (floatround(floatabs(get_gametime() - flLastSpawnTime)) > g_iCfgSpawnSecondsDelay)
	{
		flLastSpawnTime = get_gametime();
		return SPAWN_SUCCESS;
	}
	
	return SPAWN_ERROR;
}

public plugin_precache()
{
	/* Чтение конфигурации */
	rm_read_cfg_str(rune_name,"model",rune_model_path,rune_model_path,charsmax(rune_model_path));
	
	rune_model_id = precache_model(rune_model_path);
}

public rm_give_rune(id)
{
	if (g_bHasmjolnir[id])
		return NO_RUNE_PICKUP_SUCCESS;
	if (task_exists(id))
		remove_task(id);
	g_bHasmjolnir[id] = true;
	set_task(0.5,"update_stun_state",id, _, _, "b");
	return RUNE_PICKUP_SUCCESS;
}

public rm_drop_rune(id)
{
	g_bHasmjolnir[id] = false;
	if (task_exists(id))
		remove_task(id);
}

public update_stun_state(id)
{
	if (get_gametime() - g_fStun_time[id] > g_fCooldown)
	{
		rm_show_dhud_message(id, DHUD_POS_ITEM1,{108, 209, 0},0.54,true,"HAMMER: [ ACTIVE ]");
	}
	else 
	{
		rm_show_dhud_message(id, DHUD_POS_ITEM1,{255, 178, 143},0.54,true,"HAMMER: [ RECHARGING ]");
	}
}

public CSGameRules_FPlayerCanTakeDmg_post(const pPlayer, const pAttacker)
{
	if (is_real_player(pAttacker) && g_bHasmjolnir[pAttacker] && GetHookChainReturn(ATYPE_INTEGER) > 0)
	{
		if (get_gametime() - g_fStun_time[pAttacker] > g_fCooldown)
		{
			if (is_real_player(pPlayer) && is_user_connected(pAttacker))
			{
				g_bHasstun[pPlayer] = true;
				velocity_by_aim(pAttacker, random_num(800,1200),g_vStunVelocity[pPlayer]);
				g_fStun_time[pAttacker] = get_gametime();
			}
		}
	}
	return HC_CONTINUE;
}

public PM_Move(const id)
{
	if ( is_real_player(id) && g_bHasstun[id] )
	{
		g_bHasstun[id] = false;
		new Float:fPunchAngles[3];
		fPunchAngles[0] = random_float(-180.0,180.0);
		fPunchAngles[1] = random_float(-180.0,180.0);
		fPunchAngles[2] = random_float(-180.0,180.0);
		set_pmove(pm_punchangle,fPunchAngles);
		g_vStunVelocity[id][2] = random_float(350.0,850.0);
		set_pmove(pm_velocity,g_vStunVelocity[id]);
		set_entvar(id,var_velocity,g_vStunVelocity[id])
	}
}