#pragma semicolon 1
#include <sourcemod>
#include <morecolors>
#include <socket>
#include <sdktools> 

public Plugin:myinfo = 
{ 
	name = "ConnectIfo", 
	author = "merk26", 
	description = "Плагин из серии Мульти Фрукт. Кириллическая информация о подключившемся игроке + мелкие настройки", 
	version = "1.3", 
	url = "www.атомхост.рф"
}

// хендлы
new Handle: h_ci_COldHide, 	Handle:h_ci_DOldHide, 		Handle:h_ci_Enable, 		Handle:g_ci_PTimer, 		Handle:g_ci_ShowStatusID, 	Handle:g_ci_ShowGeo, 	Handle:g_ci_ShowDistrict, 	Handle:g_ci_Log, 
	Handle:h_ci_IPShow,		Handle:g_ci_WelcomeSound,	Handle:h_ci_StemIDShow, 	Handle:g_ci_ShowLines,  	Handle:h_ci_DisconnectMsg,  Handle:g_ci_EnterSound, Handle:g_ci_ExitSound;
// булеты
new bool:p_ci_coldhide, 	bool:p_ci_doldhide, 		bool:p_ci_enable, 		bool:p_ci_showstatussteam, 	bool:p_ci_showgeoinfo, 		bool:p_ci_showdistrict, 	bool:p_ci_writelog, 	bool:p_ci_showlines,
	bool:p_ci_enable_ip, 	bool:p_ci_enable_steamid, 	bool:p_ci_exitmsg;
// стринги
new String:g_IP[MAXPLAYERS + 1][25], String:s_ci_welcomesoung[128], String:s_ci_entersoung[128], String:s_ci_exitsoung[128];

public OnPluginStart()
{

	h_ci_COldHide 			= CreateConVar("mf_ci_coldhide" , 		"1", 	"Скрыть стандартное сообщение о подключении", _, true, 0.0, true, 1.0);
	h_ci_DOldHide 			= CreateConVar("mf_ci_doldhide" , 		"1", 	"Скрыть стандартное сообщение об отключении", _, true, 0.0, true, 1.0);
	h_ci_DisconnectMsg 		= CreateConVar("mf_ci_exitmsg" , 		"1", 	"Показывать сообщение об отключении", _, true, 0.0, true, 1.0);
	h_ci_IPShow				= CreateConVar("mf_ci_showip", 			"1", 	"Показывать IP игрока", _, true, 0.0, true, 1.0);
	h_ci_StemIDShow			= CreateConVar("mf_ci_showstemid", 		"1", 	"Показывать SteamID игрока", _, true, 0.0, true, 1.0);
	h_ci_Enable 			= CreateConVar("mf_ci_enable", 			"1", 	"Вкл/Выкл плагин", _, true, 0.0, true, 1.0);
	g_ci_ShowLines 			= CreateConVar("mf_ci_showlines", 		"1", 	"Отделять информационный блок линиями", _, true, 0.0, true, 1.0);
	g_ci_PTimer 			= CreateConVar("mf_ci_ptimer", 			"30.0", "Время через которое (после старта карты) начнут отображаться сообщения (для защиты от перегрузок при массовом реконнекте)", _, true, 10.0, true, 120.0);
	g_ci_ShowStatusID 		= CreateConVar("mf_ci_showstatussteam", "1", 	"Показывать информации о статусе лицензии Steam", _, true, 0.0, true, 1.0);
	g_ci_ShowGeo 			= CreateConVar("mf_ci_showgeoinfo", 	"1", 	"Показывать информацию о стране + городе + крае игрока", _, true, 0.0, true, 1.0);
	g_ci_ShowDistrict 		= CreateConVar("mf_ci_showdistrict", 	"1", 	"Показывать информации о дистрикте игрока", _, true, 0.0, true, 1.0);
	g_ci_Log 				= CreateConVar("mf_ci_writelog", 		"1", 	"Запись подключений в лог файл (если  mf_connect_info = 1)", _, true, 0.0, true, 1.0);
	g_ci_WelcomeSound		= CreateConVar("mf_ci_welcomesound", 	"atomhost/hello.mp3", 	"Звук приветствия для игрока (проиграется во время показа инфы в чате); \"off\" - выкл");
	g_ci_EnterSound			= CreateConVar("mf_ci_entersound", 		"atomhost/enter.mp3", 	"Звуковое уведомление игроков о входе нового игрока; \"off\" - выкл");
	g_ci_ExitSound			= CreateConVar("mf_ci_exitsound", 		"atomhost/exit.mp3", 	"Звуковое уведомление о выходе игрока; \"off\" - выкл");
	
	AutoExecConfig(true, "mf_conect_info");
	LoadTranslations("mf_conect_info.phrases"); 
	
	//отлавливаем изменение cvar's
	HookConVarChange(h_ci_COldHide, OnConVarChanged);
	HookConVarChange(h_ci_DOldHide, OnConVarChanged);
	HookConVarChange(h_ci_Enable, OnConVarChanged);
	HookConVarChange(g_ci_ShowLines, OnConVarChanged);
	HookConVarChange(g_ci_ShowStatusID, OnConVarChanged);
	HookConVarChange(g_ci_ShowGeo, OnConVarChanged);
	HookConVarChange(g_ci_ShowDistrict, OnConVarChanged);
	HookConVarChange(g_ci_Log, OnConVarChanged);
	HookConVarChange(h_ci_IPShow, OnConVarChanged);
	HookConVarChange(h_ci_StemIDShow, OnConVarChanged);
	HookConVarChange(h_ci_DisconnectMsg, OnConVarChanged);
	
	
	// перехват событий
	HookEvent("player_connect",		player_connect,		EventHookMode_Pre);
	HookEvent("player_disconnect",	player_disconnect,	EventHookMode_Pre);
	
}

public OnConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == h_ci_COldHide)
		p_ci_coldhide = GetConVarBool(convar);
	else if (convar == h_ci_DOldHide)
		p_ci_doldhide = GetConVarBool(convar);
	else if (convar == h_ci_Enable)
		p_ci_enable = GetConVarBool(convar);
	else if (convar == g_ci_ShowLines)
		p_ci_showlines = GetConVarBool(convar);
	else if (convar == g_ci_ShowStatusID)
		p_ci_showstatussteam = GetConVarBool(convar);
	else if (convar == g_ci_ShowGeo)
		p_ci_showgeoinfo = GetConVarBool(convar);
	else if (convar == g_ci_ShowDistrict)
		p_ci_showdistrict = GetConVarBool(convar);
	else if (convar == g_ci_Log)
		p_ci_writelog = GetConVarBool(convar);
	else if (convar == h_ci_IPShow)
		p_ci_enable_ip = GetConVarBool(convar);
	else if (convar == h_ci_StemIDShow)
		p_ci_enable_steamid	= GetConVarBool(convar);
	else if (convar == h_ci_DisconnectMsg) 
		p_ci_exitmsg = GetConVarBool(convar);
}

public OnConfigsExecuted()
{
	GetConVarString(g_ci_WelcomeSound, s_ci_welcomesoung, sizeof(s_ci_welcomesoung));
	GetConVarString(g_ci_EnterSound, s_ci_entersoung, sizeof(s_ci_entersoung));
	GetConVarString(g_ci_ExitSound, s_ci_exitsoung, sizeof(s_ci_exitsoung));
	
	if(!StrEqual(s_ci_welcomesoung, "off", false))
	{
		decl String:buf[128];
		Format(buf, 128, "sound/%s", s_ci_welcomesoung);
		AddFileToDownloadsTable(buf);
		PrecacheSound(s_ci_welcomesoung, true);
	}	
	if(!StrEqual(s_ci_entersoung, "off", false))
	{
		decl String:buf[128];
		Format(buf, 128, "sound/%s", s_ci_entersoung);
		AddFileToDownloadsTable(buf);
		PrecacheSound(s_ci_entersoung, true);
	}	
	if(!StrEqual(s_ci_exitsoung, "off", false))
	{
		decl String:buf[128];
		Format(buf, 128, "sound/%s", s_ci_exitsoung);
		AddFileToDownloadsTable(buf);
		PrecacheSound(s_ci_exitsoung, true);
	}
	
	p_ci_coldhide 			= GetConVarBool(h_ci_COldHide);
	p_ci_doldhide 			= GetConVarBool(h_ci_DOldHide);
	p_ci_showlines 			= GetConVarBool(g_ci_ShowLines);
	p_ci_showstatussteam 	= GetConVarBool(g_ci_ShowStatusID);
	p_ci_showgeoinfo 		= GetConVarBool(g_ci_ShowGeo);
	p_ci_showdistrict 		= GetConVarBool(g_ci_ShowDistrict);
	p_ci_writelog 			= GetConVarBool(g_ci_Log);
	p_ci_exitmsg 			= GetConVarBool(h_ci_DisconnectMsg);
	p_ci_enable_ip			= GetConVarBool(h_ci_IPShow);
	p_ci_enable_steamid		= GetConVarBool(h_ci_StemIDShow);

}


public OnMapStart()
{
	p_ci_enable = false;
	CreateTimer(GetConVarFloat(g_ci_PTimer), t_star_connect_info);
	return 0;
}

// включаем плагин обратно, если он был включен
public Action:t_star_connect_info(Handle:timer)
{
	if(GetConVarBool(h_ci_Enable)) 
		p_ci_enable = true;
	return Plugin_Stop;
}

public Action:player_connect(Handle:event, const String:name[], bool:silent)
{ 
	
	if(p_ci_coldhide) // скрываем стандартное сообщение если того требуют
		return Plugin_Handled;
	else
		return Plugin_Continue;
}

public Action:player_disconnect(Handle:event, const String:name[], bool:silent)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client)// двойной if, так надо!
	{
		if(!IsFakeClient(client) && p_ci_exitmsg) //показываем сообщение об отключении
			CPrintToChatAll("%t", "player disconnect", client);
			// играем звук выхода
		if(!IsFakeClient(client) && !StrEqual(s_ci_exitsoung, "off", false))
			EmitSoundToAll(s_ci_exitsoung);
	}
	if(p_ci_doldhide) 
		return Plugin_Handled;
	else 
		return Plugin_Continue;
}

public OnClientPutInServer(client){		
	// глушим недоразумения в зачатке
	if(!p_ci_enable || IsFakeClient(client) || !GetClientIP(client, g_IP[client], 25)) 
		return 0;
		// играем звук входа
	if(!StrEqual(s_ci_entersoung, "off", false))
	{
		for(new i = 1; i <= MaxClients; i++) 
		{
			if(IsClientInGame(i) && !IsFakeClient(i) && i!=client)
				EmitSoundToClient(i, s_ci_entersoung);
				
		}
	}
		
	//открываем соединенее с сервером и храним хендл
	new Handle:socket = SocketCreate(SOCKET_TCP, OnSocketError);
	SocketSetArg(socket, GetClientUserId(client));
	SocketConnect(socket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, "ip.css26.ru", 80);
	
	return 0;
} 


// отправка запроса
public OnSocketConnected(Handle:socket, any:id)
{
	new client = GetClientOfUserId(id);
	if (client < 1)
		return 0;
	decl String:info[150];
	//формируем запрос
	Format(info, 150, "GET /ip/index.php?s=%s HTTP/1.0\r\nHost: ip.css26.ru\r\nConnection: close\r\n\r\n", g_IP[client]);
	//посылаем
	SocketSend(socket, info);
	return 0;
}
// обрабатываем р-аты запроса
public OnSocketReceive(Handle:socket, String:receiveData[], const dataSize, any:id)
{
	CloseHandle(socket); // прикрываем дырочку
	// создаем хлам
	decl client;
	decl String:steamid[20], String:i_country[25], String:i_city[35],	String:i_region[50], String:i_district[70];
	
	client = GetClientOfUserId(id);
	// проверяем, чем черт не шутит...
	if(client<1) return 0;
	// играем звук приветствия
	if(!StrEqual(s_ci_welcomesoung, "off", false))
		EmitSoundToClient(client, s_ci_welcomesoung);
	//извлекаем стимид 
	if (!GetClientAuthString(client, steamid, 20)) strcopy(steamid, 20, "steam: -");
	// печатаем верхнюю границу, если нужно
	if(p_ci_showlines) CPrintToChatAll("%t", "line");
	// печатаем стим и статус лицензии если нужно
	if (p_ci_showstatussteam)
	{
		if(CheckSteamID(steamid)) 
			CPrintToChatAll("%t", "enter steam", client);
		else 
			CPrintToChatAll("%t", "enter nosteam", client);
	}
	else 
		CPrintToChatAll("%t", "enter", client);
	// печатаем сам стимид
	if(p_ci_enable_steamid) 
		CPrintToChatAll("%t", "staemid", steamid);
	// печатаем ип
	if(p_ci_enable_ip) 
		CPrintToChatAll("%t", "ip", g_IP[client]);
	//потрошим массив
	if (p_ci_showgeoinfo)
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
					CPrintToChatAll("%t", "country", i_country);
					CPrintToChatAll("%t", "no data");
				}
				else
				{
					if (StrEqual(i_city, i_region, false))
						CPrintToChatAll("%t%t", "country", i_country, "city", i_city);
					else 
						CPrintToChatAll("%t%t%t", "country", i_country, "city", i_city, "region" ,i_region);
					
					if(p_ci_showdistrict)
					{
						pos = StrContains(receiveData, "<district>", false);
						if (pos > 0) 
						{
							SplitString(receiveData[pos + 10], "</district>", i_district, 70);
							CPrintToChatAll("%t", "district", i_district);
						}
					}
				}
			}
		} 
		else
			CPrintToChatAll("%t", "no connect");
	}
	// пише в лог
	if (p_ci_writelog) 
		{
			decl String:date[21];
			FormatTime(date, sizeof(date), "%d%m%y", -1);
			decl String:file[PLATFORM_MAX_PATH];
			BuildPath(Path_SM, file, sizeof(file), "logs/connect_info_%s.log", date); 
			LogToFileEx(file, "%s - %s - %N - %s - %s - %s - %s", g_IP[client], steamid, client, i_country, i_city, i_region, i_district);
		}
	// печатаем нижнюю границу, если нужно
	if(p_ci_showlines) 
		CPrintToChatAll("%t", "line");

	return 0;
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

public CheckSteamID(String:steamid[20]) // true если игрок Steam и false если no staem
{
	if(strlen(steamid) != 19) 
		return true;
	else 
		return false;
}