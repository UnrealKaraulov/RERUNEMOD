#include <amxmodx>
#include <amxmisc>
#include <rm_api>

new rune_name[] = "rm_silentstep_item_name";
new rune_descr[] = "rm_silentstep_item_desc";

new rune_model_path[64] = "models/rm_reloaded/w_botinok_2.mdl";

new rune_model_id = -1;

new bool:g_bSilentStep[MAX_PLAYERS + 1] = {false,...};

new Float:g_fActiveTime = 20.0;

new g_iCfgSpawnSecondsDelay = 0;

public plugin_init()
{
	register_plugin("RM_SILENT","2.4","Karaulov"); 
	rm_register_rune(rune_name,rune_descr,Float:{255.0,255.0,255.0}, rune_model_path, _,rune_model_id);
	rm_base_use_rune_as_item( );
	
	/* Чтение конфигурации */
	new cost = 1000;
	rm_read_cfg_int(rune_name,"COST_MONEY",cost,cost);
	rm_base_set_rune_cost(cost);
	
	rm_read_cfg_flt(rune_name,"ACTIVE_SECONDS",g_fActiveTime,g_fActiveTime);

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
	if (g_bSilentStep[id])
	{
		return NO_RUNE_PICKUP_SUCCESS;
	}
	g_bSilentStep[id] = true;
	if (task_exists(id))
		remove_task(id);
	set_member(id,m_flTimeStepSound,999.0);
	set_task(g_fActiveTime + 1.0,"reset_silent",id);
	return RUNE_PICKUP_SUCCESS;
}

public rm_drop_rune(id)
{
	if (task_exists(id))
		remove_task(id);
	g_bSilentStep[id] = false;
}

public reset_silent(id)
{
	g_bSilentStep[id] = false;
	if (is_user_connected(id))
	{
		set_member(id,m_flTimeStepSound,0.0);
		if (is_user_alive(id))
			rm_base_drop_item_notice(id);
	}
}