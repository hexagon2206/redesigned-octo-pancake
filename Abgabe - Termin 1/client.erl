%client.erl
%siehe diagramm(client).
-module(client).
-export([init/1]).	% Liest die Config Datei ein und erstellt entsprechend clients

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

  startClients(LogFile,LifeTime*1000, Server, ClientCount, Interval*1000).

startClients(_LogFile,_LifeTime, _Server, 0, _Interval) ->
  io:format("Alle Clients wurden gestartet ~n");

startClients(LogFile,LifeTime, Server, ClientCount, Interval) ->
  io:format("Starte Clientnummer: ~p ~n ", [ClientCount]),
  spawn(fun () -> init(ClientCount,LogFile,Server, LifeTime, Interval) end),
  startClients(LogFile,LifeTime, Server, ClientCount - 1, Interval).




% Functions
init(ClientNR,LogFile,Server, Lifetime, Interval) ->
  ClientBez=lists:flatten(io_lib:format("Client[~p]", [ClientNR])),
  timer:send_after(Lifetime,{kill}),
  tool:l(LogFile,ClientBez," UP "),
  writeCycle(ClientBez,Server, 0, Interval, LogFile).

% ############################################### ClientWriter - Logic ################################################################ %

newSleepTime(SleepTime) ->
  newSleepTime(SleepTime,random:uniform(2)).

newSleepTime(SleepTime,1) ->
  TMP = SleepTime / 2 ,
  if
    TMP < 2000 ->
      2000;
    true ->
      TMP
  end;

newSleepTime(SleepTime,2) ->
  SleepTime * 2 .

quit() ->  ok.

% 6. Nummer Wird ignoriert
writeCycle(ClientBez,Server, MessageCounter, SleepTime, LogFile) when MessageCounter > 4 ->
  Server ! {self(), getmsgid},
  receive
    {kill} ->
      quit();
    {nid, ID} -> 
        tool:l(LogFile,ClientBez,"Nachrichtnummer: ~p wird verworfen | Zeitstempel:  ~p ", [ID, werkzeug:timeMilliSecond()]),
        tool:l(LogFile,ClientBez,"Starting ReadCycle"),  
        readCycle(ClientBez,Server, newSleepTime(SleepTime), LogFile)
  end;
  % Reader starten

% Normaler Ablauf
writeCycle(ClientBez,Server, MessageCounter, SleepTime, LogFile) ->
  Server ! {self(), getmsgid},
  receive
    {kill} ->
      quit();
    {nid, ID} -> 
      timer:sleep(SleepTime),
      dropMessage(ClientBez,Server, ID , LogFile),
      writeCycle(ClientBez,Server, MessageCounter+1, SleepTime, LogFile)
  end.
  
% Eine Zufallszeit "schlafen" und anschließend eine neue Nachricht an den Server schicken
dropMessage(ClientBez,Server, MessageID , LogFile) ->
  MSGText = io_lib:format("Team 02 : ~p - ~p",[ClientBez,node()]),
  Server ! {dropmessage, [MessageID, MSGText, tool:t()]},
  tool:l(LogFile,ClientBez,"Nachrichtnummer: ~p gesendet ", [MessageID]).


% ############################################### ClientReader - Logic ################################################################ %

readCycle(ClientBez,Server, SleepTime, LogFile) ->
  Server ! {self(), getmessages},
  receive
    {kill} ->
      quit();
    {reply, Message, false} ->
      printMSG(LogFile,ClientBez,Message,tool:t()),
      readCycle(ClientBez,Server, SleepTime, LogFile);
    {reply, Message, true} ->
      printMSG(LogFile,ClientBez,Message,tool:t()),
      tool:l(LogFile,ClientBez,"Alle Nachrichten Gelesen"),
      writeCycle(ClientBez,Server, 0, SleepTime, LogFile)

  end.


printMSG(LogFile,ClientBez,Message,Now) ->
      [MsgNumber, _Msg, _ClientOut, _HBQin, _DLQin, DLQout] = Message,

      LOE = werkzeug:lessoeqTS(Now,DLQout),
      if
        LOE ->
          tool:l(LogFile,ClientBez,"Nachrichtnummer: ~p empfangen | Nachricht: ~p | Nachricht aus der Zukunft:  ~p ~n", [MsgNumber, Message , werkzeug:diffTS(Now,DLQout)]);
        true ->
          tool:l(LogFile,ClientBez,"Nachrichtnummer: ~p empfangen | Nachricht: ~p ", [MsgNumber, Message])          
      end.
