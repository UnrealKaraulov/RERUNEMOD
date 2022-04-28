#include <amxmodx>
#include <amxmisc>
#include <rm_api>

new rune_model_id = -1;

public plugin_init()
{
	register_plugin("RM_AMMO","2.3","Karaulov"); 
	rm_register_rune("rm_fill_ammo_item_name","rm_fill_ammo_item_desc",Float:{255.0,255.0,255.0}, "models/w_weaponbox.mdl",_,rune_model_id);
	rm_base_use_rune_as_item( );
}

public plugin_precache()
{
	rune_model_id = precache_model("models/w_weaponbox.mdl");
}

public bool:ReloadWeapons(const pPlayer)
{
	new m_iActiveItem = get_member(pPlayer, m_pActiveItem);
	if(!m_iActiveItem || is_nullent(m_iActiveItem))
	{
		return false
	}
	
	new iMaxClip = rg_get_iteminfo(m_iActiveItem, ItemInfo_iMaxClip);
	new iMaxAmmo = rg_get_iteminfo(m_iActiveItem, ItemInfo_iMaxAmmo1);
	
	if(iMaxClip == -1)
	{
		return false;
	}
	
	new iClip = rg_get_user_ammo(pPlayer,get_member(m_iActiveItem, m_iId));
	new iAmmo = rg_get_user_bpammo(pPlayer,get_member(m_iActiveItem, m_iId));
	
	if (iClip != iMaxClip || iMaxAmmo != iAmmo)
	{
		rg_instant_reload_weapons(pPlayer, m_iActiveItem);
		return true;
	}

	
	return false;
}

public rm_give_rune(id)
{
	if (!ReloadWeapons(id))
		return NO_RUNE_PICKUP_SUCCESS;
	return RUNE_PICKUP_SUCCESS;
}