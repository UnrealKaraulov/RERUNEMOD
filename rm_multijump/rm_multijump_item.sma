#include <amxmodx>
#include <amxmisc>
#include <rm_api>


new g_bHasMultiJump[MAX_PLAYERS + 1] = {0,...};


new rune_model_id = -1;

new rune_name[] = "rm_multijump_item_name";
new rune_descr[] = "rm_multijump_item_desc";

new rune_model_path[64] = "models/rm_reloaded/w_multijump.mdl";

new g_iMultiJumpCount = 10;

new g_iCfgSpawnSecondsDelay = 0;

public plugin_init()
{
	register_plugin("RM_JUMP","1.7","Karaulov");
	rm_register_dictionary("runemod_mj_item.txt");
	rm_register_rune(rune_name,rune_descr,Float:{0.0,255.0,0.0}, rune_model_path, _,rune_model_id);
	rm_base_use_rune_as_item( );
	
	RegisterHookChain(RG_CBasePlayer_Jump, "HC_CBasePlayer_Jump_Pre", .post = false);
	
	/* Чтение конфигурации */
	new cost = 4300;
	rm_read_cfg_int(rune_name,"COST_MONEY",cost,cost);
	rm_base_set_rune_cost(cost);
	
	
	/* Чтение конфигурации */
	rm_read_cfg_int(rune_name,"JUMPS",g_iMultiJumpCount,g_iMultiJumpCount);
	
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

public rm_drop_rune(id)
{
	g_bHasMultiJump[id] = 0;
	if (task_exists(id))
		remove_task(id);
}

public rm_give_rune(id)
{
	if (g_bHasMultiJump[id] > 0)
		return NO_RUNE_PICKUP_SUCCESS;
	if (task_exists(id))
		remove_task(id);
	g_bHasMultiJump[id] = g_iMultiJumpCount;
	set_task(0.5,"update_jump_state",id, _, _, "b");
	return RUNE_PICKUP_SUCCESS;
}

public update_jump_state(id)
{
	rm_show_dhud_message(id, DHUD_POS_ITEM3,{108, 209, 0},0.54,true,"JUMPS: [ %d / %d ]", g_bHasMultiJump[id],g_iMultiJumpCount);
}

public HC_CBasePlayer_Jump_Pre(id) 
{
	if (g_bHasMultiJump[id] > 0)
	{
		new iFlags = get_entvar(id,var_flags);
		if (iFlags & FL_WATERJUMP)
		{
			return HC_CONTINUE;
		}
		
		if (iFlags & FL_ONGROUND)
		{
			return HC_CONTINUE;
		}
		
		if (get_entvar(id,var_waterlevel) >= 2)
		{
			return HC_CONTINUE;
		}
		
		if (!(get_member(id,m_afButtonPressed) & IN_JUMP))
		{
			return HC_CONTINUE;
		}
		
		new Float:fVelocity[3];
		get_entvar(id, var_velocity, fVelocity);
		
		
		fVelocity[0] *= 1.25;
		fVelocity[1] *= 1.25;
		fVelocity[2] = 350.0;
		
		set_entvar(id, var_velocity, fVelocity);
		
	
		g_bHasMultiJump[id] -= 1;
		
		if (g_bHasMultiJump[id] == 0)
		{
			if (task_exists(id))
				remove_task(id);
			rm_base_drop_item_notice(id);
		}
		return HC_BREAK;
	}
	return HC_CONTINUE;
}