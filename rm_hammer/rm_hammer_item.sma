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

public plugin_init()
{
	register_plugin("RM_MJOLNIR","1.5","Karaulov");
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
}

public plugin_precache()
{
	/* Чтение конфигурации */
	rm_read_cfg_str(rune_name,"model",rune_model_path,rune_model_path,charsmax(rune_model_path));
	
	rune_model_id = precache_model(rune_model_path);
}

public client_putinserver(id)
{
	g_bHasmjolnir[id] = false;
	if (task_exists(id))
		remove_task(id);
}

public client_disconnected(id)
{
	g_bHasmjolnir[id] = false;
	if (task_exists(id))
		remove_task(id);
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
		set_dhudmessage(100, 150, 0, -1.0, 0.65, 0, 0.0, 0.55, 0.0, 0.0);
		show_dhudmessage(id, "HAMMER: [ ACTIVE ]");
	}
	else 
	{
		set_dhudmessage(255, 150, 0, -1.0, 0.65, 0, 0.0, 0.55, 0.0, 0.0);
		show_dhudmessage(id, "HAMMER: [  WAIT ]");
	}
		
	new iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum, "bch" );
	for( new i = 0; i < iNum; i++ )
	{
		new spec_id = iPlayers[ i ];
		new specTarget = get_entvar(spec_id, var_iuser2);
		if (specTarget == id)
		{
			if (get_gametime() - g_fStun_time[id] > g_fCooldown)
			{
				set_dhudmessage(100, 150, 0, -1.0, 0.65, 0, 0.0, 0.55, 0.0, 0.0);
				show_dhudmessage(id, "HAMMER: [ ACTIVE ]");
			}
			else 
			{
				set_dhudmessage(255, 150, 0, -1.0, 0.65, 0, 0.0, 0.55, 0.0, 0.0);
				show_dhudmessage(id, "HAMMER: [  WAIT ]");
			}
		}
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