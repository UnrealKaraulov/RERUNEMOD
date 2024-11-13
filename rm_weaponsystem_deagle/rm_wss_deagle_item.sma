#include <amxmodx>
#include <rm_api>

new item_name[] = "rm_wss_deagle_item_name";
new item_descr[] = "rm_wss_deagle_item_desc";

new item_wss_name[] = "vip_deagle";

new item_model_id = -1;

new item_model_path[64] = "models/w_deagle.mdl";
new item_sound_path[64] = "sound/items/nvg_on.wav";

new g_iCfgSpawnSecondsDelay = 0;

public plugin_init() 
{
	// Регистрация плагина
	register_plugin("RM_WSS_DEAGLE_ITEM", "1.0", "Karaulov");
	// Регистрация словаря для runemod/предмета
	rm_register_dictionary("runemod_wss_deagle_item.txt");
	// Регистрация руны
	rm_register_rune(item_name,item_descr, Float:{0.0,100.0,200.0}, item_model_path , item_sound_path, item_model_id);
	// Указать что руна является предметом
	rm_base_use_rune_as_item( );
	
	/* Чтение конфигурации */
	// Максимальное количество предметов/рун которые могут быть на карте в одно время
	new max_count = 3;
	rm_read_cfg_int(item_name,"MAX_COUNT_ON_MAP",max_count,max_count);
	rm_base_set_max_count( max_count );
	// Задержка между спавнами
	rm_read_cfg_int(item_name,"DELAY_BETWEEN_NEXT_SPAWN",g_iCfgSpawnSecondsDelay,g_iCfgSpawnSecondsDelay);
}

new Float:flLastSpawnTime = 0.0;

public rm_spawn_rune(iEnt)
{
	if (floatround(floatabs(get_gametime() - flLastSpawnTime)) > g_iCfgSpawnSecondsDelay)
	{
		new Float:flOrigin[3];
		get_entvar(iEnt,var_origin,flOrigin);
		flOrigin[2]+=8;
		set_entvar(iEnt, var_origin,flOrigin);
		set_entvar(iEnt, var_avelocity,Float:{0.0,125.0,0.0});
		set_entvar(iEnt, var_renderamt, 220.0);
		set_entvar(iEnt, var_rendermode, kRenderTransAdd);
		set_entvar(iEnt, var_renderfx, kRenderFxGlowShell);
		flLastSpawnTime = get_gametime();
		return SPAWN_SUCCESS;
	}
	
	return SPAWN_ERROR;
}

public plugin_precache()
{
	/* Чтение конфигурации */
	rm_read_cfg_str(item_name,"model",item_model_path,item_model_path,charsmax(item_model_path));
	rm_read_cfg_str(item_name,"sound",item_sound_path,item_sound_path,charsmax(item_sound_path));
	rm_read_cfg_str(item_name,"item_wss_name",item_wss_name,item_wss_name,charsmax(item_wss_name));

	item_model_id = precache_model(item_model_path);
	if (file_exists(item_sound_path,true))
	{
		precache_generic(item_sound_path);
	}
}

// Разовая выдача wss-оружия указанному игроку
// return		индекс энтити оружия в случае успеха, иначе 0
native wss_give_weapon(pPlayer, const szWssClassname[], GiveType:iGiveType = GT_APPEND);

// Позволяет проверить, имеет ли игрок указанное wss-оружие
// return		индекс энтити оружия, либо 0
native wss_user_has_weapon(pPlayer, const szWssClassname[]);

// Выдача Deagle
public rm_give_rune(id)
{
	if (wss_user_has_weapon(id,item_wss_name))
		return NO_RUNE_PICKUP_SUCCESS;
	wss_give_weapon(id,item_wss_name,GT_APPEND);
	return wss_user_has_weapon(id,item_wss_name) ? RUNE_PICKUP_SUCCESS : NO_RUNE_PICKUP_SUCCESS;
}