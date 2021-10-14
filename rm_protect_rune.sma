#include <amxmodx>
#include <amxmisc>
#include <rm_api>
#include <fun>
#include <hamsandwich>

new g_protection[MAX_PLAYERS + 1] = {0,...};

public plugin_init()
{
	register_plugin("Protect_rune","1.1","Karaulov"); 
	rm_register_rune("3aщитa","Дaeт вpeмeннyю зaщитy oт пoлyчeния ypoнa.",Float:{255.0,64.0,0.0}, _,"rm_reloaded/protect.wav");
	RegisterHam(Ham_TakeDamage, "player", "CPlayer_TakeDamage_Pre")
}

public plugin_precache()
{
	if (file_exists("sound/rm_reloaded/protect.wav"))
	{
		precache_sound("rm_reloaded/protect.wav");
	}
}

public rm_give_rune(id)
{
	g_protection[id] = 3;
	rm_base_highlight_player(id);
}

public rm_drop_rune(id)
{
	g_protection[id] = false;
}

public CPlayer_TakeDamage_Pre(iVictim, iInflictor, iAttacker, Float:flDamage, iDamageBits)
{
	if (is_real_player(iVictim) && g_protection[iVictim] > 0)
	{
		g_protection[iVictim]--;
		if (g_protection[iVictim] <= 0)
			rm_base_drop_plugin( iVictim );
		return HAM_SUPERCEDE;
	}
	return HAM_IGNORED;
}

