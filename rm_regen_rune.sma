#include <amxmodx>
#include <amxmisc>
#include <rm_api>
#include <fun>

new Float:g_regen[MAX_PLAYERS + 1] = {0.0,...};

const MovingBits = ( IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT );

new rune_model_id = -1;

public plugin_init()
{
	register_plugin("RM_REGEN","2.0","Karaulov"); 
	rm_register_rune("Регенерация","Быстрое восстановление если игрок не двигается.",Float:{255.0,80.0,140.0}, "models/rm_reloaded/rune_pink.mdl", "rm_reloaded/regen.wav",rune_model_id);
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
				new Float:hp = get_entvar(id,var_health);
				if (hp < 150.0)
					set_entvar(id,var_health,floatclamp(hp+1.5,5.0,150.0));
				g_regen[id] = get_gametime();
			}
		}
		else
		{
			g_regen[id] = get_gametime();
		}
	}
}