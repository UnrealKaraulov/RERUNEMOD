#include <amxmodx>
#include <amxmisc>
#include <rm_api>

new rune_model_id = -1;

new rune_name[] = "rm_re_portal_item_name";
new rune_descr[] = "rm_re_portal_item_desc";

new rune_model_path[64] = "models/portal_gun/w_portalgun.mdl";
new rune_sound_path[64] = "sound/portal_gun/portal_b.wav";

native pg_chat_command(bool:enabled);
native pg_player_give(id);
native pg_player_drop(id);
native pg_is_has_player(id);

public plugin_init()
{
	register_plugin("RM_INVIS","2.7","Karaulov"); 
	rm_register_dictionary("runemod_re_portal_item.txt");
	rm_register_rune(rune_name,rune_descr,Float:{99.0, 197.0, 218.0}, rune_model_path, rune_sound_path, rune_model_id);
	rm_base_use_rune_as_item( );
	
	/* Чтение конфигурации */
	new cost = 8500;
	rm_read_cfg_int(rune_name,"COST_MONEY",cost,cost);
	rm_base_set_rune_cost(cost);
	
	// Максимальное количество предметов/рун которые могут быть на карте в одно время
	new max_count = 10;
	rm_read_cfg_int(rune_name,"MAX_COUNT_ON_MAP",max_count,max_count);
	rm_base_set_max_count( max_count );
	
	pg_chat_command(false);
}

public plugin_precache()
{	
	/* Чтение конфигурации */
	rm_read_cfg_str(rune_name,"model",rune_model_path,rune_model_path,charsmax(rune_model_path));
	rm_read_cfg_str(rune_name,"sound",rune_sound_path,rune_sound_path,charsmax(rune_sound_path));

	rune_model_id = precache_model(rune_model_path);
	
	if (file_exists(rune_sound_path,true))
	{
		precache_generic(rune_sound_path);
	}
}

public rm_give_rune(id)
{
	if (pg_is_has_player(id))
	{
		return PICKUP_ERROR;
	}
	pg_player_give(id);
	return PICKUP_SUCCESS;
}

public rm_drop_rune(id)
{
	pg_player_drop(id);
}
