#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#define SCORE_DELAY_EMPTY_SERVER 3.0
#define VOTE_NO "no"
#define VOTE_YES "yes"

new Votey = 0;
new Voten = 0;
new bool:game_l4d2 = false;
new String:ReadyMode[64];
new String:Label[16];
new String:VotensReady_ED[32];
new String:VotensMap_ED[32];
new String:votesmaps[MAX_NAME_LENGTH];
new String:votesmapsname[MAX_NAME_LENGTH];
new Handle:g_hVoteMenu = INVALID_HANDLE;
new Handle:g_Cvar_Limits;
new Handle:cvarFullResetOnEmpty;
new Handle:VotensReadyED;
new Handle:VotensMapED;
new Handle:VotensED;
new Float:lastDisconnectTime;

enum voteType
{
    ready,
    map
}

new voteType:g_voteType = voteType:ready;

public Plugin:myinfo =
{
    name = "投票菜单插件",
    author = "fenghf",
    description = "Votes Commands",
    version = "1.2.2a",
    url = "http://bbs.3dmgame.com/thread-2094823-1-1.html"
};

public OnPluginStart()
{
    decl String: game_name[64];
    GetGameFolderName(game_name, sizeof(game_name));
    if (!StrEqual(game_name, "left4dead", false) && !StrEqual(game_name, "left4dead2", false))
    {
        SetFailState("只能在Left 4 Dead 1 & 2使用.");
    }
    if (StrEqual(game_name, "left4dead2", false))
    {
        game_l4d2 = true;
    }
    RegConsoleCmd("votesready", Command_Voter);
    RegConsoleCmd("votesmapsmenu", Command_VotemapsMenu);
    RegConsoleCmd("sm_votes", Command_Votes, "打开投票菜单");

    g_Cvar_Limits = CreateConVar("sm_votes_s", "0.60", "百分比.", 0, true, 0.05, true, 1.0);
    cvarFullResetOnEmpty = CreateConVar("l4d_full_reset_on_empty", "1", " 当服务器没有人的时候关闭ready插件.", FCVAR_NOTIFY);
    VotensReadyED = CreateConVar("l4d_VotensreadyED", "1", " 启用、关闭 投票ready功能.", FCVAR_NOTIFY);
    VotensMapED = CreateConVar("l4d_VotensmapED", "1", " 启用、关闭 投票换图功能.", FCVAR_NOTIFY);
    VotensED = CreateConVar("l4d_Votens", "1", " 启用、关闭 插件.", FCVAR_NOTIFY);

    AutoExecConfig(true, "l4d2_votes2_mod");
}

public OnClientPutInServer(client)
{
    CreateTimer(30.0, TimerAnnounce, client);
}

public OnMapStart()
{
    new Handle:currentReadyMode = FindConVar("l4d_ready_enabled");
    GetConVarString(currentReadyMode, ReadyMode, sizeof(ReadyMode));

    if (strcmp(ReadyMode, "0", false) == 0)
    {
        Format(Label, sizeof(Label), "启用");
    }
    else if (strcmp(ReadyMode, "1", false) == 0)
    {
        Format(Label, sizeof(Label), "关闭");
    }
}

public Action:TimerAnnounce(Handle:timer, any:client)
{
    if (IsClientInGame(client))
    {
        PrintToChat(client, "[SM] 玩家可以输入 !votes 打开投票菜单.");
    }
}

public Action:Command_Votes(client, args)
{
    if(GetConVarInt(VotensED) == 1)
    {
        new VotensReadyE_D = GetConVarInt(VotensReadyED);
        new VotensMapE_D = GetConVarInt(VotensMapED);

        if(VotensReadyE_D == 0)
        {
            VotensReady_ED = "启用";
        }
        else if(VotensReadyE_D == 1)
        {
            VotensReady_ED = "禁用";
        }

        if(VotensMapE_D == 0)
        {
            VotensMap_ED = "启用";
        }
        else if(VotensMapE_D == 1)
        {
            VotensMap_ED = "禁用";
        }

        new Handle:menu = CreatePanel();
        new String:Value[64];
        SetPanelTitle(menu, "投票菜单");

        if (VotensReadyE_D == 0)
        {
            DrawPanelItem(menu, "投票ready插件 已禁用");
        }
        else if(VotensReadyE_D == 1)
        {
            Format(Value, sizeof(Value), "投票%sready插件", Label);
            DrawPanelItem(menu, Value);
        }

        if (VotensMapE_D == 0)
        {
            DrawPanelItem(menu, "投票换图 已禁用");
        }
        else if (VotensMapE_D == 1)
        {
            DrawPanelItem(menu, "投票换图");
        }

        if (GetUserFlagBits(client) & ADMFLAG_ROOT || GetUserFlagBits(client) & ADMFLAG_CONVARS)
        {
            DrawPanelText(menu, "管理员选项");
            Format(Value, sizeof(Value), "%s 投票ready插件", VotensReady_ED);
            DrawPanelItem(menu, Value);
            Format(Value, sizeof(Value), "%s 投票换图", VotensMap_ED);
            DrawPanelItem(menu, Value);
        }

        DrawPanelText(menu, " \n");
        DrawPanelItem(menu, "关闭");
        SendPanelToClient(menu, client,Votes_Menu, MENU_TIME_FOREVER);

        return Plugin_Handled;
    }
    else if(GetConVarInt(VotensED) == 0)
    {
        //
    }

    return Plugin_Stop;
}

public Votes_Menu(Handle:menu, MenuAction:action, client, itemNum)
{
    if (action == MenuAction_Select)
    {
        new VotensReadyE_D = GetConVarInt(VotensReadyED);
        new VotensMapE_D = GetConVarInt(VotensMapED);

        switch (itemNum)
        {
            case 1:
            {
                if (VotensReadyE_D == 0)
                {
                    FakeClientCommand(client, "sm_votes");
                    PrintToChat(client, "[SM] 投票ready插件 已禁用");
                    return ;
                }
                else if (VotensReadyE_D == 1)
                {
                    FakeClientCommand(client, "votesready");
                }
            }
            case 2:
            {
                if (VotensMapE_D == 0)
                {
                    FakeClientCommand(client, "sm_votes");
                    PrintToChat(client, "[SM] 投票换图 已禁用");
                    return ;
                }
                else if (VotensMapE_D == 1)
                {
                    FakeClientCommand(client, "votesmapsmenu");
                }
            }
            case 3:
            {
                if (VotensReadyE_D == 0 && (GetUserFlagBits(client) & ADMFLAG_ROOT) || (GetUserFlagBits(client) & ADMFLAG_CONVARS) && VotensReadyE_D == 0)
                {
                    SetConVarInt(FindConVar("l4d_VotensreadyED"), 1);
                    PrintToChatAll("\x05[SM] \x04管理员 已启用投票ready插件");
                }
                else if (VotensReadyE_D == 1 && (GetUserFlagBits(client) & ADMFLAG_ROOT) || (GetUserFlagBits(client) & ADMFLAG_CONVARS) && VotensReadyE_D == 1)
                {
                    SetConVarInt(FindConVar("l4d_VotensreadyED"), 0);
                    PrintToChatAll("\x05[SM] \x04管理员 已禁用投票ready插件");
                }
            }
            case 4:
            {
                if (VotensMapE_D == 0 && (GetUserFlagBits(client) & ADMFLAG_ROOT) || (GetUserFlagBits(client) & ADMFLAG_CONVARS) && VotensMapE_D == 0)
                {
                    SetConVarInt(FindConVar("l4d_VotensmapED"), 1);
                    PrintToChatAll("\x05[SM] \x04管理员 已启用投票换图");
                }
                else if (VotensMapE_D == 1 && (GetUserFlagBits(client) & ADMFLAG_ROOT) || (GetUserFlagBits(client) & ADMFLAG_CONVARS) && VotensMapE_D == 1)
                {
                    SetConVarInt(FindConVar("l4d_VotensmapED"), 0);
                    PrintToChatAll("\x05[SM] \x04管理员 已禁用投票换图");
                }
            }
        }
    }
}

public Action:Command_Voter(client, args)
{
    if (GetConVarInt(VotensED) == 1 && GetConVarInt(VotensReadyED) == 1)
    {
        if (IsVoteInProgress())
        {
            ReplyToCommand(client, "[SM] 已有投票在进行中");
            return Plugin_Handled;
        }
        if (!TestVoteDelay(client))
        {
            return Plugin_Handled;
        }

        PrintToChatAll("\x05[SM] \x04%N \x03发起投票 \x05%s \x03ready插件", client, Label);
        PrintToChatAll("\x05[SM] \x04服务器没有玩家的时候 ready插件自动关闭");

        g_voteType = voteType:ready;
        decl String:SteamId[35];
        GetClientAuthId(client, AuthId_Steam2, SteamId, sizeof(SteamId));
        LogMessage("%N %s发起投票%s ready插件!",  client, SteamId, Label);

        g_hVoteMenu = CreateMenu(Handler_VoteCallback, MenuAction:MENU_ACTIONS_ALL);
        SetMenuTitle(g_hVoteMenu, "是否%s ready插件?",Label);
        AddMenuItem(g_hVoteMenu, VOTE_YES, "Yes");
        AddMenuItem(g_hVoteMenu, VOTE_NO, "No");

        SetMenuExitButton(g_hVoteMenu, false);
        VoteMenuToAll(g_hVoteMenu, 20);
        return Plugin_Handled;
    }
    else if(GetConVarInt(VotensED) == 0 && GetConVarInt(VotensReadyED) == 0)
    {
        PrintToChat(client, "[SM] 投票ready插件 已禁用");
    }

    return Plugin_Handled;
}

public Action:Command_VotemapsMenu(client, args)
{
    if (GetConVarInt(VotensED) == 1 && GetConVarInt(VotensMapED) == 1)
    {
        if (!TestVoteDelay(client))
        {
            return Plugin_Handled;
        }

        new Handle:menu = CreateMenu(MapMenuHandler);
        SetMenuTitle(menu, "请选择地图");

        if (game_l4d2)
        {
            AddMenuItem(menu, "c1m1_hotel", "死亡中心");
            AddMenuItem(menu, "c2m1_highway", "黑色狂欢节");
            AddMenuItem(menu, "c3m1_plankcountry", "沼泽激战");
            AddMenuItem(menu, "c4m1_milltown_a", "暴风骤雨");
            AddMenuItem(menu, "c5m1_waterfront", "教区");
            AddMenuItem(menu, "c6m1_riverbank", "短暂时刻");
            AddMenuItem(menu, "c7m1_docks", "牺牲");
            AddMenuItem(menu, "c8m1_apartment", "毫不留情");
            AddMenuItem(menu, "c9m1_alleys", "坠机险途");
            AddMenuItem(menu, "c10m1_caves", "死亡丧钟");
            AddMenuItem(menu, "c11m1_greenhouse", "静寂时分");
            AddMenuItem(menu, "c12m1_hilltop", "血腥收获");
            AddMenuItem(menu, "c13m1_alpinecreek", "刺骨寒溪");
        }
        else
        {
            AddMenuItem(menu, "l4d_vs_hospital01_apartment", "毫不留情");
            AddMenuItem(menu, "l4d_vs_airport01_greenhouse", "静寂时分");
            AddMenuItem(menu, "l4d_vs_smalltown01_caves", "死亡丧钟");
            AddMenuItem(menu, "l4d_vs_farm01_hilltop", "血腥收获");
            AddMenuItem(menu, "l4d_garage01_alleys", "坠机险途");
            AddMenuItem(menu, "l4d_river01_docks", "牺牲");
        }

        SetMenuExitBackButton(menu, true);
        SetMenuExitButton(menu, true);
        DisplayMenu(menu, client, MENU_TIME_FOREVER);

        return Plugin_Handled;
    }
    else if (GetConVarInt(VotensED) == 0 && GetConVarInt(VotensMapED) == 0)
    {
        PrintToChat(client, "[SM] 投票换图 已禁用");
    }

    return Plugin_Handled;
}

public MapMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
    if (action == MenuAction_Select)
    {
        new String:info[32], String:name[32];
        GetMenuItem(menu, itemNum, info, sizeof(info), _, name, sizeof(name));
        votesmaps = info;
        votesmapsname = name;
        PrintToChatAll("\x05[SM] \x04%N 发起投票换图 \x05 %s", client, votesmapsname);
        DisplayVoteMapsMenu(client);
    }
}

public DisplayVoteMapsMenu(client)
{
    if (IsVoteInProgress())
    {
        ReplyToCommand(client, "[SM] 已有投票在进行中");
        return;
    }
    if (!TestVoteDelay(client))
    {
        return;
    }

    g_voteType = voteType:map;
    g_hVoteMenu = CreateMenu(Handler_VoteCallback, MenuAction:MENU_ACTIONS_ALL);

    SetMenuTitle(g_hVoteMenu, "发起投票换图 %s %s",votesmapsname, votesmaps);
    AddMenuItem(g_hVoteMenu, VOTE_YES, "Yes");
    AddMenuItem(g_hVoteMenu, VOTE_NO, "No");
    SetMenuExitButton(g_hVoteMenu, false);
    VoteMenuToAll(g_hVoteMenu, 20);
}

public Handler_VoteCallback(Handle:menu, MenuAction:action, param1, param2)
{
    // ==========================
    if (action == MenuAction_Select)
    {
        switch(param2)
        {
            case 0:
            {
                Votey += 1;
                PrintToChatAll("\x03%N \x05投票了.", param1);
            }
            case 1:
            {
                Voten += 1;
                PrintToChatAll("\x03%N \x04投票了.", param1);
            }
        }
    }
    // ==========================

    decl String:item[64], String:display[64];
    new Float:percent, Float:limit, votes, totalVotes;

    GetMenuVoteInfo(param2, votes, totalVotes);
    GetMenuItem(menu, param1, item, sizeof(item), _, display, sizeof(display));

    if (strcmp(item, VOTE_NO) == 0 && param1 == 1)
    {
        votes = totalVotes - votes;
    }

    percent = GetVotePercent(votes, totalVotes);
    limit = GetConVarFloat(g_Cvar_Limits);

    CheckVotes();

    if (action == MenuAction_End)
    {
        VoteMenuClose();
    }
    else if (action == MenuAction_VoteCancel && param1 == VoteCancel_NoVotes)
    {
        PrintToChatAll("[SM] 没有票数");
    }
    else if (action == MenuAction_VoteEnd)
    {
        if ((strcmp(item, VOTE_YES) == 0 && FloatCompare(percent,limit) < 0 && param1 == 0) || (strcmp(item, VOTE_NO) == 0 && param1 == 1))
        {
            PrintToChatAll("[SM] 投票失败. 至少需要 %d%% 支持.(同意 %d%% 总共 %i 票)", RoundToNearest(100.0 * limit), RoundToNearest(100.0 * percent), totalVotes);
            CreateTimer(2.0, VoteEndDelay);
        }
        else
        {
            PrintToChatAll("[SM] 投票通过.(同意 %d%% 总共 %i 票)", RoundToNearest(100.0 * percent), totalVotes);
            CreateTimer(2.0, VoteEndDelay);
            switch (g_voteType)
            {
                case (voteType:ready):
                {
                    if (strcmp(ReadyMode, "0", false) == 0 || strcmp(item, VOTE_NO) == 0 || strcmp(item, VOTE_YES) == 0)
                    {
                        strcopy(item, sizeof(item), display);
                        ServerCommand("sv_search_key 1");
                        SetConVarInt(FindConVar("l4d_ready_enabled"), 1);
                    }
                    if (strcmp(ReadyMode, "1", false) == 0 || strcmp(item, VOTE_NO) == 0 || strcmp(item, VOTE_YES) == 0)
                    {
                        ServerCommand("sv_search_key 1");
                        SetConVarInt(FindConVar("l4d_ready_enabled"), 0);
                    }
                    PrintToChatAll("[SM] 投票的结果为: %s.", item);
                    LogMessage("投票 %s ready通过", Label);
                }
                case (voteType:map):
                {
                    CreateTimer(5.0, Changelevel_Map);
                    PrintToChatAll("\x03[SM] \x04 5秒后换图 \x05%s", votesmapsname);
                    PrintToChatAll("\x04 %s",votesmaps);
                    LogMessage("投票换图 %s %s 通过", votesmapsname, votesmaps);
                }
            }
        }
    }

    return 0;
}

CheckVotes()
{
    PrintHintTextToAll("同意: \x04%i\n不同意: \x04%i", Votey, Voten);
}

public Action:VoteEndDelay(Handle:timer)
{
    Votey = 0;
    Voten = 0;
}

public Action:Changelevel_Map(Handle:timer)
{
    ServerCommand("changelevel %s", votesmaps);
}

// ===============================
VoteMenuClose()
{
    Votey = 0;
    Voten = 0;
    CloseHandle(g_hVoteMenu);
    g_hVoteMenu = INVALID_HANDLE;
}

Float:GetVotePercent(votes, totalVotes)
{
    return FloatDiv(float(votes), float(totalVotes));
}

bool:TestVoteDelay(client)
{
    new delay = CheckVoteDelay();

    if (delay > 0)
    {
        if (delay > 60)
        {
            PrintToChat(client, "[SM] 您必须再等 %i 分钟後才能发起新一轮投票", delay % 60);
        }
        else
        {
            PrintToChat(client, "[SM] 您必须再等 %i 秒钟後才能发起新一轮投票", delay);
        }
        return false;
    }

    return true;
}
// =======================================

public OnClientDisconnect(client)
{
    if (IsClientInGame(client) && IsFakeClient(client))
    {
        return;
    }

    new Float:currenttime = GetGameTime();

    if (lastDisconnectTime == currenttime)
    {
        return;
    }

    CreateTimer(SCORE_DELAY_EMPTY_SERVER, IsNobodyConnected, currenttime);
    lastDisconnectTime = currenttime;
}

public Action:IsNobodyConnected(Handle:timer, any:timerDisconnectTime)
{
    if (timerDisconnectTime != lastDisconnectTime)
    {
        return Plugin_Stop;
    }

    for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientConnected(i) && !IsFakeClient(i))
        {
            return Plugin_Stop;
        }
    }

    SetConVarInt(FindConVar("l4d_ready_enabled"), 0);

    if (GetConVarBool(cvarFullResetOnEmpty))
    {
        SetConVarInt(FindConVar("l4d_ready_enabled"), 0);
    }

    return  Plugin_Stop;
}
