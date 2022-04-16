#include <amxmodx>
#include <amxmisc>
#include <rm_api>
#include <fun>

new bool:g_invis[MAX_PLAYERS + 1] = {false,...};
const MovingBits = ( IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT );

new rune_model_id = -1;

public plugin_init()
{
	register_plugin("Invis_rune","1.2","Karaulov"); 
	rm_register_rune("Heвидимocть","Игpoк нeвидимый ecли нe aтaкyeт.^nЧacтичнo пpoзpaчный пpи движeнии.",Float:{99.0, 197.0, 218.0}, "models/rm_reloaded/rune_sky.mdl", "rm_reloaded/invis.wav", rune_model_id);
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "CPlayer_TakeDamage_Post", .post = true);
}

public plugin_precache()
{
	if(file_exists("models/rm_reloaded/rune_sky.mdl"))
	{
		rune_model_id = precache_model("models/rm_reloaded/rune_sky.mdl");
	}
	if (file_exists("sound/rm_reloaded/invis.wav"))
	{
		precache_generic("sound/rm_reloaded/invis.wav");
	}
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
			set_entvar( id, var_flags, iFlags - FL_NOTARGET )
		}
	}
}

public client_PostThink(id)
{
	if ( is_real_player(id) && g_invis[id] )
	{
		new iFlags = entity_get_int( id, EV_INT_flags );
		if (!(iFlags & FL_NOTARGET))
		{
			set_entvar( id, var_flags, iFlags + FL_NOTARGET )
		}
		if (entity_get_int(id, EV_INT_button) & MovingBits)
			set_user_rendering(id, kRenderFxNone, 254, 254, 254, kRenderTransAlpha, 40)
		else 
			set_user_rendering(id, kRenderFxNone, 254, 254, 254, kRenderTransAlpha, 0)
	}
}

public CPlayer_TakeDamage_Post(iVictim, iInflictor, iAttacker, Float:flDamage, iBitsDamageType)
{
    if (is_real_player(iAttacker) && g_invis[iAttacker])
	{
		rm_base_drop_plugin( iAttacker );
	}
}