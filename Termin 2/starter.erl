-module(starter).
-author("flo").

-export([init/1]).

init(StarterNumber) ->

    % Liest aus der Config - Datei die Parameter
    {ok, Config} = file:consult("ggt.cfg"),
    {ok, Group} = werkzeug:get_config_value(praktikumsgruppe, Config),
    {ok, Team} = werkzeug:get_config_value(teamnummer, Config),
    {ok, NameServiceNode} = werkzeug:get_config_value(nameservicenode, Config),
    {ok, NameServiceName} = werkzeug:get_config_value(nameservicename, Config),
    {ok, Coordinator} = werkzeug:get_config_value(koordinatorname, Config),

    io:format("~p~n",[Config]),
    net_adm:ping(NameServiceNode),
    % Fürs Sync wichtig
    timer:sleep(500),

    getParameters(Coordinator, Group, Team, StarterNumber, NameServiceName).

% Ruft die Steuerungsparamter für die ggt - Prozesse ab
getParameters(Coordinator, Group, Team ,StarterNumber, NameServiceName) ->
    % Coordinator beim NameServiceName abfragen
    tool:send(Coordinator,NameServiceName,{self(), getsteeringval}),
    receive
        {steeringval, WorkTime, TerminationTime, Quota, ProcessCount} ->
            startGGTprocesses(ProcessCount, WorkTime, TerminationTime, Group, Team, StarterNumber, NameServiceName, Coordinator, Quota)
    end.

% Startet die ggt - Prozesse
startGGTprocesses(0, Delay, TerminationTime, Group, Team, StarterNumber, NameServiceName, Coordinator, Quota) ->
    ClientName = list_to_atom(tool:format("~p~p~p~p",[Group,Team,0,StarterNumber])),
    spawn(fun() -> ggt_process:init(Delay, TerminationTime, ClientName, NameServiceName, Coordinator, Quota)end);

startGGTprocesses(ProcessCount, Delay, TerminationTime, Group, Team, StarterNumber, NameServiceName, Coordinator, Quota) ->
    ClientName = list_to_atom(tool:format("~p~p~p~p",[Group,Team,ProcessCount,StarterNumber])),
    spawn(fun() -> ggt_process:init(Delay, TerminationTime, ClientName, NameServiceName, Coordinator, Quota) end),
    startGGTprocesses(ProcessCount - 1, Delay, TerminationTime, Group, Team, StarterNumber, NameServiceName, Coordinator, Quota).
