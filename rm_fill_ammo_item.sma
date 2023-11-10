#include <amxmodx>
#include <amxmisc>
#include <rm_api>

new rune_model_id = -1;

new rune_name[] = "rm_fill_ammo_item_name";
new rune_descr[] = "rm_fill_ammo_item_desc";

new rune_model_path[64] = "models/w_weaponbox.mdl";

new g_iCfgSpawnSecondsDelay = 0;

public plugin_init()
{
	register_plugin("RM_AMMO","2.6","Karaulov"); 
	rm_register_rune(rune_name,rune_descr,Float:{255.0,255.0,255.0}, rune_model_path,_,rune_model_id);
	rm_base_use_rune_as_item( );
	
	/* Чтение конфигурации */
	new cost = 1100;
	rm_read_cfg_int(rune_name,"COST_MONEY",cost,cost);
	rm_base_set_rune_cost(cost);
	
	
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

public bool:ReloadWeapons(const pPlayer)
{
	new m_iActiveItem = get_member(pPlayer, m_pActiveItem);
	if(!m_iActiveItem || is_nullent(m_iActiveItem))
	{
		return false;
	}
	
	new iMaxClip = rg_get_iteminfo(m_iActiveItem, ItemInfo_iMaxClip);
	new iMaxAmmo = rg_get_iteminfo(m_iActiveItem, ItemInfo_iMaxAmmo1);
	
	if(iMaxClip == -1)
	{
		return false;
	}
	
	new iClip = rg_get_user_ammo(pPlayer,get_member(m_iActiveItem, m_iId));
	new iAmmo = rg_get_user_bpammo(pPlayer,get_member(m_iActiveItem, m_iId));
	
	if (iClip != iMaxClip || iMaxAmmo != iAmmo)
	{
		rg_instant_reload_weapons(pPlayer, m_iActiveItem);
		return true;
	}

	
	return false;
}

public rm_give_rune(id)
{
	if (!ReloadWeapons(id))
		return NO_RUNE_PICKUP_SUCCESS;
	return RUNE_PICKUP_SUCCESS;
}