#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <rm_api>
#include <fun>
#include <reapi>

new Float:g_regen[MAX_PLAYERS + 1] = {0.0,...};
const MovingBits = ( IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT );

public plugin_init()
{
	register_plugin("Regen_rune","1.1","Karaulov"); 
	rm_register_rune(rm_current_plugin_id(),"Регенерация","Быстрое восстановление если игрок не двигается.",Float:{255.0,0.0,120.0}, _,"rm_reloaded/regen.wav");
}

public plugin_precache()
{
	if (file_exists("sound/rm_reloaded/regen.wav"))
	{
		precache_sound("rm_reloaded/regen.wav");
	}
}

public rm_give_rune(id)
{
	g_regen[id] = 1.0;
}

public rm_drop_rune(id)
{
	g_regen[id] = 0.0;
}


public client_PostThink(id)
{
	if (is_user_connected(id) && g_regen[id] > 0.0)
	{
		if (!(entity_get_int(id, EV_INT_button) & MovingBits))
		{
			if( get_gametime() - g_regen[id] > 1.0)
			{
				new hp = get_user_health(id);
				if (hp < 100)
					set_user_health(id,clamp(hp+10,0,100));
				g_regen[id] = get_gametime();
			}
		}
	}
}