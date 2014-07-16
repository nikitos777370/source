/* Описание
- Убирает стандартные сообщения (вход, отключение) сообщения из чата
- Цветное русскоязычное сообщение об отключении игрока
- Кирилическая Гео информация о игроке(Страна | Город | Регион | Дистрикт)
*/

#pragma semicolon 1
#include <adminmenu>
#include <cstrike>
#include <sourcemod>
//#include <sdktools>

#include <socket>
public Plugin:myinfo = 
{ 
	name = "ConnectIfo [by атомхост.рф]", 
	author = "merk™", 
	description = "Плагин из серии Мульти Фрукт. Кирилическая информация о подключившемся игроке (Страна | Город | Регион | Дистрикт) + мелкие настройки", 
	version = "1.1", 
	url = "https://vk.com/merk26"
}

// конвары
new Handle: g_connetc_old_hide, Handle:g_disconnetc_old_hide, Handle:g_connect_info, Handle:g_connect_timer, Handle:g_connect_lic, Handle:g_connect_cc, Handle:g_connect_dis, Handle:g_connect_log, 
	Handle:g_connect_info_ip,Handle:g_connect_info_steamid, Handle:g_connect_lines,  Handle:g_disconnetc_new;
new bool:p_connetc_old_hide, bool:p_disconnetc_old_hide, bool:p_connect_info, bool:p_connect_lic, bool:p_connect_cc, bool:p_connect_dis, bool:p_connect_log, bool:p_connect_lines,
bool:p_connect_info_ip, bool:p_connect_info_steamid, bool:p_disconnetc_new;
new String:g_IP[MAXPLAYERS + 1][25];

new String:Col[5][10]={"\x07FFF000", "\x07FFFFFF", "\x0700FF00", "\x07FF0000", "\x0797FD78"}; 
public OnPluginStart()
{

	g_connetc_old_hide 			= CreateConVar("mf_connect_old_hide" , "1", "Скрыть стандартное сообщение о подключении", _, true, 0.0, true, 1.0);
	g_disconnetc_old_hide 		= CreateConVar("mf_disconnect_old_hide" , "1", "Скрыть стандартное сообщение об отключении", _, true, 0.0, true, 1.0);
	g_disconnetc_new 			= CreateConVar("mf_disconnetc_new" , "0", "Показывать новое сообщение об отключении", _, true, 0.0, true, 1.0);
	g_connect_info_ip			= CreateConVar("mf_connect_info_ip", "1", "Показывать IP игрока", _, true, 0.0, true, 1.0);
	g_connect_info_steamid		= CreateConVar("mf_connect_info_steamid", "1", "Показывать SteamID игрока", _, true, 0.0, true, 1.0);
	g_connect_info 				= CreateConVar("mf_connect_info", "1", "Показывать информацию о подключившемся игроке", _, true, 0.0, true, 1.0);
	g_connect_lines 			= CreateConVar("mf_connect_lines", "1", "Отделять информационный блок линиями", _, true, 0.0, true, 1.0);
	g_connect_timer 			= CreateConVar("mf_connect_timer", "20.0", "Время через которое (после старта карты) начнут отображаться сообщения (для защиты от перегрузок при массовом коннекте)", _, true, 10.0, true, 120.0);
	g_connect_lic 				= CreateConVar("mf_connect_lic", "1", "Показывать информации о статусе лицензии Steam", _, true, 0.0, true, 1.0);
	g_connect_cc 				= CreateConVar("mf_connect_cc", "1", "Показывать информацию о стране + городе + крае игрока (только для некоторых стран СНГ + Россия)", _, true, 0.0, true, 1.0);
	g_connect_dis 				= CreateConVar("mf_connect_district", "1", "Показывать информации о дистрикте игрока (только для некоторых стран СНГ + Россия)", _, true, 0.0, true, 1.0);
	g_connect_log 				= CreateConVar("mf_connect_log", "1", "Запись подключений в лог файл (если  mf_connect_info = 1)", _, true, 0.0, true, 1.0);
	
	AutoExecConfig(true, "mf_conect_info");
	
	p_connetc_old_hide 			= GetConVarBool(g_connetc_old_hide);
	p_disconnetc_old_hide 		= GetConVarBool(g_disconnetc_old_hide);
	p_connect_info 				= GetConVarBool(g_connect_info);
	p_connect_lines 			= GetConVarBool(g_connect_lines);
	p_connect_lic 				= GetConVarBool(g_connect_lic);
	p_connect_cc 				= GetConVarBool(g_connect_cc);
	p_connect_dis 				= GetConVarBool(g_connect_dis);
	p_connect_log 				= GetConVarBool(g_connect_log);
	p_disconnetc_new 			= GetConVarBool(g_disconnetc_new);
	p_connect_info_ip			= GetConVarBool(g_connect_info_ip);
	p_connect_info_steamid		= GetConVarBool(g_connect_info_steamid);
	
	HookConVarChange(g_connetc_old_hide, mf_connect_OnConVarChanged);
	HookConVarChange(g_disconnetc_old_hide, mf_connect_OnConVarChanged);
	HookConVarChange(g_connect_info, mf_connect_OnConVarChanged);
	HookConVarChange(g_connect_lines, mf_connect_OnConVarChanged);
	HookConVarChange(g_connect_lic, mf_connect_OnConVarChanged);
	HookConVarChange(g_connect_cc, mf_connect_OnConVarChanged);
	HookConVarChange(g_connect_dis, mf_connect_OnConVarChanged);
	HookConVarChange(g_connect_log, mf_connect_OnConVarChanged);
	HookConVarChange(g_connect_info_ip, mf_connect_OnConVarChanged);
	HookConVarChange(g_connect_info_steamid, mf_connect_OnConVarChanged);
	HookConVarChange(g_disconnetc_new, mf_connect_OnConVarChanged);
	
	
	// перехват событий
	HookEvent("player_connect",		player_connect,		EventHookMode_Pre);
	HookEvent("player_disconnect",	player_disconnect,	EventHookMode_Pre);
	
}

public mf_connect_OnConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == g_connetc_old_hide) p_connetc_old_hide 				= GetConVarBool(convar);
	else if (convar == g_disconnetc_old_hide) p_disconnetc_old_hide 	= GetConVarBool(convar);
	else if (convar == g_connect_info) p_connect_info 					= GetConVarBool(convar);
	else if (convar == g_connect_lines) p_connect_lines 				= GetConVarBool(convar);
	else if (convar == g_connect_lic) p_connect_lic 					= GetConVarBool(convar);
	else if (convar == g_connect_cc) p_connect_cc 						= GetConVarBool(convar);
	else if (convar == g_connect_dis) p_connect_dis 					= GetConVarBool(convar);
	else if (convar == g_connect_log) p_connect_log 					= GetConVarBool(convar);
	else if (convar == g_connect_info_ip) p_connect_info_ip				= GetConVarBool(convar);
	else if (convar == g_connect_info_steamid) p_connect_info_steamid	= GetConVarBool(convar);
	else if (convar == g_disconnetc_new) p_disconnetc_new				= GetConVarBool(convar);
}



public OnMapStart() // стартовала карта
{
	if(p_connect_info)
	{
		p_connect_info = false;
		CreateTimer(GetConVarFloat(g_connect_timer), t_star_connect_info);
	}
}

// включает показ инфы об игроках
public Action:t_star_connect_info(Handle:timer)
{
	if(GetConVarBool(g_connect_info)) p_connect_info = true;
	return Plugin_Stop;
}

public Action:player_connect(Handle:event, const String:name[], bool:silent){ //зашел на серв
	if(p_connetc_old_hide) return Plugin_Handled;
	else return Plugin_Continue;
}

public Action:player_disconnect(Handle:event, const String:name[], bool:silent){ // вышел
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client > 0 && !IsFakeClient(client) && p_disconnetc_new) PrintToChatAll("%sИгрок %s%N %sустал и покинул наш игровой мир.", Col[4], Col[0], client,Col[4] );
	if(p_disconnetc_old_hide) return Plugin_Handled;
	else return Plugin_Continue;
}

public OnClientPutInServer(client){
		
	// информация об игроке
	if(p_connect_info)
	{
		if (IsFakeClient(client) || !GetClientIP(client, g_IP[client], 25))
		{
		}
		else
		{	
			new Handle:socket = SocketCreate(SOCKET_TCP, OnSocketError);
			SocketSetArg(socket, GetClientUserId(client));
			SocketConnect(socket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, "ip.css26.ru", 80);
		}
	}
} 


// эта часть кода отвечает за получение и обработку информации о клиенте [Страна | Город | Регион | Дистрикт]

public OnSocketConnected(Handle:socket, any:id)
{
	new client = GetClientOfUserId(id);
	if (client < 1)
		return;
	decl String:info[150];
	Format(info, 150, "GET /ip/index.php?s=%s HTTP/1.0\r\nHost: ip.css26.ru\r\nConnection: close\r\n\r\n", g_IP[client]); //g_IP[client] // m 89.109.235.0
	SocketSend(socket, info);
}
public OnSocketReceive(Handle:socket, String:receiveData[], const dataSize, any:id)
{
	CloseHandle(socket); // прикрываем дырочку
	
	decl client;
	decl String:steamid[20],String:i_steamid[20], String:i_country[25], String:i_city[35],	String:i_region[50], String:i_district[70];
	
	client = GetClientOfUserId(id);
	if (!GetClientAuthString(client, steamid, 20)) strcopy(steamid, 20, "steam: -");
	
	if(p_connect_lines) PrintToChatAll("%s- - - - - - - - - - - - - - - - - - - - - - - - - - - - -", Col[4]);
	
	if (p_connect_lic)
	{
		
		if(CheckSteamID(steamid)) 
		{
			strcopy(i_steamid, 20, "[Steam]"); 
			PrintToChatAll("%sЗашел %s%N %s%s", Col[1], Col[4], client, Col[2], i_steamid);
		}
		else 
		{
			strcopy(i_steamid, 20, "[No-Steam]"); 
			PrintToChatAll("%sЗашел %s%N %s%s", Col[1], Col[4], client, Col[3],i_steamid);
		}
		
		
	}
	else PrintToChatAll("%sЗашел %s%N", Col[1], Col[4], client);
	if(p_connect_info_steamid) PrintToChatAll("%sSteamID: %s%s", Col[1], Col[4],steamid);
	if(p_connect_info_ip) PrintToChatAll("%sIP адрес: %s%s", Col[1], Col[4], g_IP[client]);
	
	if (p_connect_cc)
	{
		new pos = StrContains(receiveData, "<country>", false);
		if (pos > 0) 
		{ 
			SplitString(receiveData[pos + 9], "</country>", i_country, 25);
			pos = 0; 
			
			pos = StrContains(receiveData, "<city>", false);
			if (pos > 0) 
			{
				SplitString(receiveData[pos + 6], "</city>", i_city, 35);
				pos = 0; 
			}
			
			pos = StrContains(receiveData, "<region>", false);
			if (pos > 0) 
			{
				SplitString(receiveData[pos + 8], "</region>", i_region, 50);
				pos = 0;
				if(i_region[0] == '-')
				{
					PrintToChatAll("%sСтрана %s(%s)", Col[1], Col[4], i_country);
					PrintToChatAll("%sОстальные данные не известны", Col[1]);
				}
				else
				{
					if (StrEqual(i_city, i_region, false)) PrintToChatAll("%sСтрана: %s%s%s, Город: %s%s", Col[1], Col[4], i_country, Col[1], Col[4], i_city);
					else PrintToChatAll("%sСтрана: %s%s%s, Город: %s%s (%s)", Col[1], Col[4], i_country , Col[1], Col[4], i_city, i_region);
					
					if(p_connect_dis)
					{
						pos = StrContains(receiveData, "<district>", false);
						if (pos > 0) 
						{
							SplitString(receiveData[pos + 10], "</district>", i_district, 70);
							PrintToChatAll("%sДистрикт: %s%s", Col[1], Col[4], i_district);
						}
					}
				}
			}
	
		} 
		else
		{
			PrintToChatAll("%sНе удалось получить данные", Col[4]);
		}
	}
	if (p_connect_log) // запись в лог
		{
			decl String:date[21];
			FormatTime(date, sizeof(date), "%d%m%y", -1);
			decl String:file[PLATFORM_MAX_PATH];
			BuildPath(Path_SM, file, sizeof(file), "logs/connect_info_%s.log", date); 
			LogToFileEx(file, "%s - %s - %N - %s - %s - %s - %s", g_IP[client], steamid, client, i_country, i_city, i_region, i_district);
		}
	if(p_connect_lines) PrintToChatAll("%s- - - - - - - - - - - - - - - - - - - - - - - - - - - - -", Col[4]);	
}

public OnSocketDisconnected(Handle:socket, any:id)
{
	CloseHandle(socket);
}

public OnSocketError(Handle:socket, const errorType, const errorNum, any:id)
{
	CloseHandle(socket);
	if(errorType !=3) LogError("Ошибка сокета (errno %d)", errorNum);
}

public CheckSteamID(String:steamid[20]) // вернет true если игрок Steam и false если no staem
{
	if(strlen(steamid) != 19) 
		return true;
	else 
		return false;
}