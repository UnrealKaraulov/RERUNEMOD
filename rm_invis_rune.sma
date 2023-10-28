#include <amxmodx>
#include <amxmisc>
#include <rm_api>

new bool:g_invis[MAX_PLAYERS + 1] = {false,...};
const MovingBits = ( IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT );

new rune_model_id = -1;

new rune_name[] = "rm_invis_rune_name";
new rune_descr[] = "rm_invis_rune_desc";

new rune_model_path[64] = "models/rm_reloaded/rune_sky.mdl";
new rune_sound_path[64] = "sound/rm_reloaded/invis.wav";


public plugin_init()
{
	register_plugin("RM_INVIS","2.6","Karaulov"); 
	rm_register_rune(rune_name,rune_descr,Float:{99.0, 197.0, 218.0}, rune_model_path, rune_sound_path, rune_model_id);
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "CPlayer_TakeDamage_Post", .post = true);
	
	/* Чтение конфигурации */
	new cost = 8500;
	rm_read_cfg_int(rune_name,"COST_MONEY",cost,cost);
	rm_base_set_rune_cost(cost);
	
	// Максимальное количество предметов/рун которые могут быть на карте в одно время
	new max_count = 10;
	rm_read_cfg_int(rune_name,"MAX_COUNT_ON_MAP",max_count,max_count);
	rm_base_set_max_count( max_count );
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