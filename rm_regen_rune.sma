#include <amxmodx>
#include <amxmisc>
#include <rm_api>

const MovingBits = ( IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT );

new rune_model_id = -1;

new rune_name[] = "rm_regen_rune_name";
new rune_descr[] = "rm_regen_rune_desc";

new rune_model_path[64] = "models/rm_reloaded/rune_pink.mdl";
new rune_sound_path[64] = "sound/rm_reloaded/regen.wav";

new Float:g_fRegenSpeedInSec = 20.0;

new Float:g_fMaxHP = 150.0;

public plugin_init()
{
	register_plugin("RM_REGEN","2.6","Karaulov"); 
	rm_register_rune(rune_name,rune_descr,Float:{255.0,80.0,140.0}, rune_model_path, rune_sound_path,rune_model_id);
	
	/* Чтение конфигурации */
	new cost = 5200;
	rm_read_cfg_int(rune_name,"COST_MONEY",cost,cost);
	rm_base_set_rune_cost(cost);
	
	rm_read_cfg_flt("GENERAL","MAXIMUM_HP",g_fMaxHP,g_fMaxHP);
	rm_read_cfg_flt(rune_name,"REGEN_IN_SECOND",g_fRegenSpeedInSec,g_fRegenSpeedInSec);
	
	g_fRegenSpeedInSec /= 10.0;
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
	rm_base_highlight_player(id);
	rm_base_highlight_screen(id);
	if (task_exists(id))
		remove_task(id);
	set_task(0.1,"regen_think",id, _, _, "b");
}

public rm_drop_rune(id)
{
	if (task_exists(id))
		remove_task(id);
}

// Регенерировать игрока и держать минимум 20хп 10 раз в секунду.
public regen_think(id)
{
	if (!(get_entvar(id, var_button) & MovingBits))
	{
		new Float:maxhp = g_fMaxHP;
		new Float:hp = get_entvar(id,var_health);
		if (hp < maxhp)
			set_entvar(id,var_health,floatclamp(hp+g_fRegenSpeedInSec,20.0,maxhp));
	}
}