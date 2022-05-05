#include <amxmodx>
#include <amxmisc>
#include <rm_api>

new rune_name[] = "rm_silentstep_item_name";
new rune_descr[] = "rm_silentstep_item_desc";

new rune_model_id = -1;

new bool:g_bSilentStep[MAX_PLAYERS + 1] = {false,...};

public plugin_init()
{
	register_plugin("RM_SILENT","2.1","Karaulov"); 
	rm_register_rune(rune_name,rune_descr,Float:{255.0,255.0,255.0}, "models/rm_reloaded/w_botinok_2.mdl", _,rune_model_id);
	rm_base_use_rune_as_item( );
}

public plugin_precache()
{
	rune_model_id = precache_model("models/rm_reloaded/w_botinok_2.mdl");
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
	set_task(20.0,"reset_silent",id);
	return RUNE_PICKUP_SUCCESS;
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