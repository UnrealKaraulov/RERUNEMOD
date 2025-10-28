#include <amxmodx>
#include <amxmisc>
#include <csx>
#include <fakemeta>
#include <xs>
#include <rm_api>
#include <cellarray>

//#define DEBUG_ENABLED

// Koличecтвo pyн
new runes_registered = 0;

// Дaнныe o pyнax
new rune_list_id[MAX_REGISTER_RUNES];
new bool:rune_list_isItem[MAX_REGISTER_RUNES] = {false,...};
new bool:rune_list_gamecms[MAX_REGISTER_RUNES] = {false,...};
new bool:rune_list_disabled[MAX_REGISTER_RUNES] = {false,...};
new rune_list_name[MAX_REGISTER_RUNES][128];
new rune_list_descr[MAX_REGISTER_RUNES][256];
new rune_list_model[MAX_REGISTER_RUNES][256];
new rune_list_model_id[MAX_REGISTER_RUNES];
new rune_list_sound[MAX_REGISTER_RUNES][256];
new Float:rune_list_model_color[MAX_REGISTER_RUNES][3];
new rune_list_maxcount[MAX_REGISTER_RUNES] = {0,...};
new rune_list_count[MAX_REGISTER_RUNES];
new rune_list_icost[MAX_REGISTER_RUNES] = {0,...};

// Текущее количество предметов и рун на карте
new runemod_spawned_items = 0;
new runemod_spawned_runes = 0;

// Koличecтвo cпaвнoв
new spawn_array_size = 0;
new spawn_filled_size = 0;

// Koopдинaты cпaвнoв
new Float:spawn_pos[MAX_SPAWN_POINTS][3];

// 3aнят ли cпaвн нa дaнный мoмeнт pyнoй
new spawn_has_ent[MAX_SPAWN_POINTS] = {0,...};

// Координаты рун для user_think
new spawn_iEnt_Origin[MAX_SPAWN_POINTS][3];

// Cтaндapтнaя мoдeль pyны. Иcпoльзyeтcя ecли зaгpyжeнa. Пo yмoлчaнию "models/rm_reloaded/rune_black.mdl"
new rune_default_model[MAX_RESOURCE_PATH_LENGTH];
new rune_default_model_id;

// Cтaндapтный звyк пoднятия pyны.
new rune_default_pickup_sound[MAX_RESOURCE_PATH_LENGTH];

// Список карт недоступных для RuneMod
new runemod_ignore_prefix_list[256];

// Стандартная модель руны
new runemod_default_model_path[MAX_RESOURCE_PATH_LENGTH];

// Стандартный звук поднятия руны
new runemod_default_pickup_path[MAX_RESOURCE_PATH_LENGTH];

// Время работы мода
new runemod_start_time_hours = -1;
new runemod_end_time_hours = -1;
new runemod_time[16];

// Очередь HUD сообщений
new HUD_SYNS_1,HUD_SYNS_2; 

// Aктивнaя pyнa игpoкa - нoмep плaгинa
new active_rune_id[MAX_PLAYERS + 1] = {-1,...};

// Блокировка возможности поднять руну или предмет
new lock_rune_pickup[MAX_PLAYERS + 1] = {0,...};

// Возможность отключить RUNEMOD на определенных картах или раундах
new runemod_active = 1;
new runemod_active_status = 1;

// Только предметы!
new runemod_only_items;

// Начальный раунд
new runemod_start_round;

// Очистка рун после завершения раунда
new runemod_restart_cleanup;

// Таймер добавления рун
new runemod_spawntime = 10;

// Максимальное спавн точек
new runemod_spawncount;

// Максимальное спавн точек для рун
new runemod_max_runes;

// Максимальное спавн точек для рун
new runemod_max_items;

// Количество появляемых рун за 1 спавн
new runemod_perspawn;

// Расстояние от место появлений игроков
new runemod_respawn_distance;

// Расстояние от игроков
new runemod_player_distance;

// Расстояние между спавнами
new runemod_spawn_distance;

// Поддержка нестандартных спавнов
new runemod_custom_spawn_support;

// Минимальное и максимальное количество игроков
new runemod_min_players,runemod_max_players;

// Активировать свечение модели игрока
new runemod_player_highlight;

// Активировать подсветку экрана игрока
new runemod_screen_highlight;

// Только для пользователей GAMECMS
new runemod_only_gamecms;

// Режим неизвестных рун
new runemod_random_mode;

// Забрать руны после окончания раунда
new runemod_newround_remove;

// Активировать магазин рун
new runemod_rune_shop;

// Префикс RUNEMOD (Можно ввести сайт или название сервера)
new runemod_prefix[64];

// Оповещение игроков
new runemod_notify_players;
new runemod_notify_players_drop;
new runemod_notify_spawns;

// Создавать предмет/руну только если игрок не увидит :)
new runemod_spawn_nolook;

// Обновление спавн точки для рун и предметов
new runemod_spawn_lifetime;

// Боты могут поднимать руны и предметы?
new runemod_bot_pickup;

// Остальные глобальные переменные
new g_pCommonTr;
new rune_last_created = 0;
new Float:g_fLastRegisterPrint[MAX_PLAYERS + 1] = {0.0,...};
new g_iRoundLeft = 0;
new bool:g_bCurrentMapIgnored = false;
new g_sConfigDirPath[PLATFORM_MAX_PATH];
new bool:g_bRegGameCMS[MAX_PLAYERS + 1] = {false,...};
new mp_maxmoney;
new g_bScreenFadeAllowed = false;
new Float:g_fLastSpawnRefreshTime = 0.0;
new g_iRefreshSpawnId = 0;

// Массивы состояния игроков
new bool:g_bUserConnected[MAX_PLAYERS + 1] = {false, ...};
new bool:g_bUserBot[MAX_PLAYERS + 1] = {false, ...};
new bool:g_bUserAlive[MAX_PLAYERS + 1] = {false, ...};

#define PLAYER_SPAWN_MAX 32
#define PLAYER_SPAWN_DEDUP_DIST 20.0
#define NOTIFY_DROP 0
#define NOTIFY_PICKUP 1

new Array:g_PlayerSpawns;

// Peгиcтpaция плaгинa, cтoлкнoвeний c pyнoй, pecпaвнa игpoкoв и oбнoвлeния cпaвнoв и pyн.
// A тaк жe нaвeдeниe нa pyнy вoзвpaщaeт ee нaзвaниe и oпиcaниe pyны.
public plugin_init()
{
	register_plugin("RM_BASEPLUGIN", RUNEMOD_VERSION,"Karaulov");
	
	create_cvar("rm_runemod", RUNEMOD_VERSION, FCVAR_SERVER | FCVAR_SPONLY);
	
	
	set_task(float(runemod_spawntime) / 2.0, "RM_SPAWN_RUNE", SPAWN_SEARCH_TASK_ID);
	set_task(UPDATE_RUNE_DESCRIPTION_HUD_TIME, "UPDATE_RUNE_DESCRIPTION", UPDATE_RUNE_DESCRIPTION_HUD_ID, _, _, "b");
	set_task(10.0, "REMOVE_RUNE_MONITOR", UPDATE_RUNE_DESCRIPTION_HUD_ID+1, _, _, "b");
	
	RegisterHookChain(RG_CBasePlayer_Spawn, "CBasePlayer_Spawn_Post", true);
	RegisterHookChain(RG_CBasePlayer_Killed, "CBasePlayer_Killed_Post", true);
	RegisterHookChain(RG_RoundEnd, "DropAllRunes_RoundEnd", .post = false);
	RegisterHookChain(RG_CSGameRules_RestartRound, "RestartRound", .post = false)
	
	// На случай если кто-то блокирует "drop" дважды проверяем
	RegisterHookChain(RG_CBasePlayer_DropPlayerItem, "RG_CBasePlayer_DropPlayerItem_Pre", .post = false);
	register_clcmd( "drop", "cmd_drop" );
	
	g_pCommonTr = create_tr2()
	
	HUD_SYNS_1 = CreateHudSyncObj();
	HUD_SYNS_2 = CreateHudSyncObj();
	
	g_PlayerSpawns = ArrayCreate(3); // 3 float (x,y,z)
	
	// Silent execute cfg 
	new HookChain:g_hConPrintf = RegisterHookChain(RH_Con_Printf, "RH_ConPrintf_Pre", 0)
	// Read server lang
	server_cmd("exec %s/amxx.cfg", g_sConfigDirPath);
	server_exec();
	DisableHookChain(g_hConPrintf);
	
	register_dictionary("rm_runemod.txt");
	register_dictionary("rm_runemod_runes.txt");
	register_dictionary("rm_runemod_items.txt");
	
	register_message(get_user_msgid("ScreenFade"),"Event_ScreenFade");
	
	mp_maxmoney = get_cvar_pointer("mp_maxmoney");
	
	// Часть кода отвечающая за отключения мода при совпадении префикса или названия карты
	static sMapName[32];
	rh_get_mapname(sMapName, charsmax(sMapName), MNT_TRUE);
	
	add(runemod_ignore_prefix_list,charsmax(runemod_ignore_prefix_list)," ");
	
	static sMapPrefix[32];
	new i = 0, iPos = 0;
	while((iPos = split_string(runemod_ignore_prefix_list[i], " ", sMapPrefix, charsmax(sMapPrefix))) > 0)
	{
		i += iPos;
		if (containi(sMapName,sMapPrefix) >= 0)
		{
			g_bCurrentMapIgnored = true;
			log_amx("[runemod_ignore_prefix_list]: Disable RuneMod Reloaded for current map. Match prefix %s for map %s.", sMapPrefix, sMapName);
			return;
		}
	}
	
	// Установка лимита по времени по часам
	
	if (strlen(runemod_time) > 2)
	{
		static hour1[3];
		static hour2[3];
		parse(runemod_time, hour1, charsmax(hour1), hour2, charsmax(hour2));
		if (hour1[0] != EOS && hour2[0] != EOS)
		{
			if (hour1[0] == '0')
			{
				hour1[0] = hour1[1];
				hour1[1] = EOS;
			}
			if (hour2[0] == '0')
			{
				hour2[0] = hour2[1];
				hour2[1] = EOS;
			}
			runemod_start_time_hours = str_to_num(hour1);
			runemod_end_time_hours = str_to_num(hour2);
		}
		
		log_amx("RuneMod Reloaded! Time from %02d:00 to %02d:00",runemod_start_time_hours,runemod_end_time_hours);
	}
	else 
	{
		log_amx("RuneMod Reloaded!");
	}
	
}

public RH_ConPrintf_Pre(const szBuffer[])
{
	return HC_BREAK;
}

public rm_config_execute()
{
	bind_pcvar_string(create_cvar("runemod_prefix", "[RUNEMOD]",
					.description = "Prefix for RUNEMOD in chat"
	),	runemod_prefix, charsmax(runemod_prefix));
	
	bind_pcvar_string(create_cvar("runemod_ignore_prefix_list", "",
					.description = "Ignore map list"
	),	runemod_ignore_prefix_list, charsmax(runemod_ignore_prefix_list));
	
	bind_pcvar_num(create_cvar("runemod_active", "1",
					.description = "Activate runemod"
	),	runemod_active);
		
	bind_pcvar_num(create_cvar("runemod_restart_cleanup", "0",
					.description = "Cleanup runes after round end"
	),	runemod_restart_cleanup);
		
	bind_pcvar_num(create_cvar("runemod_start_round", "0",
					.description = "Startup round"
	),	runemod_start_round);
		
	bind_pcvar_num(create_cvar("runemod_only_items", "0",
					.description = "Only items!"
	),	runemod_only_items);
		
	bind_pcvar_num(create_cvar("runemod_spawntime", "10",
					.description = "Timer for add new rune"
	),	runemod_spawntime);
		
	bind_pcvar_num(create_cvar("runemod_perspawn", "1",
					.description = "Number of spawn runes at one time"
	),	runemod_perspawn);
	
	bind_pcvar_num(create_cvar("runemod_spawncount", "20",
					.description = "Max spawn points at map"
	),	runemod_spawncount);
	
	bind_pcvar_num(create_cvar("runemod_max_runes", "10",
					.description = "Max runes at map"
	),	runemod_max_runes);
		
	bind_pcvar_num(create_cvar("runemod_max_items", "20",
					.description = "Max items at map"
	),	runemod_max_items);
		
	bind_pcvar_num(create_cvar("runemod_respawn_distance", "100",
					.description = "Min spawn distance from info_player_start/deathmath"
	),	runemod_respawn_distance);
		
	bind_pcvar_num(create_cvar("runemod_player_distance", "100",
					.description = "Min spawn distance from players"
	),	runemod_player_distance);
		
	bind_pcvar_num(create_cvar("runemod_spawn_distance", "100",
					.description = "Min distance between spawns"
	),	runemod_spawn_distance);
	
	bind_pcvar_num(create_cvar("runemod_custom_spawn_support", "0",
					.description = "Support custom player spawns"
	),	runemod_custom_spawn_support);
	
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
	
	bind_pcvar_num(create_cvar("runemod_only_gamecms", "0",
					.description = "Only GAMECMS users!"
	),	runemod_only_gamecms);
	
	bind_pcvar_num(create_cvar("runemod_random_mode", "0",
					.description = "Random mode"
	),	runemod_random_mode);
	
	bind_pcvar_num(create_cvar("runemod_newround_remove", "1",
					.description = "Drop all runes and items at round end"
	),	runemod_newround_remove);
	
	bind_pcvar_num(create_cvar("runemod_rune_shop", "0",
					.description = "Enable runeshop"
	),	runemod_rune_shop);
	
	bind_pcvar_string(create_cvar("runemod_default_model_path", "models/rm_reloaded/rune_black.mdl",
					.description = "Default model for RuneMod"
	),	runemod_default_model_path, charsmax(runemod_default_model_path));
	
	
	bind_pcvar_string(create_cvar("runemod_default_pickup_path", "models/rm_reloaded/rune_black.mdl",
					.description = "Default sound for RuneMod"
	),	runemod_default_pickup_path, charsmax(runemod_default_pickup_path));
	
	
	bind_pcvar_string(create_cvar("runemod_time", "",
					.description = "Runemod time"
	),	runemod_time, charsmax(runemod_time));
	
	
	bind_pcvar_num(create_cvar("runemod_notify_players", "0",
					.description = "Players notify (pickup)"
	),	runemod_notify_players);
	
	bind_pcvar_num(create_cvar("runemod_notify_players_drop", "0",
					.description = "Players notify (drop)"
	),	runemod_notify_players_drop);
	
	bind_pcvar_num(create_cvar("runemod_notify_spawns", "0",
					.description = "Players notify (spawns)"
	),	runemod_notify_spawns);
	
	bind_pcvar_num(create_cvar("runemod_spawn_nolook", "0",
					.description = "Spawn only if player not sees"
	),	runemod_spawn_nolook);
	
	bind_pcvar_num(create_cvar("runemod_spawn_lifetime", "0",
					.description = "Spawn refresh timer"
	),	runemod_spawn_lifetime);
	
	bind_pcvar_num(create_cvar("runemod_bot_pickup", "1",
					.description = "Bot can pickup items"
	),	runemod_bot_pickup);
	
	register_clcmd("runeshop", "rm_runeshop");
	register_clcmd("rune_shop", "rm_runeshop");
	register_clcmd("say runeshop", "rm_runeshop");
	register_clcmd("say /runeshop", "rm_runeshop");
	register_clcmd("say_team runeshop", "rm_runeshop");
	register_clcmd("say_team /runeshop", "rm_runeshop");
	
	get_configsdir(g_sConfigDirPath, charsmax(g_sConfigDirPath));
	server_cmd("exec %s/plugins/runemod.cfg", g_sConfigDirPath);
	server_exec();
}

public plugin_end()
{
	free_tr2(g_pCommonTr);
	ArrayDestroy(g_PlayerSpawns);
}

// Обновлять информацию о рунах на прицеле
public client_putinserver(id)
{
	if (task_exists(id))
		remove_task(id);
		
	g_bRegGameCMS[id] = false;
	
	lock_rune_pickup[id] = 0;
	player_drop_rune(id);
	player_drop_all_items(id);
	active_rune_id[id] = -1;
	g_bUserConnected[id] = true;
	g_bUserAlive[id] = false;
	g_bUserBot[id] = is_user_bot(id) || is_user_hltv(id);
	
	if (!g_bUserBot[id])
		set_task(0.4, "user_think", id, _, _, "b");
}
public client_connect(id)
{
	g_bUserAlive[id] = false;
	g_bUserBot[id] = is_user_bot(id) || is_user_hltv(id);
}

// 3aбpaть pyнy пpи oтключeнии игpoкa
public client_disconnected(id, bool:drop, message[], maxlen)
{
	if (task_exists(id))
		remove_task(id);
		
	g_bRegGameCMS[id] = false;
	lock_rune_pickup[id] = 0;
	player_drop_rune(id);
	player_drop_all_items(id);
	active_rune_id[id] = -1;
	g_bUserConnected[id] = false;
}

public update_all_player_stat()
{
	for(new i = 1; i <= MAX_PLAYERS;i++)
	{
		if (is_user_connected(i))
		{
			g_bUserConnected[i] = true;
			g_bUserBot[i] = is_user_bot(i) || is_user_hltv(i);
			g_bUserAlive[i] = bool:is_user_alive(i);
		}
		else 
		{
			g_bUserConnected[i] = g_bUserAlive[i] = g_bUserBot[i] = false;
		}
	}
}

public plugin_pause()
{
	// Очистить карту от рун, т.к могут стать не валидными
	RemoveAllRunes();
	// Предотвратить нежелательне последствия
	DropAllRunes();
}

public plugin_unpause()
{
	update_all_player_stat();
	REMOVE_RUNE_MONITOR();
	RM_SPAWN_RUNE();
}

// Зарегистрировать словарь в RUNEMOD
public rm_register_dictionary_api(const dictname[])
{
	register_dictionary(dictname);
}

// Удаление всех рун при отключении RUNEMOD
public REMOVE_RUNE_MONITOR()
{
	if (runemod_active_status != runemod_active)
	{
		runemod_active_status = runemod_active;
		if (!runemod_active)
		{
			RemoveAllRunes();
		}
	}
	
	if (runemod_start_time_hours == -1 || runemod_end_time_hours == -1 || runemod_start_time_hours == runemod_end_time_hours)
	{
		return;
	}
	
	static hours;
	time(hours);
	
	if (runemod_start_time_hours > runemod_end_time_hours)
	{
		if (hours >= runemod_start_time_hours || hours < runemod_end_time_hours)
		{
			if (runemod_active_status != 1)
			{
				set_cvar_num("runemod_active", 1);
			}
		}
		else 
		{
			if (runemod_active_status != 0)
			{
				set_cvar_num("runemod_active", 0);
			}
		}
	}
	else if (runemod_start_time_hours <= hours && hours < runemod_end_time_hours)
	{
		if (runemod_active_status != 1)
		{
			set_cvar_num("runemod_active", 1);
		}
	}
	else 
	{
		if (runemod_active_status != 0)
		{
			set_cvar_num("runemod_active", 0);
		}
	}
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

// Выбрать нож и нажать 2 раза DROP что бы выбросить руну
public cmd_drop(id)
{
	static Float:player_drop_time[MAX_PLAYERS + 1] = {0.0,...};
	static iWeaponsTest[MAX_PLAYERS+1];
	
	if (id <= 0 || id > MAX_PLAYERS)
		return PLUGIN_CONTINUE;
		
	new tmpwId = get_user_weapon(id);
	
	if (tmpwId == iWeaponsTest[id])
	{
		if (get_gametime() - player_drop_time[id] < 0.30)
		{
			if (active_rune_id[id] >= 0)
			{
				player_drop_rune(id);
				player_drop_time[id] = get_gametime();
				iWeaponsTest[id] = tmpwId;
				return PLUGIN_HANDLED;
			}
		}
		player_drop_time[id] = get_gametime();
	}
	
	iWeaponsTest[id] = tmpwId;
	return PLUGIN_CONTINUE;
}

public RG_CBasePlayer_DropPlayerItem_Pre(id)
{
	static Float:player_drop_time[MAX_PLAYERS + 1] = {0.0,...};
	static iWeaponsTest[MAX_PLAYERS+1];
	
	if (id <= 0 || id > MAX_PLAYERS)
		return HC_CONTINUE;
		
	new tmpwId = get_user_weapon(id);
	
	if (tmpwId == iWeaponsTest[id])
	{
		if (get_gametime() - player_drop_time[id] < 0.30)
		{
			if (active_rune_id[id] >= 0)
			{
				player_drop_rune(id);
				player_drop_time[id] = get_gametime();
				iWeaponsTest[id] = tmpwId;
				
				SetHookChainReturn(ATYPE_INTEGER, 0);
				return HC_SUPERCEDE;
			}
		}
		player_drop_time[id] = get_gametime();
	}
	
	iWeaponsTest[id] = tmpwId;
	return HC_CONTINUE;
}

// 3aбpaть pyны в конце payндa
public DropAllRunes_RoundEnd( )
{
	if (runemod_newround_remove > 0)
	{
		g_iRoundLeft++;
		for(new id = 1; id < MAX_PLAYERS + 1;id++)
		{
			player_drop_rune(id);
			player_drop_all_items(id);
		}
	}
}

public DropAllRunes( )
{
	for(new id = 1; id < MAX_PLAYERS + 1;id++)
	{
		player_drop_rune(id);
		player_drop_all_items(id);
	}
}

// Удалить руны в начале раунда если требуется
public RemoveAllRunes()
{
	spawn_filled_size = 0;
	for(new i = 0; i < spawn_array_size; i++)
	{
		new iEnt = spawn_has_ent[i];
		if (iEnt > 0 && !is_nullent(iEnt))
		{
			set_entvar(iEnt, var_flags, FL_KILLME);
			set_entvar(iEnt, var_nextthink, get_gametime());
			
			new rune_id = rm_get_rune_runeid(iEnt)
			if (rune_id < 0 || rune_id >= runes_registered)
				continue;
				
			new origin_rune_id = rm_get_rune_num(iEnt);
			if (origin_rune_id >= 0 && origin_rune_id != rune_list_id[rune_id] && origin_rune_id < runes_registered)
			{
				rm_remove_rune_callback( rune_list_id[origin_rune_id],iEnt );
			}
				
			rm_remove_rune_callback(rune_list_id[rune_id],iEnt);
			rune_list_count[rune_id] = 0;
		}
		
		runemod_spawned_items = 0;
		runemod_spawned_runes = 0;
		
		if (spawn_has_ent[i] > 0)
			spawn_has_ent[i] = 0;
	}
}

public RestartRound()
{
	if (runemod_restart_cleanup)
	{
		RemoveAllRunes();
	}
}

// Пpeкeш мoдeли pyны и звука поднятия
public plugin_precache()
{
	rm_config_execute();
	
	if(file_exists(runemod_default_model_path,true))
	{
		copy(rune_default_model,charsmax(rune_default_model),runemod_default_model_path);
	}
	else 
	{
		copy(rune_default_model,charsmax(rune_default_model),"models/w_weaponbox.mdl");
	}
	
	rune_default_model_id = precache_model(rune_default_model);
	
	if(file_exists(runemod_default_pickup_path,true))
	{
		// replace first sound/
		precache_generic(runemod_default_pickup_path);
		copy(rune_default_pickup_sound,charsmax(rune_default_pickup_sound),runemod_default_pickup_path);
	}
	else
	{
		copy(rune_default_pickup_sound,charsmax(rune_default_pickup_sound),"sound/items/nvg_on.wav");
	}
}


// Peгиcтpaция нoвoй pyны в бaзoвoм плaгинe (coxpaнeниe в зapaнee пoдгoтoвлeнный cпиcoк)
public RM_RegisterPlugin(PluginIndex,RuneName[],RuneDesc[],Float:RuneColor1,Float:RuneColor2,Float:RuneColor3,rModel[],rSound[],rModelID,RuneGiveName[])
{
	//server_print("INIT RUNE: %i %s %s %f %f %f %s %s %i %s^n", PluginIndex,RuneName,RuneDesc, RuneColor1,RuneColor2,RuneColor3,rModel,rSound,rModelID,RuneGiveName);
	new i = runes_registered;
	
	if (i >= MAX_REGISTER_RUNES)
		return -1;
	
	runes_registered++;
	
	rune_list_id[i] = PluginIndex;
	
	copy(rune_list_name[i],charsmax(rune_list_name[]), RuneName);
	copy(rune_list_descr[i],charsmax(rune_list_descr[]), RuneDesc);
	
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
	
	if( strlen(rSound) > 0 && file_exists( rSound, true ) )
	{
		//server_print("INIT RUNE: SOUND FOUND");
		if (contain(rSound,"sound/") == 0)
			copy(rune_list_sound[i],charsmax(rune_list_sound[]), rSound);
		else 
			copy(rune_list_sound[i],charsmax(rune_list_sound[]), rSound[6]);
	}
	else 
	{
		//server_print("INIT RUNE: SOUND NOT FOUND");
		if (contain(rune_default_pickup_sound,"sound/") == 0)
			copy(rune_list_sound[i],charsmax(rune_list_sound[]), rune_default_pickup_sound);
		else 
			copy(rune_list_sound[i],charsmax(rune_list_sound[]), rune_default_pickup_sound[6]);
	}
	
	rune_list_maxcount[i] = RUNE_MAX_UNLIMITED;
	
	rune_list_model_color[i][0] = RuneColor1;
	rune_list_model_color[i][1] = RuneColor2;
	rune_list_model_color[i][2] = RuneColor3;
	
	return i;
}

public Event_ScreenFade(msgid, msgDest, msgEnt)
{
	if (runemod_screen_highlight && is_real_player(msgEnt) && active_rune_id[msgEnt] >= 0 && !g_bScreenFadeAllowed)
	{
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

// Вернуть количество зарегистрированных рун
public rm_get_runes_count_api()
{
	return runes_registered;
}

// Вернуть номер руны по названию
public rm_get_rune_by_name_api(rune_name[])
{
	for(new i = 0; i < runes_registered;i++)
	{
		if (equali(rune_name,rune_list_name[i]))
			return i;
	}
	
	// FIX AES FLAGS MAX CHAR[30]
	new name_len = strlen(rune_name);
	
	for(new i = 0; i < runes_registered;i++)
	{
		if (strlen(rune_list_name[i]) <= name_len)
			continue;
			
		if (equali(rune_name,rune_list_name[i],name_len))
			return i;
	}
	
	return -1;
}

// Лимит на количество рун 
public RM_MaxRunesAtOneTime(plug_id, num)
{
	for(new i = 0; i < runes_registered;i++)
	{
		if (rune_list_id[i] == plug_id)
			rune_list_maxcount[i] = num;
	}
}

// Форвард из GAMECMS означающий что игрок с GAMECMS подключен
public OnAPIMemberConnected(id, memberId, memberName[])
{
	g_bRegGameCMS[id] = true;
}

// Предупредить игрока о необходимости зарегистрироваться на веб сайте
public rm_print_register_api(id)
{
	if (get_gametime() > g_fLastRegisterPrint[id])
	{
		g_fLastRegisterPrint[id] = get_gametime() + 10.0;
		rm_show_dhud_message(id, DHUD_POS_NOTIFY,{255, 94, 0},10.0,false,"%s: %L",runemod_prefix, LANG_PLAYER, "runemod_print_need_register");
	}
}

// Необходимо зарегистрироваться на веб сайте (GAMECMS) для того что бы поднять руну
public rm_need_gamecms_register_api(plug_id)
{
	for(new i = 0; i < runes_registered;i++)
	{
		if (rune_list_id[i] == plug_id)
			rune_list_gamecms[i] = true;
	}
}

// Руна является предметом (поднял и забыл)
public rm_rune_set_item(plug_id)
{
	for(new i = 0; i < runes_registered;i++)
	{
		if (rune_list_id[i] == plug_id)
			rune_list_isItem[i] = true;
	}
}



// 3aбpaть pyнy пpи cмepти игpoкa 
public CBasePlayer_Killed_Post(pVictim, pAttacker, pGib)
{
	if (is_real_player(pVictim))
	{
		lock_rune_pickup[pVictim] = 0;
		player_drop_rune(pVictim);
		player_drop_all_items(pVictim);
		// После
		g_bUserAlive[pVictim] = false;
	}
}

// 3aбpaть pyнy пpи пoявлeнии игpoкa
public CBasePlayer_Spawn_Post(const id)
{
	if (is_real_player(id))
	{
		if (is_user_alive(id))
			g_bUserAlive[id] = true;
		
		if (runemod_newround_remove > 0)
		{
			lock_rune_pickup[id] = 0;
			player_drop_rune(id);
			player_drop_all_items(id);
		}
		
		if (runemod_rune_shop > 0 && g_bUserAlive[id])
		{
			client_print_color(id, print_team_red, "^4%s^3: %L!",runemod_prefix, LANG_PLAYER, "runemod_print_shopmenu");
		}
		
		if (runemod_custom_spawn_support <= 0)
			return;
		
		static Float:origin[3];
		get_entvar(id, var_origin, origin);

		AddPlayerSpawn(origin);

		for (new i = 0; i < spawn_array_size; i++)
		{
			new iEnt = spawn_has_ent[i];
			if (iEnt > 0 && !is_nullent(iEnt))
			{
				static Float:runeOrigin[3];
				get_entvar(iEnt, var_origin, runeOrigin);

				if (get_distance_f(origin, runeOrigin) < 32.0)
				{
					RemoveRuneEntity(iEnt, i);
				}
			}
		}
	}
}

// Подсветка модели игрока 
public rm_highlight_player(rune_id, id)
{
	if (runemod_player_highlight && is_real_player(id))
	{
		if (rune_id >= 0)
			rg_set_rendering(id, kRenderFxGlowShell, _, rune_list_model_color[rune_id], 10.0);
	}
}

// Подсветка экрана игрока
public rm_highlight_screen(rune_id, id, hpower)
{
	if (runemod_screen_highlight && is_real_player(id))
	{
		static bColor[3];
		bColor[0] = floatround(rune_list_model_color[rune_id][0]);
		bColor[1] = floatround(rune_list_model_color[rune_id][1]);
		bColor[2] = floatround(rune_list_model_color[rune_id][2]);
		if (rune_id >= 0)
		{	
			RM_SCREENFADE(id, bColor , 1.0, 0.0, hpower, FFADE_STAYOUT | FFADE_MODULATE, true,true);
		}
	}
}

// Функция сбрасывает действия всех предметов
public player_drop_all_items(id)
{
	for(new i = 0; i < runes_registered;i++)
	{
		if (rune_list_isItem[i])
			rm_drop_rune_callback(rune_list_id[i], id, i);
	}
}

// Фyнкция зaбиpaeт pyнy и вызывaeт cooтвeтcтвyющyю фyнкцию в плaгинe pyны
public player_drop_rune(id)
{
	if (is_real_player(id))
	{
		if (active_rune_id[id] >= 0)
		{
			new rune_id = active_rune_id[id];
			if (rune_id >= 0)
			{
				if (g_bUserConnected[id])
				{
					new bool:is_item = rune_list_isItem[rune_id];
					rm_drop_notify(id, rune_id, is_item, NOTIFY_DROP);
				}
				rm_drop_rune_callback(rune_list_id[rune_id], id, rune_id);
			}
		}
		active_rune_id[id] = -1;
		rm_reset_highlight(id);
	}
}

stock rm_drop_notify(const id, const rune_id, const bool:is_item, const notify_type = NOTIFY_DROP)
{
    // 1. Объявление переменных
    static username[MAX_NAME_LENGTH];
    static bool:notify_all;
    static message_lang_key[64];
    static message_lang_key_noty[64];
    
    // 2. Определение параметров уведомления
    switch(notify_type) {
        case NOTIFY_DROP: {
            notify_all = bool:runemod_notify_players_drop;
            if(is_item) {
                formatex(message_lang_key, charsmax(message_lang_key), "runemod_drop_item");
                formatex(message_lang_key_noty, charsmax(message_lang_key_noty), "runemod_drop_item_noty");
            } else {
                formatex(message_lang_key, charsmax(message_lang_key), "runemod_drop_rune");
                formatex(message_lang_key_noty, charsmax(message_lang_key_noty), "runemod_drop_rune_noty");
            }
        }
        case NOTIFY_PICKUP: {
            notify_all = bool:runemod_notify_players;
            if(is_item) {
                formatex(message_lang_key, charsmax(message_lang_key), "runemod_pickup_item");
            } else {
                formatex(message_lang_key, charsmax(message_lang_key), "runemod_pickup_rune");
            }
            formatex(message_lang_key_noty, charsmax(message_lang_key_noty), "runemod_player_pickup_noty");
        }
    }
    
    // 3. Получение имени игрока, если нужно
    if(notify_all) {
        get_user_name(id, username, charsmax(username));
    }
    
    // 4. Отправка уведомлений другим игрокам
    for(new i = 1; i <= MAX_PLAYERS; i++) {
        if(!g_bUserConnected[i] || i == id) {
            continue;
        }
        
        if(notify_all) {
            // Уведомление всех игроков
            client_print_color(i, print_team_red, "^4%s^3 %L", runemod_prefix, LANG_PLAYER, message_lang_key_noty, username, LANG_PLAYER, rune_list_name[rune_id]);
        } else {
            // Уведомление только наблюдающих
            new specTarget = get_entvar(i, var_iuser2);
            if(specTarget == id) {
                client_print_color(i, print_team_red, "^4%s^3 %L", runemod_prefix, LANG_PLAYER, message_lang_key, LANG_PLAYER, rune_list_name[rune_id]);
                
                // Дополнительное сообщение для рун
                if(notify_type == NOTIFY_PICKUP && !is_item) {
                    client_print_color(i, print_team_red, "^4%s^3 %L", runemod_prefix, LANG_PLAYER, "runemod_hintdrop_rune");
                }
            }
        }
    }
    
    // 5. Отправка уведомления самому игроку
    if(notify_type == NOTIFY_PICKUP) {
        client_print_color(id, print_team_red, "^4%s^3 %L", runemod_prefix, LANG_PLAYER, message_lang_key, LANG_PLAYER, rune_list_name[rune_id]);
        
        if(!is_item) {
            client_print_color(id, print_team_red, "^4%s^3 %L", runemod_prefix, LANG_PLAYER, "runemod_hintdrop_rune");
        }
        
        // Проигрывание звука подбора
        client_cmd(id, "spk ^"%s^"", rune_list_sound[rune_id]);
    } else {
        client_print_color(id, print_team_red, "^4%s^3 %L", runemod_prefix, LANG_PLAYER, message_lang_key, LANG_PLAYER, rune_list_name[rune_id]);
    }
}

// Сообщение о том что действие предмета прекратилось
public rm_drop_item_api(plug_id,id)
{
	new rune_id = get_runeid_by_pluginid(plug_id);
	if (rune_id >= 0 && g_bUserConnected[id])
	{
		rm_drop_notify(id, rune_id, true, NOTIFY_DROP);
	}
}

// Сообщение о том что действие предмета прекратилось по номеру руны
public rm_drop_item_api_by_rune_id(rune_id,id)
{
	if (rune_id >= 0 && g_bUserConnected[id])
	{
		static username[MAX_NAME_LENGTH];
		if (runemod_notify_players_drop)
			get_user_name(id,username,charsmax(username));
						
		static iPlayers[ 32 ], iNum;
		
		if (runemod_notify_players_drop)
			get_players( iPlayers, iNum, "ch" );
		else 
			get_players( iPlayers, iNum, "bch" );
			
		for( new i = 0; i < iNum; i++ )
		{
			new spec_id = iPlayers[ i ];
			if (runemod_notify_players_drop)
			{
				if ( spec_id != id )
				{
					client_print_color(spec_id, print_team_red, "^4%s^3 %L",runemod_prefix, LANG_PLAYER, "runemod_drop_item_noty", username, LANG_PLAYER, rune_list_name[rune_id]);
				}
			}
			else 
			{
				new specTarget = get_entvar(spec_id, var_iuser2);
				if (specTarget == id)
				{
					client_print_color(spec_id, print_team_red, "^4%s^3 %L",runemod_prefix, LANG_PLAYER, "runemod_drop_item", LANG_PLAYER, rune_list_name[rune_id]);
				}
			}
		}
		
		client_print_color(id, print_team_red, "^4%s^3 %L",runemod_prefix, LANG_PLAYER, "runemod_drop_item", LANG_PLAYER, rune_list_name[rune_id]);
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
public rm_is_player_has_rune(id)
{
	if (is_real_player(id))
	{
		return active_rune_id[id] >= 0;
	}
	return 0;
}

// Получить активную руну игрока
public rm_player_active_rune(id)
{
	if (is_real_player(id))
	{
		return active_rune_id[id];
	}
	return -1;
}

// Сбросить подсветку игрока
public rm_reset_highlight(id)
{
	if (g_bUserConnected[id])
	{
		RM_SCREENFADE(id, _, _, _,_,true,true);
		if (!is_nullent(id))
			rg_set_rendering(id);
	}
}

// Фyнкция вызывaeтcя в плaгинax pyн, пoзвoляeт пpинyдитeльнo зacтaвить бaзoвый плaгин oтключить pyнy игpoкy.
public rm_drop_rune_api(plug_id, id)
{
	if (is_real_player(id) && active_rune_id[id] >= 0 && rune_list_id[active_rune_id[id]] == plug_id)
		player_drop_rune(id); 
}

// Устанавливает стоимость руны
public rm_set_rune_cost_api(plug_id, imoney)
{
	for(new i = 0; i < runes_registered;i++)
	{
		if (rune_list_id[i] == plug_id)
			rune_list_icost[i] = imoney;
	}
}

// Устанавливает стоимость руны
public rm_set_rune_cost_api_by_rune_id(rune_id, imoney)
{
	if (rune_id >= 0 && rune_id < runes_registered)
		rune_list_icost[rune_id] = imoney;
}

// Запретить создание руны на карте
public rm_disable_rune_api(rune_id, rune_status)
{
	rune_list_disabled[rune_id] = rune_status > 0;
}

// Фyнкция пpoвepяeт нe нaxoдитcя ли тoчкa pядoм c тoчкaми пoявлeния дpyгиx pyн
public bool:is_no_rune_point( Float:coords[3] )
{
	for (new i = 0; i < spawn_array_size; i++)
	{
		if ( get_distance_f(coords,spawn_pos[i]) < float(runemod_spawn_distance) )
			return false;
	}
	return true;
}


// 3aпoлняeм cпaвны пo кoopдинaтaм игpoкoв. Пpocтeйший cпocoб нe тpeбyющий coздaния фaйлoв co cпaвнaми.
// Пpeимeщecтвo в тoм чтo кaждый paз coздaютcя нoвыe cпaвны.
public fill_new_spawn_points( )
{
	static iPlayers[ 32 ], iNum;
	static Float:fOrigin[3];
	static Float:fMins[3];
	
	if (spawn_array_size >= MAX_SPAWN_POINTS || spawn_array_size >= runemod_spawncount)
	{
#if defined DEBUG_ENABLED
		log_amx("[TRACE] No free spawn slots! %i of %i/%i filled!", spawn_array_size, MAX_SPAWN_POINTS,runemod_spawncount);
#endif
	}
	else 
	{
	#if defined DEBUG_ENABLED
		new tmpArraySize = spawn_array_size;
	#endif		
		get_players( iPlayers, iNum, "ah" );
		for( new i = 0; i < iNum; i++ )
		{
			new id = iPlayers[ i ];
			if (is_user_onground(id))
			{
				get_entvar(id, var_origin, fOrigin );
				if (is_no_spawn_point(fOrigin) && is_no_custom_spawn(fOrigin) && is_no_rune_point(fOrigin) && rm_is_hull_vacant(id, fOrigin, HULL_HUMAN,g_pCommonTr) )
				{
					fOrigin[2] += 25.0;
					if (rm_is_hull_vacant(id, fOrigin, HULL_HUMAN,g_pCommonTr))
					{
						get_entvar(id, var_absmin, fMins );
						fOrigin[2] = fMins[2] + 4.0;
						for( new n = 0; n < spawn_array_size; n++)
						{
							if (spawn_has_ent[n] < 0)
							{
								spawn_pos[n] = fOrigin;
								spawn_has_ent[n] = 0;
								return;
							}
						}
						
						spawn_pos[spawn_array_size] = fOrigin;
						spawn_has_ent[spawn_array_size] = 0;
						
						spawn_array_size++;
						if (spawn_array_size >= MAX_REGISTER_RUNES || spawn_array_size >= runemod_spawncount)
							return;
					}
				}
			}
		}
		#if defined DEBUG_ENABLED
		if (tmpArraySize == spawn_array_size)
		{
			log_amx("[TRACE] No added spawn points... Tracing...");
			for( new i = 0; i < iNum; i++ )
			{
				new id = iPlayers[ i ];
				if (is_user_onground(id))
				{
					get_entvar(id, var_origin, fOrigin );
					if (!is_no_spawn_point(fOrigin) || !is_no_custom_spawn(fOrigin))
					{
						if (!is_no_custom_spawn(fOrigin))
						{
							log_amx("[TRACE] User %i on CUSTOM spawn point!", id );
						}
						else 
						{
							log_amx("[TRACE] User %i on spawn point!", id );
						}
					}
					else if (!is_no_rune_point(fOrigin))
					{
						log_amx("[TRACE] User %i has near runes [%f,%f,%f]!", id, fOrigin[0],fOrigin[1],fOrigin[2] );
						for (new i = 0; i < spawn_array_size; i++)
						{
							if ( get_distance_f(fOrigin,spawn_pos[i]) < float(runemod_spawn_distance) )
							{
								log_amx("[TRACE] Found rune spawn %i at [%f,%f,%f]!", i, spawn_pos[i][0],spawn_pos[i][1],spawn_pos[i][2] );
								break;
							}
						}
					}
					else if (!rm_is_hull_vacant(id, fOrigin, HULL_HUMAN,g_pCommonTr))
					{
						log_amx("[TRACE] User %i no vacant hull!", id );
					}
					else 
					{
						fOrigin[2] += 25.0;
						if (!rm_is_hull_vacant(id, fOrigin, HULL_HUMAN,g_pCommonTr))
						{
							log_amx("[TRACE] User %i no vacant hull Z+25.0!", id );
						}
					}
				}
				else 
				{
					log_amx("[TRACE] User %i no ground!", id );
				}
			}
		}
		#endif	
	}
	
	if (runemod_spawn_lifetime > 0 && spawn_array_size > 0 && get_gametime() - g_fLastSpawnRefreshTime > runemod_spawn_lifetime)
	{
		if (g_iRefreshSpawnId >= spawn_array_size)
			g_iRefreshSpawnId = 0;
		
		if (spawn_has_ent[spawn_array_size] == 0)
		{
			get_players( iPlayers, iNum, "ach" );
			
			for( new i = 0; i < iNum; i++ )
			{
				new id = iPlayers[ i ];
				if (is_user_onground(id))
				{
					get_entvar(id, var_origin, fOrigin );
					if (is_no_spawn_point(fOrigin) && is_no_custom_spawn(fOrigin) && is_no_rune_point(fOrigin) && rm_is_hull_vacant(id, fOrigin, HULL_HUMAN,g_pCommonTr) )
					{
						// Для тех что приподняты
						fOrigin[2] += 25.0;
						if (rm_is_hull_vacant(id, fOrigin, HULL_HUMAN,g_pCommonTr))
						{
							g_fLastSpawnRefreshTime = get_gametime();
							
							get_entvar(id, var_absmin, fMins );
							fOrigin[2] = fMins[2] + 4.0;
							spawn_pos[g_iRefreshSpawnId] = fOrigin;
							break;
						}
					}
				}
			}
		}
		g_iRefreshSpawnId++;
	}

}

// Меняет руну местами
public rm_swap_rune_id( iEnt, new_rune_id )
{
	if (is_nullent( iEnt ))
	{
		//log_amx("Error! Invalid entity %i for swap function", iEnt);
		return;
	}
	
	if (runemod_random_mode > 0)
	{
		set_entvar(iEnt, var_model,rune_default_model);
		set_entvar(iEnt, var_modelindex,rune_default_model_id);
	}
	else 
	{
		set_entvar(iEnt, var_model,rune_list_model[new_rune_id]);
		set_entvar(iEnt, var_modelindex, rune_list_model_id[new_rune_id]);
	}
	
	if (!rune_list_isItem[new_rune_id] && runemod_random_mode == 0)
	{
		set_entvar(iEnt, var_renderfx, kRenderFxGlowShell);
		set_entvar(iEnt, var_rendercolor,rune_list_model_color[new_rune_id]);
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
	
	if (!rune_list_isItem[new_rune_id] && runemod_random_mode <= 0)
		set_entvar(iEnt, var_avelocity,Float:{0.0,125.0,0.0});
	else 
		set_entvar(iEnt, var_avelocity,Float:{0.0,0.0,0.0});
	
	rm_set_rune_runeid(iEnt,new_rune_id);
	
	static Float:fOrigin[3];
	fOrigin = spawn_pos[rm_get_rune_spawnid(iEnt)];
	
	if (!rune_list_isItem[new_rune_id] && runemod_random_mode <= 0)
		fOrigin[2] += 25.0;
	
	entity_set_origin(iEnt, fOrigin);
}

// Проверить не является ли руна предметом?
public rm_is_rune_item_api(rune_id)
{
	return rune_list_isItem[rune_id] ? 1 : 0;
}

// Coбcтвeннo coздaeм oднy pyнy
public bool:spawn_one_rune(rune_id, spawn_id)
{
#if defined DEBUG_ENABLED
	log_amx("[TRACE] Trying to create new rune '%s' in spawn '%i' max spawns '%i'", rune_list_name[rune_id], spawn_id, spawn_array_size);
#endif
	if (rune_list_isItem[rune_id])
	{
		if (runemod_spawned_items >= runemod_max_items)
		{
#if defined DEBUG_ENABLED
			log_amx("[TRACE] Can't create due runemod_max_items limit reached. [%d of %d]", runemod_spawned_items,runemod_max_items);
#endif
			return false;
		}
	}
	else 
	{
		if (runemod_spawned_runes >= runemod_max_runes)
		{
#if defined DEBUG_ENABLED
			log_amx("[TRACE] Can't create due runemod_max_runes limit reached. [%d of %d]", runemod_spawned_runes,runemod_max_runes);
#endif
			return false;
		}
	}

	new iEnt = rg_create_entity("info_target");
	if (!iEnt || is_nullent(iEnt))
	{
		return false;
	}
	
	rune_list_count[rune_id]++;
	
	spawn_filled_size++;
	spawn_has_ent[spawn_id] = iEnt;

	set_entvar(iEnt, var_classname, RUNE_CLASSNAME);
	
	if (runemod_random_mode > 0)
	{
		set_entvar(iEnt, var_model,rune_default_model);
		set_entvar(iEnt, var_modelindex,rune_default_model_id);
	}
	else 
	{
		set_entvar(iEnt, var_model,rune_list_model[rune_id]);
		set_entvar(iEnt, var_modelindex, rune_list_model_id[rune_id]);
	}
	
	if (!rune_list_isItem[rune_id] && runemod_random_mode == 0)
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
	
	set_entvar(iEnt, var_solid, SOLID_TRIGGER );
	set_entvar(iEnt, var_movetype, MOVETYPE_FLY);
	set_entvar(iEnt, var_velocity, Float:{0.0,0.0,0.0});
	set_entvar(iEnt, var_gravity, 0.0);
	
	if (!rune_list_isItem[rune_id] && runemod_random_mode <= 0)
		set_entvar(iEnt, var_avelocity,Float:{0.0,125.0,0.0});
		
	set_entvar(iEnt, var_sequence, ACT_IDLE);
	set_entvar(iEnt, var_framerate, 1.0);
	
	entity_set_size(iEnt, Float:{-13.0,-13.0,-1.0}, Float:{13.0,13.0,14.0});
	
	/*set_entvar(iEnt, var_mins, Float:{-13.0,-13.0,-1.0});
	set_entvar(iEnt, var_maxs, Float:{13.0,13.0,14.0});*/
	
	
	rm_set_rune_runeid(iEnt,rune_id);
	rm_set_rune_spawnid(iEnt,spawn_id);
	rm_set_rune_num(iEnt, -1);

	SetTouch(iEnt,"rune_touch");
	
	static Float:fOrigin[3];
	fOrigin = spawn_pos[spawn_id];
	
	if (!rune_list_isItem[rune_id] && runemod_random_mode <= 0)
		fOrigin[2] += 25.0;
	
	entity_set_origin(iEnt, fOrigin);
	
	
	spawn_iEnt_Origin[spawn_id][0] = floatround(fOrigin[0]);
	spawn_iEnt_Origin[spawn_id][1] = floatround(fOrigin[1]);
	spawn_iEnt_Origin[spawn_id][2] = floatround(fOrigin[2]);
	
	
	if (!rm_spawn_rune_callback(rune_list_id[rune_id],iEnt,rune_id))
	{
		spawn_filled_size--;
		spawn_has_ent[spawn_id] = 0;
		rune_list_count[rune_id]--;
		set_entvar(iEnt, var_nextthink, get_gametime())
		set_entvar(iEnt, var_flags, FL_KILLME);
		return false;
	}
	
	if (rune_list_isItem[rune_id])
	{
		runemod_spawned_items++;
	}
	else 
	{
		runemod_spawned_runes++;
	}

	
	if (runemod_notify_spawns)
	{
		client_print_color(0, print_team_red, "^4%s^3 %L", runemod_prefix, LANG_PLAYER, "runemod_print_rune_spawned", LANG_PLAYER, rune_list_name[rune_id]);
	}
	
	return true;
}

public bool:rm_give_rune_to_player_api( player_id, rune_id )
{
	new bool:is_item = rune_list_isItem[rune_id];
	if (active_rune_id[player_id] < 0 || is_item)
	{
		if (!g_bRegGameCMS[player_id] && (rune_list_gamecms[rune_id] || runemod_only_gamecms > 0))
		{
			rm_print_register_api(player_id);
			return false;
		}
		
		if (!is_item)
			active_rune_id[player_id] = rune_id;
		
		if (rm_give_rune_callback(rune_list_id[rune_id],player_id, 0, rune_id))
		{
			rm_drop_notify(player_id, rune_id, is_item, NOTIFY_PICKUP);
			
			client_cmd(player_id,"spk ^"%s^"", rune_list_sound[rune_id]);
			
			return true;
		}
		else 
		{
			if (!is_item)
				active_rune_id[player_id] = -1;
			
			return false;
		}
	}
	return false;
}

// Coбытиe пpoиcxoдит пpи cтoлкнoвeнии игpoкa c pyнoй, ecли pyны нeт, дaeм игpoкy нoвyю, ocвoбoждaeм cпaвн и yдaляeм мoдeль pyны
public rune_touch(const rune_ent, const player_id)
{
	if (!is_nullent(rune_ent) && is_real_player(player_id) && !lock_rune_pickup[player_id])
	{
		new rune_id = rm_get_rune_runeid(rune_ent)
		if (rune_id < 0 || rune_id >= runes_registered || !g_bUserAlive[player_id])
			return PLUGIN_CONTINUE;
			
		if (runemod_bot_pickup == 0 && g_bUserBot[player_id])
		{
			return PLUGIN_CONTINUE;
		}
		
		new bool:is_item = rune_list_isItem[rune_id];
		if (active_rune_id[player_id] < 0 || is_item)
		{
			if (!g_bRegGameCMS[player_id] && (rune_list_gamecms[rune_id] || runemod_only_gamecms > 0))
			{
				rm_print_register_api(player_id);
				return PLUGIN_CONTINUE;
			}
			
			if (!is_item)
				active_rune_id[player_id] = rune_id;
				
			if (rm_give_rune_callback(rune_list_id[rune_id], player_id, rune_ent, rune_id))
			{
				new spawn_id = rm_get_rune_spawnid(rune_ent);
				
				spawn_has_ent[spawn_id] = 0;
				spawn_filled_size--;
				
				set_entvar(rune_ent, var_nextthink, get_gametime())
				set_entvar(rune_ent, var_flags, FL_KILLME);
				
				rm_remove_rune_callback(rune_list_id[rune_id],rune_ent);
				
				new origin_rune_id = rm_get_rune_num(rune_ent);
				if (origin_rune_id >= 0 && origin_rune_id != rune_list_id[rune_id] && origin_rune_id < runes_registered)
				{
					rm_remove_rune_callback( rune_list_id[origin_rune_id],rune_ent );
				}
				
				rune_list_count[rune_id]--;
				
				if (is_item)
				{
					runemod_spawned_items--;
					client_print_color(player_id, print_team_red, "^4%s^3 %L", runemod_prefix, LANG_PLAYER, "runemod_pickup_item", LANG_PLAYER, rune_list_name[rune_id]);
				}
				else 
				{
					runemod_spawned_runes--;
					client_print_color(player_id, print_team_red, "^4%s^3 %L", runemod_prefix, LANG_PLAYER, "runemod_pickup_rune", LANG_PLAYER, rune_list_name[rune_id]);
					client_print_color(player_id, print_team_red, "^4%s^3 %L", runemod_prefix, LANG_PLAYER, "runemod_hintdrop_rune");
				}
				
				static username[MAX_NAME_LENGTH];
				if (runemod_notify_players)
					get_user_name(player_id,username,charsmax(username));
				
				static iPlayers[ 32 ], iNum;
				if (runemod_notify_players)
					get_players( iPlayers, iNum, "ch" );
				else 
					get_players( iPlayers, iNum, "bch" );
					
				for( new i = 0; i < iNum; i++ )
				{
					new spec_id = iPlayers[ i ];
					if (runemod_notify_players)
					{
						if ( spec_id != player_id )
						{
							client_print_color(spec_id, print_team_red, "^4%s^3 %L", runemod_prefix, LANG_PLAYER, "runemod_player_pickup_noty", username, LANG_PLAYER, rune_list_name[rune_id]);
						}
					}
					else 
					{
						new specTarget = get_entvar(spec_id, var_iuser2);
						if (specTarget == player_id)
						{
							if (is_item)
							{
								client_print_color(spec_id, print_team_red, "^4%s^3 %L", runemod_prefix, LANG_PLAYER, "runemod_pickup_item", LANG_PLAYER, rune_list_name[rune_id]);
							}
							else 
							{
								client_print_color(spec_id, print_team_red, "^4%s^3 %L", runemod_prefix, LANG_PLAYER, "runemod_pickup_rune", LANG_PLAYER, rune_list_name[rune_id]);
								client_print_color(spec_id, print_team_red, "^4%s^3 %L", runemod_prefix, LANG_PLAYER, "runemod_hintdrop_rune");
							}
						}
					}
				}
				
				client_cmd(player_id,"spk ^"%s^"", rune_list_sound[rune_id]);
			}
			else 
			{
				if (!is_item)
					active_rune_id[player_id] = -1;
			}
		}
	}
	return PLUGIN_CONTINUE;
}

// Фунция подходящий номер руны для создания
public rm_get_next_rune( spawn_id )
{
	new rune_id = -1;
	new max_rune_count = 999;
	
	// Псевдо "рандом"
	for(new i = rune_last_created + 1; i < runes_registered; i++ )
	{
		if (random_num(1,10) > 5 || rune_list_disabled[i]
			|| (runemod_only_items && !rune_list_isItem[i]))
		{
			continue;
		}
		new cur_rune_count = rune_list_count[i];
		if (cur_rune_count <= max_rune_count && cur_rune_count < rune_list_maxcount[i])
		{
			if (cur_rune_count == max_rune_count && random_num(1,10) > 5)
				break;
			rune_id = i;
			max_rune_count = cur_rune_count;
		}
	}
	
	for(new i = 0; i < rune_last_created; i++ )
	{
		if (random_num(1,10) > 5 || rune_list_disabled[i]
			|| (runemod_only_items && !rune_list_isItem[i]))
		{
			continue;
		}
		new cur_rune_count = rune_list_count[i];
		if (cur_rune_count <= max_rune_count && cur_rune_count < rune_list_maxcount[i])
		{
			if (cur_rune_count == max_rune_count && random_num(1,10) > 5)
				break;
			rune_id = i;
			max_rune_count = cur_rune_count;
		}
	}
	
	// Если не найдено подходящей руны, берем любую
	if (rune_id == -1)
	{
		for(new i = 0; i < runes_registered; i++ )
		{
			new cur_rune_count = rune_list_count[i];
			if (cur_rune_count < rune_list_maxcount[i])
			{
				rune_id = i;
				break;
			}
		}
	}
	
	rune_last_created = rune_id;
	return rune_id;
}

new spawn_runes_tries = 0;
// Фyнкция coздaющaя pyны
public spawn_runes( )
{
	if (spawn_array_size == 0)
		return;
	new bool:reversed = random_num(1,10) > 5;
	new random_spawn = random_num(1,spawn_array_size) - 1;
	new need_runes = runemod_perspawn;
#if defined DEBUG_ENABLED
	log_amx("[TRACE] Need create '%i' runes.", need_runes);
#endif
	static iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum ,"ah" );
	
	if (iNum < runemod_min_players || iNum > runemod_max_players)
	{
#if defined DEBUG_ENABLED
		log_amx("[TRACE] Can't create rune because player limit reached!");
#endif
		return;
	}
	
	if (spawn_filled_size >= spawn_array_size)
	{
#if defined DEBUG_ENABLED
		log_amx("[TRACE] No free spawn points! %i of %i filled!", spawn_filled_size, spawn_array_size);
#endif
		return;
	}
		
	if (spawn_runes_internal(random_spawn))
	{
		need_runes--;
		if (need_runes <= 0)
		{
#if defined DEBUG_ENABLED
			log_amx("Created %d runes!", runemod_perspawn - need_runes);
#endif
			return;
		}
	}

	if (!reversed)
	{
		for(new i = 0; i < spawn_array_size; i++)
		{
			if (spawn_runes_internal(i))
			{
				need_runes--;
			}
			
			if (need_runes <= 0)
			{
#if defined DEBUG_ENABLED
				log_amx("Created %d runes!", runemod_perspawn - need_runes);
#endif
				return;
			}
		}
	}
	else 
	{
		for(new i = spawn_array_size - 1; i >= 0; i--)
		{
			if (spawn_runes_internal(i))
			{
				need_runes--;
			}
			
			if (need_runes <= 0)
			{
#if defined DEBUG_ENABLED
				log_amx("Created %d runes!", runemod_perspawn - need_runes);
#endif
				return;
			}
		}
	}
	
	if (spawn_runes_tries > 1)
	{
		spawn_runes_tries = 0;
		for(new i = 0; i < spawn_array_size; i++)
		{
			if (spawn_runes_internal(i,true))
			{
				need_runes--;
			}
			
			if (need_runes <= 0)
			{
#if defined DEBUG_ENABLED
				log_amx("Created %d runes!", runemod_perspawn - need_runes);
#endif
				return;
			}
		}
	}
	
	if (need_runes == runemod_perspawn)
	{
		spawn_runes_tries++;
#if defined DEBUG_ENABLED
		if (spawn_runes_tries > 1)
		{
			log_amx("Warning! I can't create any runes with current settings.");
			log_amx("Please check your runemod and runes config!");
		}
#endif
	}
	else 
	{
		spawn_runes_tries = 0;
#if defined DEBUG_ENABLED
		log_amx("Created %d runes!", runemod_perspawn - need_runes);
#endif
	}
}

bool:spawn_runes_internal(spawn_id, bool:forceview = false)
{
	if (spawn_has_ent[spawn_id] > 0 || spawn_has_ent[spawn_id] < 0)
		return false;
	
	if (runemod_spawn_nolook && !forceview)
	{
		for(new i = 1; i <= MAX_PLAYERS; i++)
		{
			if (g_bUserConnected[i] && g_bUserAlive[i] && !g_bUserBot[i])
			{
				new lookplayer = i;
				if (fm_is_in_viewcone_my(lookplayer, spawn_pos[spawn_id]) && fm_is_visible_my(lookplayer, spawn_pos[spawn_id]))
				{
					return false;
				}
			}
		}
	}
	
	if (is_no_player_point(spawn_pos[spawn_id],float(runemod_player_distance))
		|| (forceview && is_no_player_point(spawn_pos[spawn_id],float(runemod_player_distance) / 1.5)) )
	{
		new rune_id = rm_get_next_rune(spawn_id);
		
		if (rune_id >= 0 && rune_id < runes_registered)
		{
			return spawn_one_rune( rune_id, spawn_id );
		}
		else 
		{
#if defined DEBUG_ENABLED
			log_amx("[TRACE] No available runes. Please check all runes configs for errors.");
#endif
		}
	}
	return false;
}

// Taймep coздaния cпaвнoв и зaпoлнeния иx pyнaми
public RM_SPAWN_RUNE()
{
#if defined DEBUG_ENABLED
	log_amx("[TRACE] RM_SPAWN_RUNE tick");
#endif
	if (runemod_active && !g_bCurrentMapIgnored)
	{
		fill_new_spawn_points( );
		if (runes_registered > 0 && g_iRoundLeft >= runemod_start_round)
			spawn_runes( );
	}
	
	for(new i = 0; i < spawn_array_size; i++)
	{
		new iEnt = spawn_has_ent[i];
		if (iEnt > 0 && (is_nullent(iEnt) || !is_valid_ent(iEnt)))
		{
			spawn_has_ent[i] = 0;
			spawn_filled_size--;
			log_error(AMX_ERR_NOTFOUND, "[CRITICAL ERROR] Spawn point %d corrupted by another plugin!!!!!!",i);
		}
	}
	
	set_task(float(runemod_spawntime), "RM_SPAWN_RUNE", SPAWN_SEARCH_TASK_ID);
}

// Фyнкция oбнoвляющaя HUD нa экpaнe игpoкa c инфopмaциeй o pyнe.
public RM_UPDATE_HUD_RUNE( id, rune_ent )
{
	new rune_id = rm_get_rune_runeid(rune_ent);
	set_hudmessage(0, 50, 255, -1.0, 0.16, 0, 0.1, 0.5, 0.02, 0.02, HUD_CHANNEL_ID);
	ShowSyncHudMsg(id, HUD_SYNS_1, "%L^n%L^n",LANG_PLAYER, "runemod_hud_rune_name", LANG_PLAYER, rune_list_name[rune_id], LANG_PLAYER, "runemod_hud_rune_description", LANG_PLAYER, rune_list_descr[rune_id]);
}

// Информация о поднятой руне
public RM_UPDATE_HUD( id, rune_id )
{
	set_hudmessage(20, 255, 20, -1.0, 0.80, 0, 0.1, UPDATE_RUNE_DESCRIPTION_HUD_TIME + 0.25, 0.02, 0.02, HUD_CHANNEL_ID_2);
	ShowSyncHudMsg(id, HUD_SYNS_2, "%L: %L", LANG_PLAYER, rune_list_name[rune_id], LANG_PLAYER, rune_list_descr[rune_id]);
}

// Обновляет описание рун всем игрокам
public UPDATE_RUNE_DESCRIPTION(taskid)
{
	if (runemod_active && !g_bCurrentMapIgnored)
	{
		for(new i = 1; i <= MAX_PLAYERS; i++)
		{
			if (g_bUserConnected[i] && g_bUserAlive[i] && !g_bUserBot[i])
			{
				if (active_rune_id[i] >= 0)
				{
					RM_UPDATE_HUD(i, active_rune_id[i]);
				}
			}
		}

		for(new i = 1; i <= MAX_PLAYERS; i++)
		{
			if (!g_bUserConnected[i] || g_bUserAlive[i])
				continue;

			new bool:highlightfound = false;
			new specTarget = get_entvar(i, var_iuser2);
			if (is_real_player(specTarget) && active_rune_id[specTarget] >= 0)
			{
				RM_UPDATE_HUD(i, active_rune_id[specTarget]);
				if (!highlightfound && runemod_screen_highlight > 0)
				{
					highlightfound = true;
					rm_highlight_screen(active_rune_id[specTarget], i, RUNEMODE_DEFAULT_HIGHLIGHT_POWER);
				}
			}
			if (!highlightfound && runemod_screen_highlight > 0)
			{
				rm_reset_highlight(i);
			}
		}
	}
}

// Функций отвечающая за описание предмета на экране
// TODO: Можно улучшить (но тогда увеличиться нагрузка слегка)
public user_think(id)
{
	static iMaxDistance,iCurDistance,iEnt,n;
	
	if (runemod_active && !g_bCurrentMapIgnored && runemod_random_mode == 0)
	{
		if (g_bUserAlive[id])
		{
			static iOriginStart[3];
			static iOriginEnd[3];
			
			get_user_origin( id, iOriginStart, Origin_Eyes );
			get_user_origin( id, iOriginEnd, Origin_AimEndEyes );
			
			iMaxDistance = get_distance(iOriginStart,iOriginEnd);
			
			if (iMaxDistance > 0)
			{
				static Float:fEntOriginStart[3];
				
				fEntOriginStart[0] = (float(iOriginEnd[0] - iOriginStart[0]) / iMaxDistance);
				fEntOriginStart[1] = (float(iOriginEnd[1] - iOriginStart[1]) / iMaxDistance);
				fEntOriginStart[2] = (float(iOriginEnd[2] - iOriginStart[2]) / iMaxDistance);

				for(n = 0; n < spawn_array_size;n++)
				{
					iEnt = spawn_has_ent[n];
					if (iEnt <= 0)
						continue;
					iCurDistance = get_distance(iOriginStart,spawn_iEnt_Origin[n]);
					if (iCurDistance < iMaxDistance)
					{
						static iEntOriginEnd[3];
						iEntOriginEnd[0] = floatround(fEntOriginStart[0] * iCurDistance + iOriginStart[0]);
						iEntOriginEnd[1] = floatround(fEntOriginStart[1] * iCurDistance + iOriginStart[1]);
						iEntOriginEnd[2] = floatround(fEntOriginStart[2] * iCurDistance + iOriginStart[2]);
						
						if (get_distance(iEntOriginEnd,spawn_iEnt_Origin[n]) < 25)
						{
							static Float:fOrigin[3];
							fOrigin[0] = float(spawn_iEnt_Origin[n][0]);
							fOrigin[1] = float(spawn_iEnt_Origin[n][1]);
							fOrigin[2] = float(spawn_iEnt_Origin[n][2]);
							if (fm_is_visible_my(id, fOrigin, 1))
							{
								static Float:fOrigin2[3];
								get_entvar(iEnt,var_origin,fOrigin2);
								if (get_distance_f(fOrigin, fOrigin2) > 2.5)
								{
									spawn_iEnt_Origin[n][0] = floatround(fOrigin2[0]);
									spawn_iEnt_Origin[n][1] = floatround(fOrigin2[1]);
									spawn_iEnt_Origin[n][2] = floatround(fOrigin2[2]);
									spawn_pos[n] = fOrigin2;
								}
								else 
								{
									RM_UPDATE_HUD_RUNE(id,iEnt);
								}
							}
							break;
						}
					}
				}
			}
		}
	}
}

public rm_get_shoprunescount()
{
	new iRunes = 0;
	new imaxmoney = get_pcvar_num(mp_maxmoney);
	if (imaxmoney <= 0)
		imaxmoney = 16000;
	for(new i = 0; i < runes_registered;i++)
	{
		if (rune_list_icost[i] > 0)
		{
			iRunes++;
		}
		//trial hardcode. FIXME
		if (rune_list_icost[i] > imaxmoney)
			rune_list_icost[i] = imaxmoney;
	}
	
	return iRunes;
}

public rm_shopmenu(id)
{
	new ishoprunes = rm_get_shoprunescount();
	new iacc = get_member(id,m_iAccount);
	if (ishoprunes == 0)
	{
		return PLUGIN_CONTINUE;
	}
	static tmpmenuitem[190];
	formatex(tmpmenuitem, charsmax(tmpmenuitem),"%L",id,"runemod_menu_shopmenu");
	
	new vmenu = menu_create(tmpmenuitem, "rm_shopmenu_handler")
	static runeidstr[16];
	for(new i = 0; i < runes_registered; i++)
	{
		if (rune_list_icost[i] > 0 && (!runemod_only_items || rune_list_isItem[i]) )
		{
			if (rune_list_icost[i] <= iacc )
				formatex(tmpmenuitem, charsmax(tmpmenuitem), "\y%L\r[\w%d\r]",id, rune_list_name[i],rune_list_icost[i]);
			else 
				formatex(tmpmenuitem, charsmax(tmpmenuitem), "\y%L\r[%d]", id, rune_list_name[i],rune_list_icost[i]);
				
			num_to_str(i,runeidstr,charsmax(runeidstr));
			menu_additem(vmenu, tmpmenuitem, runeidstr);
		}
	}
	menu_display(id, vmenu, 0)
	return PLUGIN_HANDLED;
}

public rm_shopmenu_handler(id, vmenu, item)
{
	if (item == MENU_EXIT || !g_bUserConnected[id])
	{
		menu_destroy(vmenu);
		return PLUGIN_HANDLED;
	}

	static data[6], iName[64];
	new accs, callback;
	menu_item_getinfo(vmenu, item, accs, data, 5, iName, 63, callback);

	if (equali(data, "exit"))
	{
		menu_destroy(vmenu);
		return PLUGIN_HANDLED;
	}

	new iaccount = get_member(id,m_iAccount);
	new key = str_to_num(data);
	
	if (key >= 0 && key < runes_registered)
	{
		new irunecost = rune_list_icost[key];
		if (irunecost <= iaccount)
		{
			new is_item = rune_list_isItem[key];
			if (is_item || active_rune_id[id] < 0)
			{
				if (rm_give_rune_to_player_api(id,key))
				{
					rg_add_account(id,iaccount - irunecost,AS_SET);
				}
				else 
				{
					client_print_color(id, print_team_red, "^4%s^3: ^1%L^3", runemod_prefix, LANG_PLAYER, "runemod_print_noneed_this_item");
				}
			}
			else 
			{
				client_print_color(id, print_team_red, "^4%s^3: ^1%L^3", runemod_prefix, LANG_PLAYER, "runemod_print_need_drop_rune");
			}
		}
		else 
		{
			client_print_color(id, print_team_red, "^4%s^3: ^1%L^3", runemod_prefix, LANG_PLAYER, "runemod_print_need_money");
		}
	}

	menu_destroy(vmenu);
	return PLUGIN_HANDLED;
}


public rm_runeshop(id)
{
	if (runemod_rune_shop <= 0)
	{
		return PLUGIN_CONTINUE;
	}
	return rm_shopmenu(id);
}

public rm_buy_rune_api(id,rune_name[])
{
	if (!is_real_player(id) || !g_bUserAlive[id])
	{
		return 0;
	}
	new rune_id = rm_get_rune_by_name_api(rune_name);
	if (rune_id == -1)
		return 0;
	new iaccount = get_member(id,m_iAccount);
	new irunecost = rune_list_icost[rune_id];
	if (irunecost <= iaccount)
	{
		new is_item = rune_list_isItem[rune_id];
		if (is_item || active_rune_id[id] < 0)
		{
			if (rm_give_rune_to_player_api(id,rune_id))
			{
				rg_add_account(id,iaccount - irunecost,AS_SET);
				return 1;
			}
			else 
			{
				client_print_color(id, print_team_red, "^4%s^3: ^1%L^3",runemod_prefix, LANG_PLAYER, "runemod_print_noneed_this_item");
			}
		}
		else 
		{
			client_print_color(id, print_team_red, "^4%s^3: ^1%L^3",runemod_prefix, LANG_PLAYER, "runemod_print_need_drop_rune");
		}
	}
	else 
	{
		client_print_color(id, print_team_red, "^4%s^3: ^1%L^3",runemod_prefix, LANG_PLAYER, "runemod_print_need_money");
	}
	return 0;
}

public rm_force_drop_rune_api(id)
{
	player_drop_rune(id);
}

public rm_force_drop_items_api(id)
{
	if (!is_real_player(id))
	{
		return;
	}
	player_drop_all_items(id);
}

stock RM_SCREENFADE(id = 0, iColor[3] = { 0, 0, 0 }, Float:flFxTime = -1.0, Float:flHoldTime = 0.0, iAlpha = 0, iFlags = FFADE_IN, bool:bReliable = false, bool:bExternal = false)
{
	g_bScreenFadeAllowed = true;
	UTIL_ScreenFade(id,iColor,flFxTime,flHoldTime,iAlpha,iFlags,bReliable,bExternal);
	g_bScreenFadeAllowed = false;
}

// the dot product is performed in 2d, making the view cone infinitely tall
stock bool:fm_is_in_viewcone_my(index, const Float:point[3]) {
	static Float:angles[3];
	get_entvar(index, var_angles, angles);
	engfunc(EngFunc_MakeVectors, angles);
	global_get(glb_v_forward, angles);
	angles[2] = 0.0;

	static Float:origin[3], Float:diff[3], Float:norm[3];
	get_entvar(index, var_origin, origin);
	xs_vec_sub(point, origin, diff);
	diff[2] = 0.0;
	xs_vec_normalize(diff, norm);

	static Float:dot, Float:fov;
	dot = xs_vec_dot(norm, angles);
	get_entvar(index, var_fov, fov);
	if (dot >= floatcos(fov * M_PI / 360.0))
		return true

	return false
}

stock bool:fm_is_visible_my(index, const Float:point[3], ignoremonsters = 0) {
	static Float:start[3], Float:view_ofs[3];
	get_entvar(index, var_origin, start);
	get_entvar(index, var_view_ofs, view_ofs);
	xs_vec_add(start, view_ofs, start);

	engfunc(EngFunc_TraceLine, start, point, ignoremonsters, index, g_pCommonTr);

	static Float:fraction;
	get_tr2(g_pCommonTr, TR_flFraction, fraction);
	if (fraction == 1.0)
		return true

	return false
}

stock bool:fm_is_visible_hull(index, const Float:point[3], hull = 0, ignoremonsters = 0) {
	static Float:start[3], Float:view_ofs[3];
	get_entvar(index, var_origin, start);
	get_entvar(index, var_view_ofs, view_ofs);
	xs_vec_add(start, view_ofs, start);

	if(hull) {
		// Hull trace - учитывает размеры entity
		engfunc(EngFunc_TraceHull, start, point, ignoremonsters, hull, index, g_pCommonTr);
	} else {
		// Line trace
		engfunc(EngFunc_TraceLine, start, point, ignoremonsters, index, g_pCommonTr);
	}

	static Float:fraction;
	get_tr2(g_pCommonTr, TR_flFraction, fraction);
	
	new bool:visible = fraction == 1.0;
	
	return visible;
}


// Фyнкция пpoвepяeт нe нaxoдитcя ли тoчкa pядoм co игpoкaми
stock bool:is_no_player_point( Float:coords[3] , Float:dist = 128.0)
{
	for(new i = 1; i <= MAX_PLAYERS; i++)
	{
		if (g_bUserConnected[i] && g_bUserAlive[i])
		{
			static Float:fOrigin[3];
			get_entvar(i, var_origin, fOrigin);
			if (get_distance_f(fOrigin, coords) < dist)
			return false;
		}
	}
	return true;
}

// Фyнкция пpoвepяeт нe нaxoдитcя ли тoчкa pядoм co cпaвнaми
stock bool:is_no_spawn_point( Float:coords[3] )
{
	// Bot fix ?
	if (coords[0] == 0.0 && coords[1] == 0.0)
	{
		return true;
	}

	new ent = -1;
	static classname[64];
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


// Проверяет на нестандартные спавны
stock bool:is_no_custom_spawn(const Float:coords[3])
{
	if (runemod_custom_spawn_support <= 0)
		return true;

	new size = ArraySize(g_PlayerSpawns);
	static Float:pt[3];

	for (new i = 0; i < size; i++)
	{
		ArrayGetArray(g_PlayerSpawns, i, pt);
		if (get_distance_f(coords, pt) < float(runemod_respawn_distance))
			return false;
	}
	return true;
}

stock AddPlayerSpawn(const Float:origin[3])
{
	new size = ArraySize(g_PlayerSpawns);
	static Float:pt[3];

	// Проверка на дубликаты (20 юнитов)
	for (new i = 0; i < size; i++)
	{
		ArrayGetArray(g_PlayerSpawns, i, pt);
		if (get_distance_f(origin, pt) < PLAYER_SPAWN_DEDUP_DIST)
			return;
	}
	
	if (size >= PLAYER_SPAWN_MAX)
	{
		ArrayDeleteItem(g_PlayerSpawns, 0);
	}

	ArrayPushArray(g_PlayerSpawns, origin);
}

stock RemoveRuneEntity(iEnt, spawnIndex = -1)
{
	if (iEnt <= 0 || is_nullent(iEnt))
		return;

	// помечаем энтити на удаление
	set_entvar(iEnt, var_flags, FL_KILLME);
	set_entvar(iEnt, var_nextthink, get_gametime());

	// корректируем счётчики
	new rune_id = rm_get_rune_runeid(iEnt);
	if (rune_id >= 0 && rune_id < runes_registered)
	{
		new bool:is_item = rune_list_isItem[rune_id];
		new origin_rune_id = rm_get_rune_num(iEnt);
		if (origin_rune_id >= 0 && origin_rune_id != rune_list_id[rune_id] && origin_rune_id < runes_registered)
		{
			rm_remove_rune_callback(rune_list_id[origin_rune_id], iEnt);
		}

		rm_remove_rune_callback(rune_list_id[rune_id], iEnt);

		if (rune_list_count[rune_id] > 0)
			rune_list_count[rune_id]--;
			
		if (is_item)
		{
			if (runemod_spawned_items > 0) runemod_spawned_items--;
		}
		else 
		{
			if (runemod_spawned_runes > 0) runemod_spawned_runes--;
		}
	}

	if (spawnIndex >= 0 && spawnIndex < spawn_array_size)
	{
		spawn_has_ent[spawnIndex] = 0;
		if (spawn_filled_size > 0) spawn_filled_size--;
	}
}