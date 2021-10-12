#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <rm_api>
#include <fun>
#include <reapi>

new bool:g_invis[MAX_PLAYERS + 1] = {false,...};
const MovingBits = ( IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT );

public plugin_init()
{
	register_plugin("Invis_rune","1.1","Karaulov"); 
	rm_register_rune(rm_current_plugin_id(),"Невидимость","Игрок невидимый если не атакует.^nЧастично прозрачный при движении.",Float:{0.0,120.0,255.0}, "DEFAULT MODEL");
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "CPlayer_TakeDamage_Post", .post = true);
}

public rm_give_rune(id)
{
	g_invis[id] = true;
}

public rm_drop_rune(id)
{
	g_invis[id] = false;
	if (is_user_connected(id))
	{
		set_user_rendering(id, kRenderFxNone, 255, 255, 255, kRenderNormal, 255)
		new iFlags = entity_get_int( id, EV_INT_flags );
		if (iFlags & FL_NOTARGET)
		{
			entity_set_int( id, EV_INT_flags, iFlags & ~FL_NOTARGET )
		}
	}
}

public client_PostThink(id)
{
	if (g_invis[id] && is_user_connected(id))
	{
		new iFlags = entity_get_int( id, EV_INT_flags );
		if (!(iFlags & FL_NOTARGET))
		{
			entity_set_int( id, EV_INT_flags, iFlags | FL_NOTARGET )
		}
		if (entity_get_int(id, EV_INT_button) & MovingBits)
			set_user_rendering(id, kRenderFxNone, 254, 254, 254, kRenderTransAlpha, 40)
		else 
			set_user_rendering(id, kRenderFxNone, 254, 254, 254, kRenderTransAlpha, 0)
	}
}

public CPlayer_TakeDamage_Post(iVictim, iInflictor, iAttacker, Float:flDamage, iBitsDamageType)
{
    if (iAttacker > 0 && iAttacker < 33 && g_invis[iAttacker])
	{
		rm_base_drop_plugin( iAttacker );
	}
}

