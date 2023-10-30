#include <amxmodx>
#include <amxmisc>
#include <rm_api>

new rune_model_id = -1;

new rune_name[] = "rm_vip_item_name";
new rune_descr[] = "rm_vip_item_desc";

new rune_model_path[64] = "models/rm_reloaded/w_vip.mdl";

new g_uVipFlags = 0;

public plugin_init()
{
	register_plugin("RM_VIP_FLAG","1.2","Karaulov"); 
	
	new rune_flags[] = "ab";
	/* Чтение конфигурации */
	rm_read_cfg_str(rune_name,"VIP_FLAGS",rune_flags,rune_flags,charsmax(rune_flags));
	
	g_uVipFlags = read_flags(rune_flags);
	
	if (g_uVipFlags == 0)
	{
		// Если флаг указан неправильно, эта строка завершит работу плагина с ошибкой.
		set_fail_state("NO VIP_FLAGS DETECTED");
		return;
	}
	
	// Регистрация руны если все впорядке
	rm_register_rune(rune_name,rune_descr,Float:{255.0,255.0,255.0}, rune_model_path,_,rune_model_id);
	
	// Класс руны: предмет
	rm_base_use_rune_as_item( );

	// Максимальное количество предметов/рун которые могут быть на карте в одно время
	new max_count = 1;
	rm_read_cfg_int(rune_name,"MAX_COUNT_ON_MAP",max_count,max_count);
	rm_base_set_max_count( max_count );
}

public plugin_precache()
{
	/* Чтение конфигурации */
	rm_read_cfg_str(rune_name,"model",rune_model_path,rune_model_path,charsmax(rune_model_path));
	
	rune_model_id = precache_model(rune_model_path);
}

public rm_give_rune(id)
{
	// Игнорировать если у игрока уже есть данный вип
	if (get_user_flags(id) & g_uVipFlags != g_uVipFlags)
	{
		// Убираем старые совпадающие флаги
		remove_user_flags(id,g_uVipFlags);
		// Убираем флаг 'z' 
		remove_user_flags(id,ADMIN_USER);
		// Добавляем привилегии до конца карты
		set_user_flags(id, get_user_flags(id) + g_uVipFlags);
		return RUNE_PICKUP_SUCCESS;
	}
	else 
		return NO_RUNE_PICKUP_SUCCESS;
}
