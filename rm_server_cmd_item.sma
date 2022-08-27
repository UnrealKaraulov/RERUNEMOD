#include <amxmodx>
#include <amxmisc>
#include <rm_api>

#define MAX_SERVER_CMD_ITEMS 64
#define MAX_SERVER_CMD_LEN 1024

new rune_name[] = "rm_servercmd_item_name";
new rune_descr[] = "rm_servercmd_item_desc";

new rune_default_model[] = "models/w_weaponbox.mdl";
new rune_default_severcmd[] = "amx_say NAME:[%username%] PID:[%pid%] ID:[%userid%] IP:[%userip%] STEAM:[%authid%]";

new rune_model_path[MAX_SERVER_CMD_ITEMS][64];
new rune_model_id[MAX_SERVER_CMD_ITEMS];
new rune_rune_id[MAX_SERVER_CMD_ITEMS];
new rune_servercmd[MAX_SERVER_CMD_ITEMS][MAX_SERVER_CMD_LEN];

new servercmd_count = 0;

new player_auth[MAX_PLAYERS+1][64];
new player_name[MAX_PLAYERS+1][64];
new player_userid[MAX_PLAYERS+1][64];
new player_ip[MAX_PLAYERS+1][64];
new player_pid[MAX_PLAYERS+1][64];

public plugin_init()
{
	register_plugin("RM_SERVERCMD","1.0","Karaulov"); 
	// Предупредить движок что это предмет а не руна
	rm_base_use_rune_as_item( );
}

public plugin_precache()
{	
	rm_read_cfg_int(rune_name,"SERVERCMD_COUNT",1,servercmd_count);
	if (servercmd_count > MAX_SERVER_CMD_ITEMS)
	{
		servercmd_count = MAX_SERVER_CMD_ITEMS;
	}
	for(new i = 0; i < servercmd_count; i++)
	{
		new tmpCmdVar[64];
		new tmpCmdNAME[256];
		new tmpCmdDESCR[256];
		
		formatex(tmpCmdVar,charsmax(tmpCmdVar),"SERVERCMD%d_MODEL",i+1);
		rm_read_cfg_str(rune_name,tmpCmdVar,rune_default_model,rune_model_path[i],charsmax(rune_model_path[]));
		
		rune_model_id[i] = precache_model(rune_model_path[i]);
		
		formatex(tmpCmdVar,charsmax(tmpCmdVar),"SERVERCMD%d_NAME",i+1);
		rm_read_cfg_str(rune_name,tmpCmdVar,rune_name,tmpCmdNAME,charsmax(tmpCmdNAME));
		
		formatex(tmpCmdVar,charsmax(tmpCmdVar),"SERVERCMD%d_DESCR",i+1);
		rm_read_cfg_str(rune_name,tmpCmdVar,rune_descr,tmpCmdDESCR,charsmax(tmpCmdDESCR));
		
		new rune_id = rm_register_rune(tmpCmdNAME,tmpCmdDESCR,Float:{255.0,255.0,255.0}, rune_model_path[i],_,rune_model_id[i]);
		rune_rune_id[i] = rune_id;
		
		new cost = 0; // 0 знач незя купить по умолчанию!
		formatex(tmpCmdVar,charsmax(tmpCmdVar),"SERVERCMD%d_COST",i+1);
		rm_read_cfg_int(rune_name,tmpCmdVar,0,cost);
		rm_base_set_rune_cost_by_rune_id(rune_id,cost);
		
		formatex(tmpCmdVar,charsmax(tmpCmdVar),"SERVERCMD%d_CMD",i+1);
		rm_read_cfg_str(rune_name,tmpCmdVar,rune_default_severcmd,rune_servercmd[i],charsmax(rune_servercmd[]));
		
	}
}

public client_putinserver(id)
{
	get_user_name(id,player_name[id],charsmax(player_name[]));
	get_user_ip(id,player_ip[id],charsmax(player_ip[]),1);
	get_user_authid(id,player_auth[id],charsmax(player_auth[]));
	formatex(player_userid[id],charsmax(player_userid[]),"%d",get_user_userid(id));
	formatex(player_pid[id],charsmax(player_pid[]),"%d",id);
}

/*
* Вызывается когда игрок поднимает руну
*
* @param id				Номер игрока
* @param ent			Руна или 0 если нет руны
* @param rune_id		Номер руны
* 
* @return RUNE_PICKUP_SUCCESS/NO_RUNE_PICKUP_SUCCESS или ничего
*/

public rm_give_rune(id,ent,rune_id)
{
	new tmpCmd[MAX_SERVER_CMD_LEN];
	copy(tmpCmd,charsmax(tmpCmd),rune_servercmd[rune_id]);
	replace_string(tmpCmd,charsmax(tmpCmd), "%username%", player_name[id], false);
	replace_string(tmpCmd,charsmax(tmpCmd), "%userid%", player_userid[id], false);
	replace_string(tmpCmd,charsmax(tmpCmd), "%pid%", player_pid[id], false);
	replace_string(tmpCmd,charsmax(tmpCmd), "%userip%", player_ip[id], false);
	replace_string(tmpCmd,charsmax(tmpCmd), "%authid%", player_auth[id], false);
	server_cmd("%s",tmpCmd);
}
