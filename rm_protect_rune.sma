#include <amxmodx>
#include <amxmisc>
#include <rm_api>
#include <hamsandwich>

new g_protection[MAX_PLAYERS + 1] = {0,...};

new Float:g_fProtection_time[MAX_PLAYERS + 1] = {0.0,...};

new rune_name[] = "rm_protect_rune_name";
new rune_descr[] = "rm_protect_rune_desc";

new rune_model_id = -1;

new const MAX_PROTECTION_CHARGE = 7;

public plugin_init()
{
	register_plugin("RM_PROTECT","2.6","Karaulov"); 
	rm_register_rune(rune_name,rune_descr,Float:{255.0,0.0,0.0}, "models/rm_reloaded/rune_red.mdl", "rm_reloaded/protect.wav",rune_model_id);
	RegisterHookChain(RG_CSGameRules_FPlayerCanTakeDamage, "CSGameRules_FPlayerCanTakeDmg", .post = false)
	
	rm_base_set_rune_cost(6000);
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
	g_protection[id] = MAX_PROTECTION_CHARGE;
	rm_base_highlight_player(id);
	rm_base_highlight_screen(id);
	if (task_exists(id))
		remove_task(id);
	set_task(1.0,"update_protect_state",id, _, _, "b");
}

public rm_drop_rune(id)
{
	g_protection[id] = 0;	
	if (task_exists(id))
		remove_task(id);
}

public update_protect_state(id)
{
	set_dhudmessage(0, 255, 213, -1.0, 0.55, 0, 0.0, 1.05, 0.0, 0.0);
	show_dhudmessage(id, "CHARGE: [ %d / %d ]", g_protection[id],MAX_PROTECTION_CHARGE);
	
	new iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum, "bch" );
	for( new i = 0; i < iNum; i++ )
	{
		new spec_id = iPlayers[ i ];
		new specTarget = get_entvar(spec_id, var_iuser2);
		if (specTarget == id)
		{
			set_dhudmessage(0, 255, 213, -1.0, 0.55, 0, 0.0, 1.05, 0.0, 0.0);
			show_dhudmessage(spec_id, "CHARGE: [ %d / %d ]", g_protection[id],MAX_PROTECTION_CHARGE);
		}
	}
}


public CSGameRules_FPlayerCanTakeDmg(const pPlayer, const pAttacker)
{
	if (is_real_player(pPlayer) && g_protection[pPlayer] > 0)
	{
		if (get_gametime() - g_fProtection_time[pPlayer] > 0.3)
		{
			g_protection[pPlayer]--;
			if (g_protection[pPlayer] <= 0)
				rm_base_drop_rune( pPlayer );
			g_fProtection_time[pPlayer] = get_gametime();
		}
		SetHookChainReturn(ATYPE_INTEGER, false);
		return HC_BREAK;
	}
	return HC_CONTINUE;
}
