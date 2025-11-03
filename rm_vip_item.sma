#include <amxmodx>
#include <amxmisc>
#include <rm_api>

new rune_model_id = -1;

new rune_name[] = "rm_vip_item_name";
new rune_descr[] = "rm_vip_item_desc";

new rune_model_path[64] = "models/rm_reloaded/w_vip.mdl";

new g_uVipFlags = 0;
new g_uAddedFlags[MAX_PLAYERS + 1];

new g_iCfgSpawnSecondsDelay = 0;

public plugin_init()
{
	register_plugin("RM_VIP_FLAG","2.0","Karaulov"); 
	
	new rune_flags[64] = "ab";
	/* Чтение конфигурации */
	rm_read_cfg_str(rune_name,"VIP_FLAGS",rune_flags,rune_flags,charsmax(rune_flags));
	
	g_uVipFlags = read_flags(rune_flags);
	
	if (g_uVipFlags == 0)
	{
		// Если флаг указан неправильно, эта строка завершит работу плагина с ошибкой.
		set_fail_state("NO VIP_FLAGS DETECTED ^"%s^"",rune_flags);
		return;
	}
	
	// Регистрация руны если все впорядке
	rm_register_rune(rune_name,rune_descr,Float:{255.0,255.0,255.0}, rune_model_path,_,rune_model_id);
	
	// Класс руны: предмет
	rm_base_use_rune_as_item( );

	// Максимальное количество предметов/рун которые могут быть на карте в одно время
	new max_count = 1;
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
	new currentFlags = get_user_flags(id);
	new missingFlags = g_uVipFlags & ~currentFlags;
	
	if (missingFlags == 0)
		return NO_RUNE_PICKUP_SUCCESS;
	
	set_user_flags(id, currentFlags | missingFlags);
	g_uAddedFlags[id] = missingFlags;
	
	return RUNE_PICKUP_SUCCESS;
}

public rm_drop_rune(id)
{
	new currentFlags = get_user_flags(id);
	set_user_flags(id, currentFlags & ~g_uAddedFlags[id]);
	g_uAddedFlags[id] = 0;	
}
