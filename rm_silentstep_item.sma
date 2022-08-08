#include <amxmodx>
#include <amxmisc>
#include <rm_api>

new rune_name[] = "rm_silentstep_item_name";
new rune_descr[] = "rm_silentstep_item_desc";

new rune_model_path[64] = "models/rm_reloaded/w_botinok_2.mdl";

new rune_model_id = -1;

new bool:g_bSilentStep[MAX_PLAYERS + 1] = {false,...};

new Float:g_fActiveTime = 20.0;

public plugin_init()
{
	register_plugin("RM_SILENT","2.3","Karaulov"); 
	rm_register_rune(rune_name,rune_descr,Float:{255.0,255.0,255.0}, rune_model_path, _,rune_model_id);
	rm_base_use_rune_as_item( );
	
	/* Чтение конфигурации */
	new cost = 1000;
	rm_read_cfg_int(rune_name,"COST_MONEY",cost,cost);
	rm_base_set_rune_cost(cost);
	
	rm_read_cfg_flt(rune_name,"ACTIVE_SECONDS",g_fActiveTime,g_fActiveTime);
}

public plugin_precache()
{
	/* Чтение конфигурации */
	rm_read_cfg_str(rune_name,"model",rune_model_path,rune_model_path,charsmax(rune_model_path));
	
	rune_model_id = precache_model(rune_model_path);
}

public client_putinserver(id)
{
	if (task_exists(id))
		remove_task(id);
	g_bSilentStep[id] = false;
}

public client_disconnected(id)
{
	if (task_exists(id))
		remove_task(id);
	g_bSilentStep[id] = false;
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