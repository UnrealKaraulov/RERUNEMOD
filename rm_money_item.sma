#include <amxmodx>
#include <amxmisc>
#include <rm_api>

new rune_model_id = -1;
new mp_maxmoney;

new rune_name[] = "rm_money_item_name";
new rune_descr[] = "rm_money_item_desc";

new rune_model_path[64] = "models/rm_reloaded/w_dollar.mdl";

new g_iMinMoney = 5000;
new g_iMaxMoney = 5000;

new g_iCfgSpawnSecondsDelay = 0;

public plugin_init()
{
	register_plugin("RM_CASH","2.5","Karaulov"); 
	rm_register_rune(rune_name,rune_descr,Float:{255.0,255.0,255.0}, rune_model_path,_,rune_model_id);
	// Класс руны: предмет
	rm_base_use_rune_as_item( );
	
	mp_maxmoney = get_cvar_pointer("mp_maxmoney");
	
	
	/* Чтение конфигурации */
	rm_read_cfg_int(rune_name,"MIN_MONEY",g_iMinMoney,g_iMinMoney);
	rm_read_cfg_int(rune_name,"MAX_MONEY",g_iMaxMoney,g_iMaxMoney);

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
	if (get_member(id,m_iAccount) < get_pcvar_num(mp_maxmoney))
	{
		rg_add_account(id,clamp(get_member(id,m_iAccount)+random_num(g_iMinMoney,g_iMaxMoney),0,get_pcvar_num(mp_maxmoney)),AS_SET);
		return RUNE_PICKUP_SUCCESS;
	}
	else 
		return NO_RUNE_PICKUP_SUCCESS;
}
