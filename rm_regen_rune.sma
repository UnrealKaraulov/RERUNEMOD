#include <amxmodx>
#include <amxmisc>
#include <rm_api>

const MovingBits = ( IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT );

new rune_model_id = -1;

new max_hp_available_cvar;

public plugin_init()
{
	register_plugin("RM_REGEN","2.5","Karaulov"); 
	rm_register_rune("rm_regen_rune_name","rm_regen_rune_desc",Float:{255.0,80.0,140.0}, "models/rm_reloaded/rune_pink.mdl", "rm_reloaded/regen.wav",rune_model_id);
	max_hp_available_cvar = get_cvar_pointer("runemod_max_hp");
	
	rm_base_set_rune_cost(6300);
}

public plugin_precache()
{
	rune_model_id = precache_model("models/rm_reloaded/rune_pink.mdl");
	if (file_exists("sound/rm_reloaded/regen.wav"))
	{
		precache_generic("sound/rm_reloaded/regen.wav");
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
		new Float:maxhp = get_pcvar_float(max_hp_available_cvar);
		new Float:hp = get_entvar(id,var_health);
		if (hp < maxhp)
			set_entvar(id,var_health,floatclamp(hp+3.0,20.0,maxhp));
	}
}