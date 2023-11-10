#include <amxmodx>
#include <amxmisc>
#include <rm_api>

new rune_name[] = "rm_random_item";
new rune_descr[] = "rm_random_item_desc";

new g_CurrentRuneID = 0;

new g_iCfgSpawnSecondsDelay = 0;

public plugin_init()
{
	register_plugin("RM_RANDOM_ITEM","1.1","Karaulov"); 
	rm_register_rune(rune_name,rune_descr,Float:{255.0,255.0,255.0});
	rm_base_use_rune_as_item( );
	
	g_CurrentRuneID = rm_get_rune_by_name(rune_name);

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
		rm_set_rune_num(iEnt,g_CurrentRuneID);
		set_task(1.0, "update_random_item", iEnt, _, _, "b");
		flLastSpawnTime = get_gametime();
		return SPAWN_SUCCESS;
	}
	
	return SPAWN_ERROR;
}

public update_random_item( ent )
{
	if (is_nullent( ent ))
	{
		remove_task( ent );
		return;
	}
	new rune_id = rm_get_rune_runeid(ent);
	new rune_max_id = rm_get_runes_count();
	if (rune_id >= 0 && rune_id < rune_max_id)
	{
		for(new i = 0; i < rune_max_id; i++)
		{
			if ( i != g_CurrentRuneID && rm_is_rune_item(i) )
			{
				rm_base_swap_rune_id(ent,i);
				return;
			}
		}
	}
}

public rm_remove_rune(ent)
{
	remove_task(ent);
}

public rm_give_rune(id)
{
	return NO_RUNE_PICKUP_SUCCESS;
}

