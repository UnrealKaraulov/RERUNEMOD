// Для работы требуется https://github.com/Giferns/HealthNade/ 

#include <amxmodx>
#include <rm_api>
#include <healthnade>


new item_name[] = "rm_healthnade_item_name";
new item_descr[] = "rm_healthnade_item_desc";

new item_model_id = -1;

new item_model_path[64] = "models/reapi_healthnade/w_healthnade.mdl";
new item_sound_path[64] = "sound/weapons/reapi_healthnade/heal.wav";

new g_iCfgSpawnSecondsDelay = 0;

public plugin_init() 
{
	// Регистрация плагина
	register_plugin("RM_HEALTHNADE_ITEM", "1.0", "Karaulov");
	// Регистрация словаря для runemod/предмета
	rm_register_dictionary("runemod_healthnade_item.txt");
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

	item_model_id = precache_model(item_model_path);
	if (file_exists(item_sound_path,true))
	{
		precache_generic(item_sound_path);
	}
}

// Выдача healthnade
public rm_give_rune(id)
{
	//HealthNade_GiveNade(id) > 0 срабатывает как надо
	if (HealthNade_HasNade(id))
		return NO_RUNE_PICKUP_SUCCESS;
	HealthNade_GiveNade(id, 1);
	return HealthNade_HasNade(id) ? RUNE_PICKUP_SUCCESS : NO_RUNE_PICKUP_SUCCESS;
}