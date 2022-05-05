#include <amxmodx>
#include <amxmisc>
#include <rm_api>
#include <hamsandwich>

new g_protection[MAX_PLAYERS + 1] = {0,...};

new rune_name[] = "rm_protect_rune_name";
new rune_descr[] = "rm_protect_rune_desc";

new rune_model_id = -1;

public plugin_init()
{
	register_plugin("RM_PROTECT","2.2","Karaulov"); 
	rm_register_rune(rune_name,rune_descr,Float:{255.0,0.0,0.0}, "models/rm_reloaded/rune_red.mdl", "rm_reloaded/protect.wav",rune_model_id);
	RegisterHam(Ham_TakeDamage, "player", "CPlayer_TakeDamage_Pre")
}

public plugin_precache()
{
	rune_model_id = precache_model("models/rm_reloaded/rune_red.mdl");
	if (file_exists("sound/rm_reloaded/protect.wav"))
	{
		precache_generic("sound/rm_reloaded/protect.wav");
	}
}

public rm_give_rune(id)
{
	g_protection[id] = 10;
	rm_base_highlight_player(id);
	rm_base_highlight_screen(id);
	if (task_exists(id))
		remove_task(id);
	set_task(1.0,"update_protect_state",id, _, _, "b");
}

public rm_drop_rune(id)
{
	g_protection[id] = false;	
	if (task_exists(id))
		remove_task(id);
}

public update_protect_state(id)
{
	set_dhudmessage(0, 255, 213, -1.0, 0.55, 0, 0.0, 0.0, 1.3, 0.0);
	show_dhudmessage(id, "CHARGE: [ %d / 10 ]", g_protection[id]);
}

public CPlayer_TakeDamage_Pre(iVictim, iInflictor, iAttacker, Float:flDamage, iDamageBits)
{
	if (is_real_player(iVictim) && g_protection[iVictim] > 0)
	{
		g_protection[iVictim]--;
		if (g_protection[iVictim] <= 0)
			rm_base_drop_rune( iVictim );
		return HAM_SUPERCEDE;
	}
	return HAM_IGNORED;
}

