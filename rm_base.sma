#include <amxmodx>
#include <amxmisc>
#include <csx>
#include <hamsandwich>
#include <xs>

#include <rm_api>

// Максимальное количество спавнов для рун
#define MAX_ACTIVE_RUNES 16
// Максимальное количество рун - плагинов
#define MAX_REGISTER_RUNES 128
// Количество рун которое будет создано за одно обновление спавнов
#define MAX_RUNES_AT_ONE_TIME_SPAWN 4


#define SPAWN_SEARCH_TASK_ID 10000
#define SPAWN_RUNES_TASK_ID 10001

#define UPDATE_RUNE_DESCRIPTION_HUD_ID 10002
#define UPDATE_RUNE_DESCRIPTION_HUD_TIME 1.5

#define HUD_CHANNEL_ID 3
#define HUD_CHANNEL_ID_2 2

// Таймер обновление рун и обучения новым спавнам
#define SPAWN_NEW_RUNE_TIME 20.0

// Количество спавнов
new filled_spawns = 0;
// Занят ли спавн на данный момент руной
new bool:spawn_filled[MAX_ACTIVE_RUNES] = {false,...};
// Координаты спавнов
new Float:spawn_list[MAX_ACTIVE_RUNES][3];

// Количество рун
new filled_runes = 0;
// Данные о рунах
new rune_list_id[MAX_REGISTER_RUNES];
new rune_list_name[MAX_REGISTER_RUNES][128];
new rune_list_descr[MAX_REGISTER_RUNES][256];
new rune_list_model[MAX_REGISTER_RUNES][256];
new Float:rune_list_model_color[MAX_REGISTER_RUNES][3];

// Активная руна игрока - номер плагина
new active_rune[MAX_PLAYERS + 1];
// Получение ID руны по номеру плагина
public get_runeid_by_pluginid( pid )
{
	for(new i = 0; i < filled_runes;i++)
	{
		if (rune_list_id[i] == pid)
			return i;
	}
	return -1;
}

// Стандартная модель руны. Используется если загружена. По умолчанию "models/runemodel.mdl"
new rune_default_model[256];

// Проверка реальный ли игрок
public bool:is_real_player( id )
{
	return id > 0 && id < 33;
}

// Регистрация плагина, столкновений с руной, респавна игроков и обновления спавнов и рун.
// А так же наведение на руну возвращает ее название и описание руны.
public plugin_init()
{
	register_plugin("Reloaded_RuneMod","1.1","Karaulov");
	register_touch("rune_model","player","rune_touch");
	RegisterHam(Ham_Spawn, "player", "client_respawned", 1);
	set_task(SPAWN_NEW_RUNE_TIME, "RM_SPAWN_RUNE", SPAWN_SEARCH_TASK_ID, _, _, "b");
	set_task(UPDATE_RUNE_DESCRIPTION_HUD_TIME, "RM_SHOW_RUNE_INFO", UPDATE_RUNE_DESCRIPTION_HUD_ID, _, _, "b");
	register_event("HLTV", "event_new_round", "a", "1=0", "2=0")
	register_concmd( "drop", "cmd_drop" );
}

new Float:player_drop_time[MAX_PLAYERS + 1];

public cmd_drop(id)
{
	if (get_gametime() - player_drop_time[id] < 0.2 && get_user_weapon(id) == CSW_KNIFE)
	{
		if (active_rune[id] != 0)
		{
			client_print_color(0, print_team_red, "^4[RUNEMOD]^3 Вы выбросили руну: %s!", rune_list_name[get_runeid_by_pluginid(active_rune[id])]);
			player_drop_rune( id );
		}
	}
	player_drop_time[id] = get_gametime();
}


// Забрать руны при старте нового раунда
public event_new_round( )
{
	for(new i = 0; i < MAX_PLAYERS + 1;i++)
	{
		player_drop_rune(i);
	}
	//cleanup spawns for create new
	new ent = 0;
	while((ent = find_ent_by_class(ent,"rune_model")) != 0)
	{
		remove_entity(ent);
	}
	for (new i = 0; i < filled_spawns; i++)
	{
		spawn_filled[i] = false;
	}
}

// Прекеш модели руны "models/runemodel.mdl" или использование стандартной предзагруженной модели "models/w_weaponbox.mdl"
public plugin_precache()
{
	if(file_exists("models/runemodel.mdl"))
	{
		precache_model("models/runemodel.mdl");
		formatex(rune_default_model,charsmax(rune_default_model),"%s","models/runemodel.mdl");
	}
	else 
	{
		formatex(rune_default_model,charsmax(rune_default_model),"%s","models/w_weaponbox.mdl");
	}
}


// Регистрация новой руны в базовом плагине (сохранение в заранее подготовленный список)
public RM_RegisterPlugin(PluginIndex,RuneName[],RuneDesc[],Float:RuneColor1,Float:RuneColor2,Float:RuneColor3,Model[])
{
	new i = filled_runes;
	filled_runes++;
	
	rune_list_id[i] = PluginIndex;
	formatex(rune_list_name[i],charsmax(rune_list_name[]),"%s", RuneName);
	formatex(rune_list_descr[i],charsmax(rune_list_descr[]),"%s", RuneDesc);
	
	if( file_exists(Model) )
	{
		formatex(rune_list_model[i],charsmax(rune_list_model[]),"%s", Model);
	}
	else 
	{
		formatex(rune_list_model[i],charsmax(rune_list_model[]),"%s", rune_default_model);
	}
	
	rune_list_model_color[i][0] = RuneColor1;
	rune_list_model_color[i][1] = RuneColor2;
	rune_list_model_color[i][2] = RuneColor3;
}

// Забрать руну при смерти игрока 
public client_death(killer, victim, wpnindex, hitplace, TK)
{
	if (is_real_player(victim))
	{
		player_drop_rune(victim);
	}
}

// Забрать руну при отключении игрока
public client_disconnected(id, bool:drop, message[], maxlen)
{
	if (is_real_player(id))
	{
		player_drop_rune(id);
	}
}

// Забрать руну при появлении игрока
public client_respawned(id)
{
	if (is_real_player(id))
	{
		player_drop_rune(id);
	}
}

// Функция забирает руну и вызывает соответствующую функцию в плагине руны
public player_drop_rune(id)
{
	if (active_rune[id] != 0)
	{
		rm_drop_rune_callback(active_rune[id], id);
	}
	active_rune[id] = 0;
}

// Функция вызывается в плагинах рун, позволяет принудительно заставить базовый плагин отключить руну игроку.
public rm_drop_rune_api(pid, id)
{
	if (active_rune[id] == pid)
		player_drop_rune(id); 
}

// Событие происходит при столкновении игрока с руной, если руны нет, даем игроку новую, освобождаем спавн и удаляем модель руны
public rune_touch(rune_ent, player_id)
{
	if (active_rune[player_id] == 0)
	{
		new spawn_id = get_rune_spawnid(rune_ent);
		spawn_filled[spawn_id] = false;
		active_rune[player_id] = rune_list_id[get_rune_runeid(rune_ent)];
		rm_give_rune_callback(active_rune[player_id],player_id);
		remove_entity(rune_ent);
		client_print_color(0, print_team_red, "^4[RUNEMOD]^3 Выберите нож и нажмите 2 раза drop что бы выбросить руну!");
	}
	return PLUGIN_CONTINUE;
}

// Функция проверяет не находится ли точка рядом со спавнами
public bool:is_no_spawn_point( Float:coords[3] )
{
	new ent, classname[64]
	while((ent = find_ent_in_sphere(ent, coords, 200.0)))
	{
		entity_get_string(ent, EV_SZ_classname,classname,charsmax(classname))
		if(equali(classname, "info_player_start") || equali(classname, "info_player_deathmatch"))
		{
			return false;
		}
	}
	return true;
}

// Функция проверяет не находится ли точка рядом со игроками
public bool:is_no_player_point( Float:coords[3] )
{
	new ent;
	while((ent = find_ent_in_sphere(ent, coords, 64.0)))
	{
		if (ent > MAX_PLAYERS)
			continue;
		else if (is_user_alive(ent))
			return false;
	}
	return true;
}

// Функция проверяет не находится ли точка рядом с точками появления других рун
public bool:is_no_rune_point( Float:coords[3] )
{
	for (new i = 0; i < filled_spawns; i++)
	{
		if ( get_distance_f(coords,spawn_list[i]) < 350 )
			return false;
	}
	return true;
}


// Заполняем спавны по координатам игроков. Простейший способ не требующий создания файлов со спавнами.
// Преимещество в том что каждый раз создаются новые спавны.
public fill_new_spawn_point( )
{
	if (filled_spawns >= MAX_ACTIVE_RUNES)
		return;
	new iPlayers[ 32 ], iNum;
	new Float:fOrigin[3];
	get_players( iPlayers, iNum  );
	for( new i = 0; i < iNum; i++ )
	{
		new iPlayer = iPlayers[ i ];
		if (is_user_connected(iPlayer) && is_user_alive(iPlayer) && is_user_onground(iPlayer))
		{
			entity_get_vector(iPlayer, EV_VEC_origin, fOrigin );
			if (is_no_spawn_point(fOrigin) && is_no_rune_point(fOrigin))
			{
				entity_get_vector(iPlayer, EV_VEC_origin, spawn_list[filled_spawns] );
				spawn_filled[filled_spawns] = false;
				filled_spawns++;
				if (filled_spawns >= MAX_ACTIVE_RUNES)
					return;
			}
		}
	}
}

// Функция сохраняет ид руны в сущность модели руны 
public set_rune_runeid( id, rune )
{
	return entity_set_float(id, EV_FL_fuser4, float(rune) );
}
// Функция возвращает ид руны из сущности модели руны 
public get_rune_runeid( id )
{
	return floatround(entity_get_float(id, EV_FL_fuser4));
}
// Функция возвращает ид спавн точки из сущности модели руны 
public get_rune_spawnid( id )
{
	return floatround(entity_get_float(id, EV_FL_fuser3));
}
// Собственно создаем одну руну
public spawn_one_rune(rune, spawn_id)
{
	new EntNum = create_entity("info_target");
	entity_set_string(EntNum, EV_SZ_classname,"rune_model");
	entity_set_float(EntNum, EV_FL_gravity, 2.0 )
	entity_set_int(EntNum, EV_INT_renderfx, kRenderFxGlowShell);
	entity_set_float(EntNum, EV_FL_renderamt, 500.0);
	entity_set_int(EntNum, EV_INT_rendermode, kRenderTransAlpha);
	entity_set_vector(EntNum, EV_VEC_rendercolor,rune_list_model_color[rune]);
	entity_set_model(EntNum, rune_list_model[rune]);
	entity_set_vector(EntNum, EV_VEC_maxs, Float:{15.0,15.0,15.0});
	entity_set_vector(EntNum, EV_VEC_mins, Float:{-15.0,-15.0,-15.0});
	entity_set_int(EntNum, EV_INT_solid, SOLID_TRIGGER )
	entity_set_float(EntNum, EV_FL_fuser3,float(spawn_id));
	entity_set_float(EntNum, EV_FL_fuser4,float(rune));
	entity_set_int(EntNum, EV_INT_movetype, MOVETYPE_FLY);
	entity_set_vector(EntNum, EV_VEC_velocity,Float:{0.0,0.0,0.0});
	entity_set_vector(EntNum, EV_VEC_avelocity,Float:{0.0,25.0,0.0});
	entity_set_origin(EntNum, spawn_list[spawn_id])
	entity_set_vector(EntNum, EV_VEC_origin, spawn_list[spawn_id] );
	spawn_filled[spawn_id] = true;
}
// Функция создающая руны
public spawn_runes( id )
{
	if (filled_runes == 0)
		return
	new i = 0;
	new need_runes = MAX_RUNES_AT_ONE_TIME_SPAWN;
	
	
	for(i = 0; i < filled_spawns; i++)
	{
		if (spawn_filled[i])
			continue;
			
		new cur_rune_id = random_num(1,filled_runes) - 1;
		if (is_no_player_point(spawn_list[i]))
		{
			spawn_one_rune( cur_rune_id, i );
			
			need_runes--;
			if (need_runes == 0)
				break;
		}
	}
}
// Таймер создания спавнов и заполнения их рунами
public RM_SPAWN_RUNE( id )
{
	fill_new_spawn_point( );
	set_task(2.0, "spawn_runes", SPAWN_RUNES_TASK_ID );
}

// Функция обновляющая HUD на экране игрока с информацией о руне.
public RM_UPDATE_HUD_RUNE( id, rune_id )
{
	set_hudmessage(0, 50, 200, -1.0, 0.20, 0, 0.1, 1.5, 0.02, 0.02, HUD_CHANNEL_ID);
	show_hudmessage(id, "Название: %s^nОписание: %s^n",rune_list_name[rune_id],rune_list_descr[rune_id]);
}

public RM_UPDATE_HUD( id, rune_id )
{
	set_hudmessage(0, 50, 200, -1.0, 0.80, 0, 0.1, 1.5, 0.02, 0.02, HUD_CHANNEL_ID_2);
	show_hudmessage(id, "%s: %s",rune_list_name[rune_id],rune_list_descr[rune_id]);
}

// Отображаем информацию о руне. 
// Способ простейший но в то же время неизвестно на сколько требователен к ресурсам
public RM_SHOW_RUNE_INFO( id )
{
	new iPlayers[ 32 ], iNum, iPlayer;
	new ClassName[64]
	get_players( iPlayers, iNum  );
	for( new i = 0; i < iNum; i++ )
	{
		iPlayer = iPlayers[ i ];
		if (is_user_connected(iPlayer)/* && is_user_alive(iPlayer)*/)
		{
			if (active_rune[iPlayer] > 0)
			{
				new runeid = get_runeid_by_pluginid(active_rune[iPlayer]);
				RM_UPDATE_HUD(iPlayer,runeid);
			}
			new iEyesOrigin[ 3 ];
			get_user_origin( iPlayer, iEyesOrigin, Origin_Eyes );
			
			new iEyesEndOrigin[ 3 ];
			get_user_origin( iPlayer, iEyesEndOrigin, Origin_AimEndEyes );
			
			new Float:vecEyesOrigin[ 3 ];
			IVecFVec( iEyesOrigin, vecEyesOrigin );
			
			new Float:vecEyesEndOrigin[ 3 ];
			IVecFVec( iEyesEndOrigin, vecEyesEndOrigin );
			
			new Float:vecDirection[ 3 ];
			velocity_by_aim( iPlayer, 1, vecDirection );

			new Float:vecAimOrigin[ 3 ];
			xs_vec_add( vecEyesOrigin, vecDirection, vecAimOrigin );

			new target, i = 0;
			
			while (i < 1200) {
				i+=64;
				velocity_by_aim( iPlayer, i, vecDirection );
				xs_vec_add( vecEyesOrigin, vecDirection, vecAimOrigin );
				
				if (get_distance_f(vecEyesEndOrigin,vecAimOrigin) < 40.0)
				{
					break;
				}
				
				target = 0;
				while((target = find_ent_in_sphere(target, vecAimOrigin, 32.0)) > 0)
				{
					entity_get_string( target, EV_SZ_classname,ClassName,charsmax(ClassName) )
					if(equal(ClassName, "rune_model"))
					{
						RM_UPDATE_HUD_RUNE(iPlayer, get_rune_runeid( target ));
						i = 1200;
						break;
					}
				}
			}
		}
	}
}