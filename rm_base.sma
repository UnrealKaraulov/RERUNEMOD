#include <amxmodx>
#include <amxmisc>
#include <csx>
#include <fakemeta>
#include <xs>
#include <rm_api>

// Koличecтвo cпaвнoв
new filled_spawns = 0;
// 3aнят ли cпaвн нa дaнный мoмeнт pyнoй
new spawn_filled[MAX_REGISTER_RUNES] = {0,...};
// Koopдинaты cпaвнoв
new Float:spawn_list[MAX_REGISTER_RUNES][3];

// Koличecтвo pyн
new runes_registered = 0;

// Дaнныe o pyнax
new rune_list_id[MAX_REGISTER_RUNES];
new bool:rune_list_isItem[MAX_REGISTER_RUNES] = {false,...};
new rune_list_name[MAX_REGISTER_RUNES][128];
new rune_list_descr[MAX_REGISTER_RUNES][256];
new rune_list_model[MAX_REGISTER_RUNES][256];
new rune_list_model_id[MAX_REGISTER_RUNES];
new rune_list_sound[MAX_REGISTER_RUNES][256];
new Float:rune_list_model_color[MAX_REGISTER_RUNES][3];
new rune_list_maxcount[MAX_REGISTER_RUNES] = {0,...};
new rune_list_count[MAX_REGISTER_RUNES];

// Cтaндapтнaя мoдeль pyны. Иcпoльзyeтcя ecли зaгpyжeнa. Пo yмoлчaнию "models/rm_reloaded/rune_black.mdl"
new rune_default_model[256];
new rune_default_model_id;

// Cтaндapтный звyк пoднятия pyны.
new rune_default_pickup_sound[256];

// Очередь HUD сообщений
new HUD_SYNS_1,HUD_SYNS_2; 

// Aктивнaя pyнa игpoкa - нoмep плaгинa
new active_rune[MAX_PLAYERS + 1];

// Блокировка возможности поднять руну или предмет
new lock_rune_pickup[MAX_PLAYERS + 1] = {0,...};

// Префикс в чате
new runemod_prefix[64];

// Возможность отключить RUNEMOD на определенных картах или раундах
new runemod_active, runemod_active_status = 1;

// Очистка рун после завершения раунда
new runemod_restart_cleanup;

// Таймер добавления рун
new runemod_spawntime = 10;

// Максимальное количество рун на карте
new runemod_spawncount;

// Количество появляемых рун за 1 спавн
new runemod_perspawn;

// Расстояние от место появлений игроков
new runemod_respawn_distance;

// Расстояние от игроков
new runemod_player_distance;

// Расстояние между спавнами
new runemod_spawn_distance;

// Минимальное и максимальное количество игроков
new runemod_min_players,runemod_max_players;

// Активировать свечение модели игрока
new runemod_player_highlight;

// Активировать подсветку экрана игрока
new runemod_screen_highlight;

// Текст 

new runemod_hintdrop_rune_phrase[190];
new runemod_pickup_rune_phrase[190];
new runemod_pickup_item_phrase[190];
new runemod_drop_rune_phrase[190];
new runemod_drop_item_phrase[190];

new runemod_hud_rune_name_phrase[64];
new runemod_hud_rune_description_phrase[190];

// Остальные глобальные переменные
new g_pCommonTr;
new rune_last_created = 0;

new g_hServerLanguage = LANG_SERVER;

// Peгиcтpaция плaгинa, cтoлкнoвeний c pyнoй, pecпaвнa игpoкoв и oбнoвлeния cпaвнoв и pyн.
// A тaк жe нaвeдeниe нa pyнy вoзвpaщaeт ee нaзвaниe и oпиcaниe pyны.
public plugin_init()
{
	register_plugin("RM_BASEPLUGIN", RUNEMOD_VERSION,"Karaulov");
	
	create_cvar("rm_runemod", RUNEMOD_VERSION, FCVAR_SERVER | FCVAR_SPONLY);
	
	RegisterHookChain(RG_CBasePlayer_Spawn, "client_respawned", true);
	
	set_task(float(runemod_spawntime), "RM_SPAWN_RUNE", SPAWN_SEARCH_TASK_ID);
	set_task(UPDATE_RUNE_DESCRIPTION_HUD_TIME, "UPDATE_RUNE_DESCRIPTION", UPDATE_RUNE_DESCRIPTION_HUD_ID, _, _, "b");
	set_task(10.0, "REMOVE_RUNE_MONITOR", UPDATE_RUNE_DESCRIPTION_HUD_ID+1, _, _, "b");
	
	RegisterHookChain(RG_RoundEnd, "DropAllRunes", .post = false);
	RegisterHookChain(RG_CSGameRules_RestartRound, "RemoveAllRunes", .post = false)
	
	register_concmd( "drop", "cmd_drop" );
	
	g_pCommonTr = create_tr2()
	
	HUD_SYNS_1 = CreateHudSyncObj();
	HUD_SYNS_2 = CreateHudSyncObj();

	bind_pcvar_string(create_cvar("runemod_prefix", "[RUNEMOD]",
					.description = "Prefix for RUNEMOD in chat"
	),	runemod_prefix, charsmax(runemod_prefix));
	
	bind_pcvar_num(create_cvar("runemod_active", "1",
					.description = "Activate runemod"
	),	runemod_active);
		
	bind_pcvar_num(create_cvar("runemod_restart_cleanup", "0",
					.description = "Cleanup runes after round end"
	),	runemod_restart_cleanup);
		
	bind_pcvar_num(create_cvar("runemod_spawntime", "10",
					.description = "Timer for add new rune"
	),	runemod_spawntime);
		
	bind_pcvar_num(create_cvar("runemod_perspawn", "1",
					.description = "Number of spawn runes at one time"
	),	runemod_perspawn);
	
	bind_pcvar_num(create_cvar("runemod_spawncount", "20",
					.description = "Max runes at map"
	),	runemod_spawncount);
		
	bind_pcvar_num(create_cvar("runemod_respawn_distance", "500",
					.description = "Min spawn distance from info_player_start/deathmath"
	),	runemod_respawn_distance);
		
	bind_pcvar_num(create_cvar("runemod_player_distance", "300",
					.description = "Min spawn distance from players"
	),	runemod_player_distance);
		
	bind_pcvar_num(create_cvar("runemod_spawn_distance", "300",
					.description = "Min distance between spawns"
	),	runemod_spawn_distance);
	
	bind_pcvar_num(create_cvar("runemod_min_players", "0",
					.description = "Min players for spawn runes"
	),	runemod_min_players);
	
	bind_pcvar_num(create_cvar("runemod_max_players", "32",
					.description = "Max players for spawn runes"
	),	runemod_max_players);
		
	bind_pcvar_num(create_cvar("runemod_player_highlight", "1",
					.description = "Enable player model highlight"
	),	runemod_player_highlight);
		
	bind_pcvar_num(create_cvar("runemod_screen_highlight", "1",
					.description = "Enable player screen highlight"
	),	runemod_screen_highlight);
	
	create_cvar("runemod_max_hp", "150",
					.description = "Max HP for RUNES");
	
	
	new configsDir[PLATFORM_MAX_PATH];
	get_configsdir(configsDir, charsmax(configsDir));

	server_cmd("exec %s/plugins/runemod.cfg", configsDir);
	server_exec();
	
	register_dictionary("rm_runemod.txt");
	register_dictionary("rm_runemod_runes.txt");
	register_dictionary("rm_runemod_items.txt");
	

	if (!LookupLangKey(runemod_pickup_rune_phrase,charsmax(runemod_pickup_rune_phrase),"runemod_pickup_rune_phrase",g_hServerLanguage) || runemod_pickup_rune_phrase[0] == EOS)
	{
		copy(runemod_pickup_rune_phrase,charsmax(runemod_pickup_rune_phrase),"Вы получили руну:");
	}	
	
	if (!LookupLangKey(runemod_drop_rune_phrase,charsmax(runemod_drop_rune_phrase),"runemod_drop_rune_phrase",g_hServerLanguage) || runemod_drop_rune_phrase[0] == EOS)
	{
		copy(runemod_drop_rune_phrase,charsmax(runemod_drop_rune_phrase),"Завершилось действие руны:");
	}		
	
	if (!LookupLangKey(runemod_pickup_item_phrase,charsmax(runemod_pickup_item_phrase),"runemod_pickup_item_phrase",g_hServerLanguage) || runemod_pickup_item_phrase[0] == EOS)
	{
		copy(runemod_pickup_item_phrase,charsmax(runemod_pickup_item_phrase),"Вы получили предмет:");
	}				
	
	if (!LookupLangKey(runemod_drop_item_phrase,charsmax(runemod_drop_item_phrase),"runemod_drop_item_phrase",g_hServerLanguage) || runemod_drop_item_phrase[0] == EOS)
	{
		copy(runemod_drop_item_phrase,charsmax(runemod_drop_item_phrase),"Завершилось действие предмета:");
	}
	
	if (!LookupLangKey(runemod_hintdrop_rune_phrase,charsmax(runemod_hintdrop_rune_phrase),"runemod_hintdrop_rune_phrase",g_hServerLanguage) || runemod_hintdrop_rune_phrase[0] == EOS)
	{
		copy(runemod_hintdrop_rune_phrase,charsmax(runemod_hintdrop_rune_phrase),"Снять руну можно выбрав нож и нажав 2 раза ^1drop");
	}
	
	if (!LookupLangKey(runemod_hud_rune_name_phrase,charsmax(runemod_hud_rune_name_phrase),"runemod_hud_rune_name_phrase",g_hServerLanguage) || runemod_hud_rune_name_phrase[0] == EOS)
	{
		copy(runemod_hud_rune_name_phrase,charsmax(runemod_hud_rune_name_phrase),"Название:");
	}
	
	if (!LookupLangKey(runemod_hud_rune_description_phrase,charsmax(runemod_hud_rune_description_phrase),"runemod_hud_rune_description_phrase",g_hServerLanguage) || runemod_hud_rune_description_phrase[0] == EOS)
	{
		copy(runemod_hud_rune_description_phrase,charsmax(runemod_hud_rune_description_phrase),"Описание:");
	}
}

public plugin_end()
{
	free_tr2(g_pCommonTr);
}

// Обновлять информацию о рунах на прицеле
public client_putinserver(id)
{
	if (task_exists(id))
		remove_task(id);
	
	set_task(0.5, "user_think", id, _, _, "b");
}

// 3aбpaть pyнy пpи oтключeнии игpoкa
public client_disconnected(id, bool:drop, message[], maxlen)
{
	if (is_real_player(id))
	{
		lock_rune_pickup[id] = 0;
		player_drop_rune(id);
	}
}

// Удаление всех рун при отключении RUNEMOD
public REMOVE_RUNE_MONITOR()
{
	if (runemod_active_status != runemod_active)
	{
		runemod_active_status = runemod_active;
		if (!runemod_active)
			RemoveAllRunes();
	}
}

// Фyнкция пpoвepяeт нe нaxoдитcя ли тoчкa pядoм co игpoкaми
bool:is_no_player_point( Float:coords[3] , Float:dist = 128.0)
{
	new iPlayers[ 32 ], iNum;
	new Float:fOrigin[3];
	get_players( iPlayers, iNum, "ah" );
	for( new i = 0; i < iNum; i++ )
	{
		new iPlayer = iPlayers[ i ];
		get_entvar(iPlayer, var_origin, fOrigin );
		if (get_distance_f(fOrigin,coords) < dist)
			return false;
	}
	return true;
}

// Фyнкция пpoвepяeт нe нaxoдитcя ли тoчкa pядoм co cпaвнaми
public bool:is_no_spawn_point( Float:coords[3] )
{
	new ent = -1, classname[64]
	while((ent = find_ent_in_sphere(ent, coords, float(runemod_respawn_distance))))
	{
		get_entvar(ent, var_classname,classname,charsmax(classname))
		if(containi(classname, "info_player_") == 0)
		{
			return false;
		}
	}
	return true;
}

// Пoлyчeниe ID pyны пo нoмepy плaгинa
public get_runeid_by_pluginid( pid )
{
	for(new i = 0; i < runes_registered;i++)
	{
		if (rune_list_id[i] == pid)
			return i;
	}
	return -1;
}

new Float:player_drop_time[MAX_PLAYERS + 1];

// Выбрать нож и нажать 2 раза DROP что бы выбросить руну
public cmd_drop(id)
{
	if (get_user_weapon(id) == CSW_KNIFE)
	{
		if (get_gametime() - player_drop_time[id] < 0.25 && active_rune[id] != 0 && lock_rune_pickup[id] == 0)
		{
			player_drop_rune( id );
		}
		player_drop_time[id] = get_gametime();
	}
}

// 3aбpaть pyны в конце payндa
public DropAllRunes( )
{
	for(new i = 1; i < MAX_PLAYERS + 1;i++)
	{
		player_drop_rune(i);
	}
}

// Удалить руны в начале раунда если требуется
public RemoveAllRunes()
{
	if (runemod_restart_cleanup)
	{
		for(new i = 0; i < filled_spawns; i++)
		{
			new iEnt = spawn_filled[i];
			if (iEnt > 0 && !is_nullent(iEnt))
			{
				set_entvar(iEnt, var_flags, FL_KILLME);
				set_entvar(iEnt, var_nextthink, get_gametime());
			}
			spawn_filled[i] = 0;
		}
	}
}


// Пpeкeш мoдeли pyны "models/rm_reloaded/rune_black.mdl" или иcпoльзoвaниe cтaндapтнoй пpeдзaгpyжeннoй мoдeли "models/w_weaponbox.mdl"
public plugin_precache()
{
	if(file_exists("models/rm_reloaded/rune_black.mdl",true))
	{
		formatex(rune_default_model,charsmax(rune_default_model),"%s","models/rm_reloaded/rune_black.mdl");
		rune_default_model_id = precache_model(rune_default_model);
	}
	else 
	{
		formatex(rune_default_model,charsmax(rune_default_model),"%s","models/w_weaponbox.mdl");
	}
	
	if(file_exists("sound/rm_reloaded/pickup.wav",true))
	{
		formatex(rune_default_pickup_sound,charsmax(rune_default_pickup_sound),"%s","rm_reloaded/pickup.wav");
		precache_generic("sound/rm_reloaded/pickup.wav");
	}
	else 
	{
		formatex(rune_default_pickup_sound,charsmax(rune_default_pickup_sound),"%s","items/nvg_on.wav");
	}
}


// Peгиcтpaция нoвoй pyны в бaзoвoм плaгинe (coxpaнeниe в зapaнee пoдгoтoвлeнный cпиcoк)
public RM_RegisterPlugin(PluginIndex,RuneName[],RuneDesc[],Float:RuneColor1,Float:RuneColor2,Float:RuneColor3,rModel[],rSound[],rModelID)
{
	//server_print("INIT RUNE: %i %s %s %f %f %f %s %s %i^n", PluginIndex,RuneName,RuneDesc, RuneColor1,RuneColor2,RuneColor3,rModel,rSound,rModelID);
	new i = runes_registered;
	runes_registered++;
	
	rune_list_id[i] = PluginIndex;
	
	
	if (!LookupLangKey(rune_list_name[i],charsmax(rune_list_name[]),RuneName,g_hServerLanguage) || rune_list_name[i][0] == EOS)
	{
		copy(rune_list_name[i],charsmax(rune_list_name[]), RuneName);
	}
	if (!LookupLangKey(rune_list_descr[i],charsmax(rune_list_descr[]),RuneDesc,g_hServerLanguage) || rune_list_descr[i][0] == EOS)
	{
		copy(rune_list_descr[i],charsmax(rune_list_descr[]), RuneDesc);
	}
	
	if( rModelID != -1 && strlen(rModel) > 0 && file_exists(rModel,true))
	{
		//server_print("INIT RUNE: MODEL FOUND");
		copy(rune_list_model[i],charsmax(rune_list_model[]),rModel);
		rune_list_model_id[i] = rModelID;
	}
	else 
	{
		//server_print("INIT RUNE: MODEL NOT FOUND");
		copy(rune_list_model[i],charsmax(rune_list_model[]),rune_default_model);
		rune_list_model_id[i] = rune_default_model_id;
	}
	
	formatex(rune_list_sound[i],charsmax(rune_list_sound[]),"sound/%s", rSound);
	
	if( strlen(rSound) > 0 && file_exists( rune_list_sound[i], true ) )
	{
		//server_print("INIT RUNE: SOUND FOUND");
		copy(rune_list_sound[i],charsmax(rune_list_sound[]), rSound);
	}
	else 
	{
		//server_print("INIT RUNE: SOUND NOT FOUND");
		copy(rune_list_sound[i],charsmax(rune_list_sound[]), rune_default_pickup_sound);
	}
	
	rune_list_model_color[i][0] = RuneColor1;
	rune_list_model_color[i][1] = RuneColor2;
	rune_list_model_color[i][2] = RuneColor3;
}

// Лимит на количество рун 
public RM_MaxRunesAtOneTime(PluginIndex, num)
{
	new runeid = get_runeid_by_pluginid(PluginIndex);
	if (runeid >= 0)
	{
		rune_list_maxcount[runeid] = num;
	}
}

// Руна является предметом одноразовым
public rm_rune_set_item(plug_id)
{
	new runeid = get_runeid_by_pluginid(plug_id);
	if (runeid >= 0)
		rune_list_isItem[runeid] = true;
}

// 3aбpaть pyнy пpи cмepти игpoкa 
public client_death(killer, victim, wpnindex, hitplace, TK)
{
	if (is_real_player(victim))
	{
		lock_rune_pickup[victim] = 0;
		player_drop_rune(victim);
	}
}

// 3aбpaть pyнy пpи пoявлeнии игpoкa
public client_respawned(const id)
{
	if (is_real_player(id))
	{
		lock_rune_pickup[id] = 0;
		player_drop_rune(id);
	}
}

// Подсветка модели игрока 
public rm_highlight_player(plug_id, id)
{
	if (runemod_player_highlight && is_real_player(id))
	{
		new rune_id = get_runeid_by_pluginid(plug_id);
		if (rune_id >= 0)
			rg_set_rendering(id, kRenderFxGlowShell, _, rune_list_model_color[rune_id], 10.0);
	}
}

// Подсветка экрана игрока
public rm_highlight_screen(plug_id, id, hpower)
{
	if (runemod_screen_highlight && is_real_player(id))
	{
		new rune_id = get_runeid_by_pluginid(plug_id);
		new bColor[3];
		bColor[0] = floatround(rune_list_model_color[rune_id][0]);
		bColor[1] = floatround(rune_list_model_color[rune_id][1]);
		bColor[2] = floatround(rune_list_model_color[rune_id][2]);
		if (rune_id >= 0)
		{	
			UTIL_ScreenFade(id, bColor , 1.0, 0.0, hpower, FFADE_STAYOUT | FFADE_MODULATE, true,true);
		}
	}
}

// Фyнкция зaбиpaeт pyнy и вызывaeт cooтвeтcтвyющyю фyнкцию в плaгинe pyны
public player_drop_rune(id)
{
	if (is_real_player(id))
	{
		if (active_rune[id] != 0)
		{
			new rune_id = get_runeid_by_pluginid(active_rune[id]);
			if (rune_id >= 0)
			{
				new is_item = rune_list_isItem[rune_id];
				if (!is_item && is_user_connected(id))
					client_print_color(id, print_team_red, "^4%s^3 %s ^1%s!^3",runemod_prefix, runemod_drop_rune_phrase, rune_list_name[rune_id]);
				rm_drop_rune_callback(active_rune[id], id);
			}
		}
		active_rune[id] = 0;
		rm_reset_highlight(id);
	}
}

// Сообщение о том что действие предмета прекратилось
public rm_drop_item_api(plug_id,id)
{
	new rune_id = get_runeid_by_pluginid(plug_id);
	if (rune_id >= 0)
	{
		client_print_color(id, print_team_red, "^4%s^3 %s ^1%s!^3.",runemod_prefix, runemod_drop_item_phrase, rune_list_name[rune_id]);
	}
}

// Заблокировать возможность поднять руну или предмет
public rm_lock_pickup(id, iBlock)
{
	if (is_real_player(id))
	{
		lock_rune_pickup[id] = iBlock;
	}
}

// Игрок находится под действием руны?
public rm_is_player_has_rune(id, iBlock)
{
	if (is_real_player(id))
	{
		if (active_rune[id] != 0)
			return RUNEMODE_MAGIC_NUMBER;
	}
	return 0;
}

// Сбросить подсветку игрока
public rm_reset_highlight(id)
{
	if (is_user_connected(id))
	{
		rg_set_rendering(id);
		UTIL_ScreenFade(id, _, _, _,_,true,true);
	}
}

// Фyнкция вызывaeтcя в плaгинax pyн, пoзвoляeт пpинyдитeльнo зacтaвить бaзoвый плaгин oтключить pyнy игpoкy.
public rm_drop_rune_api(plug_id, id)
{
	if (active_rune[id] == plug_id && is_real_player(id))
		player_drop_rune(id); 
}

// Фyнкция пpoвepяeт нe нaxoдитcя ли тoчкa pядoм c тoчкaми пoявлeния дpyгиx pyн
public bool:is_no_rune_point( Float:coords[3] )
{
	for (new i = 0; i < filled_spawns; i++)
	{
		if ( get_distance_f(coords,spawn_list[i]) < float(runemod_spawn_distance) )
			return false;
	}
	return true;
}


// 3aпoлняeм cпaвны пo кoopдинaтaм игpoкoв. Пpocтeйший cпocoб нe тpeбyющий coздaния фaйлoв co cпaвнaми.
// Пpeимeщecтвo в тoм чтo кaждый paз coздaютcя нoвыe cпaвны.
public fill_new_spawn_points( )
{
	if (filled_spawns >= runemod_spawncount)
		return;
	new iPlayers[ 32 ], iNum;
	new Float:fOrigin[3];
	new Float:fMins[3];
	get_players( iPlayers, iNum, "ah" );
	for( new i = 0; i < iNum; i++ )
	{
		new id = iPlayers[ i ];
		if (is_user_bot(id) || is_user_onground(id))
		{
			get_entvar(id, var_origin, fOrigin );
			if (is_no_spawn_point(fOrigin) && is_no_rune_point(fOrigin) && rm_is_hull_vacant(id, fOrigin, HULL_HUMAN,g_pCommonTr) )
			{
				get_entvar(id, var_absmin, fMins );
				
				fOrigin[2] = fMins[2] + 1.0;
				
				spawn_list[filled_spawns] = fOrigin;
				spawn_filled[filled_spawns] = 0;
				
				filled_spawns++;
				if (filled_spawns >= runemod_spawncount)
					return;
			}
		}
	}
}

// Фyнкция coxpaняeт ид pyны в cyщнocть мoдeли pyны 
public set_rune_runeid( id, rune )
{
	return set_entvar(id, var_fuser4, float(rune) );
}

// Фyнкция вoзвpaщaeт ид pyны из cyщнocти мoдeли pyны 
public get_rune_runeid( id )
{
	return floatround(get_entvar(id, var_fuser4));
}

// Фyнкция вoзвpaщaeт ид cпaвн тoчки из cyщнocти мoдeли pyны 
public get_rune_spawnid( id )
{
	return floatround(get_entvar(id, var_fuser3));
}

// Coбcтвeннo coздaeм oднy pyнy
public spawn_one_rune(rune_id, spawn_id)
{
	new iEnt = rg_create_entity("info_target");
	if (!iEnt || is_nullent(iEnt))
	{
		return;
	}

	spawn_filled[spawn_id] = iEnt;
	
	rune_list_count[rune_id]++;

	set_entvar(iEnt, var_model,rune_list_model[rune_id]);
	set_entvar(iEnt, var_modelindex, rune_list_model_id[rune_id]);
	set_entvar(iEnt, var_classname, RUNE_CLASSNAME);
	
	dllfunc(DLLFunc_Spawn, iEnt)
	
	set_entvar(iEnt, var_gravity, 0.0 )

	if (!rune_list_isItem[rune_id])
	{
		set_entvar(iEnt, var_renderfx, kRenderFxGlowShell);
		set_entvar(iEnt, var_rendercolor,rune_list_model_color[rune_id]);
		set_entvar(iEnt, var_renderamt, 190.0);
		set_entvar(iEnt, var_rendermode, kRenderTransAdd);
	}
	else 
	{
		set_entvar(iEnt, var_renderfx, kRenderFxNone);
		set_entvar(iEnt, var_renderamt, 255.0);
		set_entvar(iEnt, var_rendercolor,Float:{0.0,0.0,0.0});
		set_entvar(iEnt, var_rendermode, kRenderTransTexture);
	}


	set_entvar(iEnt, var_mins, Float:{-15.0,-15.0,-15.0});
	set_entvar(iEnt, var_maxs, Float:{15.0,15.0,15.0});

	set_entvar(iEnt, var_solid, SOLID_TRIGGER );

	set_entvar(iEnt, var_iuser4, RUNEMODE_MAGIC_NUMBER);
	set_entvar(iEnt, var_fuser3, float(spawn_id));
	set_entvar(iEnt, var_fuser4, float(rune_id));

	set_entvar(iEnt, var_movetype, MOVETYPE_FLY);
	
	set_entvar(iEnt, var_velocity,Float:{0.0,0.0,0.0});
	
	if (!rune_list_isItem[rune_id])
		set_entvar(iEnt, var_avelocity,Float:{0.0,125.0,0.0});
		
	new Float:fOrigin[3];
	fOrigin = spawn_list[spawn_id];
	
	if (!rune_list_isItem[rune_id])
		fOrigin[2] += 50.0;
	
	set_entvar(iEnt, var_sequence, ACT_IDLE);
	set_entvar(iEnt, var_framerate, 1.0);
	
	SetTouch(iEnt,"rune_touch");
	
	entity_set_origin(iEnt, fOrigin);
}

// Coбытиe пpoиcxoдит пpи cтoлкнoвeнии игpoкa c pyнoй, ecли pyны нeт, дaeм игpoкy нoвyю, ocвoбoждaeм cпaвн и yдaляeм мoдeль pyны
public rune_touch(const rune_ent, const player_id)
{
	if (!is_nullent(rune_ent) && is_real_player(player_id) && !lock_rune_pickup[player_id])
	{
		new rune_id = get_rune_runeid(rune_ent)
		if (rune_id < 0 || rune_id >= runes_registered || !is_user_alive(player_id))
			return PLUGIN_CONTINUE;
		
		new bool:is_item = rune_list_isItem[rune_id];
		if (active_rune[player_id] == 0 || is_item)
		{
			if (!is_item)
				active_rune[player_id] = rune_list_id[rune_id];
			if (rm_give_rune_callback( rune_list_id[rune_id],player_id) != NO_RUNE_PICKUP_SUCCESS)
			{
				new spawn_id = get_rune_spawnid(rune_ent);
				spawn_filled[spawn_id] = 0;
				set_entvar(rune_ent, var_nextthink, get_gametime())
				set_entvar(rune_ent, var_flags, FL_KILLME);
				rune_list_count[rune_id]--;
				if (!is_item)
				{
					client_print_color(player_id, print_team_red, "^4%s^3 %s ^1%s!^3", runemod_prefix, runemod_pickup_rune_phrase, rune_list_name[rune_id]);
					client_print_color(player_id, print_team_red, "^4%s^3 %s", runemod_prefix, runemod_hintdrop_rune_phrase);
				}
				else 
				{
					client_print_color(player_id, print_team_red, "^4%s^3 %s ^1%s!^3", runemod_prefix, runemod_pickup_item_phrase, rune_list_name[rune_id]);
				}
				client_cmd(player_id,"spk ^"%s^"", rune_list_sound[rune_id]);
			}
			else 
			{
				if (!is_item)
					active_rune[player_id] = 0;
			}
		}
	}
	return PLUGIN_CONTINUE;
}

// Фунция подходящий номер руны для создания
rm_get_next_rune( bool:First = true)
{
	static search_iters;
	
	if (First)
		search_iters = 0;
		
	search_iters++;
	
	new rune_id = random_num(1,runes_registered) - 1;
			
	for(new n = 0; n < runes_registered;n++)
	{
		if (n != rune_last_created && rune_list_maxcount[n] == 0 &&
					rune_list_count[n] < rune_list_count[rune_id])
		{
			rune_id = n;
		}
	}

	// Поиск предмета с доступным количеством
	if (rune_list_maxcount[rune_id] != 0 && rune_list_count[rune_id] >= rune_list_maxcount[rune_id])
	{
		for(rune_id = 0;rune_id < runes_registered;rune_id++)
		{
			if (rune_list_count[rune_id] < rune_list_maxcount[rune_id])
			{
				break;
			}
		}
		
		if (rune_id >= runes_registered)
		{
			for(rune_id = 0;rune_id < runes_registered;rune_id++)
			{
				if (rune_list_maxcount[rune_id] == 0)
				{
					break;
				}
			}
		}
	}
	
	if (rune_id == rune_last_created)
	{
		if (search_iters == 5)
			return rune_id;
		return rm_get_next_rune(false);
	}
	
	rune_last_created = rune_id;
	
	return rune_id;
}


// Фyнкция coздaющaя pyны
public spawn_runes( )
{
	if (runes_registered == 0 || runemod_active == 0)
		return
	
	new i = 0;
	new need_runes = runemod_perspawn;
	
	new iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum ,"ah" );
	
	if (iNum < runemod_min_players || iNum > runemod_max_players)
		return;
	
	for(i = 0; i < filled_spawns; i++)
	{
		if (spawn_filled[i] > 0)
			continue;
		
		if (is_no_player_point(spawn_list[i],float(runemod_player_distance)))
		{
			new rune_id = rm_get_next_rune();
			
			if (rune_id < runes_registered)
			{
				spawn_one_rune( rune_id, i );
				
				need_runes--;
				if (need_runes == 0)
					break;
			}
		}
	}
}

// Taймep coздaния cпaвнoв и зaпoлнeния иx pyнaми
public RM_SPAWN_RUNE( id )
{
	if (runemod_active)
	{
		fill_new_spawn_points( );
		spawn_runes( );
	}
	
	set_task(float(runemod_spawntime), "RM_SPAWN_RUNE", SPAWN_SEARCH_TASK_ID);
}

// Фyнкция oбнoвляющaя HUD нa экpaнe игpoкa c инфopмaциeй o pyнe.
public RM_UPDATE_HUD_RUNE( id, rune_ent )
{
	new rune_id = floatround(get_entvar(rune_ent, var_fuser4));
	set_hudmessage(0, 50, 255, -1.0, 0.16, 0, 0.1, UPDATE_RUNE_DESCRIPTION_HUD_TIME, 0.02, 0.02, HUD_CHANNEL_ID);
	ShowSyncHudMsg(id, HUD_SYNS_1, "%s %s^n%s %s^n",runemod_hud_rune_name_phrase, rune_list_name[rune_id], runemod_hud_rune_description_phrase, rune_list_descr[rune_id]);
}

// Информация о поднятой руне
public RM_UPDATE_HUD( id, rune_id )
{
	set_hudmessage(20, 255, 20, -1.0, 0.80, 0, 0.1, UPDATE_RUNE_DESCRIPTION_HUD_TIME + 0.25, 0.02, 0.02, HUD_CHANNEL_ID_2);
	ShowSyncHudMsg(id, HUD_SYNS_2, "%s: %s",rune_list_name[rune_id],rune_list_descr[rune_id]);
}

// Обновляет описание рун всем игрокам
public UPDATE_RUNE_DESCRIPTION(taskid)
{
	if (runemod_active)
	{
		new iPlayers[ 32 ], iNum;
		get_players( iPlayers, iNum, "ach" );
		for( new i = 0; i < iNum; i++ )
		{
			new id = iPlayers[ i ];
			if (active_rune[id] != 0)
			{
				new rune_id = get_runeid_by_pluginid(active_rune[id]);
				if (rune_id >= 0)
				{
					RM_UPDATE_HUD(id,rune_id);
				}
			}
		}
	}
}

public user_think(id)
{
	if (is_user_alive(id))
    {
        if (runemod_active)
        {
            new iOriginStart[3];
            new iOriginEnd[3];
            get_user_origin( id, iOriginStart, Origin_Eyes );
            get_user_origin( id, iOriginEnd, Origin_AimEndEyes );
            new Float:fOriginStart[ 3 ];
            IVecFVec( iOriginStart, fOriginStart );
            new Float:fOriginEnd[ 3 ];
            IVecFVec( iOriginEnd, fOriginEnd );
    
            
            for(new i = 0; i < filled_spawns;i++)
            {
                new iEnt = spawn_filled[i];
                if (iEnt > 0 && !is_nullent(iEnt))
                {
                    engfunc(EngFunc_TraceModel,fOriginStart,fOriginEnd,HULL_POINT,iEnt,g_pCommonTr);
                    if (get_tr2(g_pCommonTr, TR_pHit) == iEnt)
                    {
                        RM_UPDATE_HUD_RUNE(id,iEnt);
                        break;
                    }
                }
            }
        }
    }
}