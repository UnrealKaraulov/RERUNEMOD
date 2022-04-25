#include <amxmodx>
#include <amxmisc>
#include <rm_api>

new bool:g_invis[MAX_PLAYERS + 1] = {false,...};
const MovingBits = ( IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT );

new rune_model_id = -1;

public plugin_init()
{
	register_plugin("RM_INVIS","2.2","Karaulov"); 
	rm_register_rune("Heвидимocть","Игpoк нeвидимый ecли нe aтaкyeт.^nЧacтичнo пpoзpaчный пpи движeнии.",Float:{99.0, 197.0, 218.0}, "models/rm_reloaded/rune_sky.mdl", "rm_reloaded/invis.wav", rune_model_id);
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "CPlayer_TakeDamage_Post", .post = true);
}

public plugin_precache()
{
	rune_model_id = precache_model("models/rm_reloaded/rune_sky.mdl");
	
	if (file_exists("sound/rm_reloaded/invis.wav"))
	{
		precache_generic("sound/rm_reloaded/invis.wav");
	}
}

public rm_give_rune(id)
{
	g_invis[id] = true;
	rm_base_highlight_screen(id);
	if (task_exists(id))
		remove_task(id);
	set_task(0.1,"update_invis_state",id, _, _, "b");
}

public rm_drop_rune(id)
{
	g_invis[id] = false;
	if (task_exists(id))
		remove_task(id);
	if (is_user_connected(id))
	{
		rg_set_rendering(id);
		new iFlags = get_entvar( id, var_flags );
		if (iFlags & FL_NOTARGET)
		{
			set_entvar( id, var_flags, iFlags - FL_NOTARGET );
		}
	}
}

// Таск срабатывает 10 раз в секунду. Если игрок держит нажатой клавишу движения, становится частично видимым.
public update_invis_state(id)
{
	if ( is_real_player(id) && g_invis[id] )
	{
		new iFlags = get_entvar( id, var_flags );
		if (!(iFlags & FL_NOTARGET))
		{
			set_entvar( id, var_flags, iFlags + FL_NOTARGET )
		}
		if (get_entvar(id, var_button) & MovingBits)
			rg_set_rendering(id, kRenderFxNone, kRenderTransAlpha, Float: {255.0, 255.0, 255.0}, 40.0)
		else 
			rg_set_rendering(id, kRenderFxNone, kRenderTransAlpha, Float: {255.0, 255.0, 255.0}, 0.0)
	}
}

public CPlayer_TakeDamage_Post(iVictim, iInflictor, iAttacker, Float:flDamage, iBitsDamageType)
{
    if (is_real_player(iAttacker) && g_invis[iAttacker])
	{
		rm_base_drop_rune( iAttacker );
	}
}