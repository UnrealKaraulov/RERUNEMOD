#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <rm_api>
#include <fun>

new bool:g_invis[MAX_PLAYERS + 1] = {false,...};

public plugin_init()
{
	register_plugin("Invis_rune","1.1","Karaulov"); 
	rm_register_rune(rm_current_plugin_id(),"Невидимость","Делает игрока прозрачным когда он не атакует.",Float:{0.0,120.0,255.0}, "DEFAULT MODEL");
	register_event("Damage", "EVENT_Damage", "b", "2!0")
}

public rm_give_rune(id)
{
	g_invis[id] = true;
}

public rm_drop_rune(id)
{
	g_invis[id] = false;
	if (is_user_connected(id))
		set_user_rendering(id, kRenderFxNone, 255, 255, 255, kRenderNormal, 255)
}

public client_PostThink(id)
{
	if (g_invis[id] && is_user_connected(id))
		set_user_rendering(id, kRenderFxNone, 254, 254, 254, kRenderTransAlpha, 0)
}

public EVENT_Damage(id)
{ 	
	new iAttackerWeapon, iAttackerBody, iAttacker;
	if (is_user_connected(id))
	{
		iAttacker = get_user_attacker(id, iAttackerWeapon, iAttackerBody);
		if (is_user_connected(iAttacker) && iAttacker > 0 && iAttacker < 33)
		{
			new damage = read_data(2)
			if (damage > 0)
			{
				rm_base_drop_plugin( iAttacker );
			}
		}
	}
}

