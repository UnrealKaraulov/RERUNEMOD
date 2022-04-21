#include <amxmodx>
#include <amxmisc>
#include <rm_api>
#include <fun>

new Float:g_regen[MAX_PLAYERS + 1] = {0.0,...};

const MovingBits = ( IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT );

new rune_model_id = -1;

new max_hp_available_cvar;

public plugin_init()
{
	register_plugin("RM_REGEN","2.1","Karaulov"); 
	rm_register_rune("Регенерация","Быстрое восстановление если игрок не двигается.",Float:{255.0,80.0,140.0}, "models/rm_reloaded/rune_pink.mdl", "rm_reloaded/regen.wav",rune_model_id);
	max_hp_available_cvar = get_cvar_pointer("runemod_max_hp");
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
	g_regen[id] = 1.0;
	rm_base_highlight_player(id);
}

public rm_drop_rune(id)
{
	g_regen[id] = 0.0;
}


public client_PostThink(id)
{
	if (is_user_alive(id) && g_regen[id] > 0.0)
	{
		if (!(get_entvar(id, var_button) & MovingBits))
		{
			if( get_gametime() - g_regen[id] > 0.05 )
			{
				new Float:maxhp = get_pcvar_float(max_hp_available_cvar);
				new Float:hp = get_entvar(id,var_health);
				if (hp < maxhp)
					set_entvar(id,var_health,floatclamp(hp+1.5,5.0,maxhp));
				g_regen[id] = get_gametime();
			}
		}
		else
		{
			g_regen[id] = get_gametime();
		}
	}
}