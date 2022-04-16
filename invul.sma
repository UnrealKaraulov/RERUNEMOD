#include <amxmodx>
#include <reapi>

public plugin_init()
{
	register_plugin("PROTECT ALL","1.1","Karaulov"); 
	RegisterHookChain(RG_CSGameRules_FPlayerCanTakeDamage, "CSGameRules_FPlayerCanTakeDmg", .post = false)
}

public CSGameRules_FPlayerCanTakeDmg(const pPlayer, const pAttacker)
{
	SetHookChainReturn(ATYPE_INTEGER, false)
	return HC_SUPERCEDE
}
