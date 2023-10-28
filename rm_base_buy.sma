#include <amxmodx>
#include <amxmisc>
#include <rm_api>

public plugin_init()
{
	register_plugin("RM_BASE_BUY","1.0","Karaulov");
	register_concmd("give_rune", "fn_give_rune",ADMIN_RCON, "[player_id] [rune_name]");
	register_concmd("replace_rune", "fn_give_rune2",ADMIN_RCON, "[player_id] [rune_name]");
	register_concmd("buy_rune", "fn_buy_rune",ADMIN_ALL,"[rune_name]");
}

public fn_give_rune(id, level, cid)
{
	if (cmd_access(id, level, cid, 3))
	{
		new player_id[128];
		read_argv(1,player_id,charsmax(player_id));
		new rune_name[128];
		read_argv(2,rune_name,charsmax(rune_name));
		new rune_id = rm_get_rune_by_name(rune_name);
		if (rune_id != -1)
		{
			rm_give_rune_to_player(str_to_num(player_id),rune_id);
		}
	}
	return PLUGIN_HANDLED;
}

public fn_give_rune2(id, level, cid)
{
	if (cmd_access(id, level, cid, 3))
	{
		new player_id[128];
		read_argv(1,player_id,charsmax(player_id));
		new rune_name[128];
		read_argv(2,rune_name,charsmax(rune_name));
		new rune_id = rm_get_rune_by_name(rune_name);
		if (rune_id != -1)
		{
			rm_force_drop_rune(str_to_num(player_id));
			rm_give_rune_to_player(str_to_num(player_id),rune_id);
		}
	}
	
	return PLUGIN_HANDLED;
}

public fn_buy_rune(id, level, cid)
{
	if (cmd_access(id, level, cid, 2))
	{
		new rune_name[128];
		read_argv(1,rune_name,charsmax(rune_name));
		rm_buy_rune_by_name(id,rune_name);
	}
	return PLUGIN_HANDLED;
}

/*

<call>
plugin = rm_base_buy.amxx
name = Монетка GAMECMS
function = AES_GIVE_ITEM
points = 10
flags = rm_gamecms_money_item_name
days = 0

<call>
plugin = rm_base_buy.amxx
name = Руна невидимости
function = AddRune
points = 10
flags = rm_invis_rune_name
days = 0

*/

public AES_GIVE_ITEM(id, item[])
{
	rm_force_drop_rune(id);
	new rune_id = rm_get_rune_by_name(item);
	if (rune_id != -1)
	{
		return rm_give_rune_to_player(id,rune_id);
	}
	return false;
}

public AES_REPLACE_RUNE(id, rune[])
{
	new rune_id = rm_get_rune_by_name(rune);
	if (rune_id != -1)
	{
		rm_force_drop_rune(id);
		return rm_give_rune_to_player(id,rune_id);
	}
	return false;
}