-module(clientLauncher).

% API
-export([init/1]).

init(ConfigFile) ->
  % Liest aus der Config - Datei die Parameter
  {ok, Config} = file:consult(ConfigFile),
  {ok, LifeTime} = werkzeug:get_config_value(lifetime, Config),
  {ok, ServerName} = werkzeug:get_config_value(servername, Config),
  {ok, ServerNode} = werkzeug:get_config_value(servernode, Config),
  {ok, ClientCount} = werkzeug:get_config_value(clients, Config),
  {ok, Interval} = werkzeug:get_config_value(sendeintervall, Config),

  Server = {ServerName, ServerNode},
  LogFile = atom_to_list(node()) ++ ".log",


  startClients(LogFile,LifeTime, Server, ClientCount, Interval).

startClients(_LogFile,_LifeTime, _Server, 0, _Interval) ->
  io:format("Alle Clients wurden gestartet ~n");

startClients(LogFile,LifeTime, Server, ClientCount, Interval) ->
  io:format("Starte Clientnummer: ~p ~n ", [ClientCount]),
  spawn(fun () -> client:init(ClientCount,LogFile,Server, LifeTime, Interval) end),
  startClients(LogFile,LifeTime, Server, ClientCount - 1, Interval).
