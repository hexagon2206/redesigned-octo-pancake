-module(client).


% API
-export([init/1, init/3]).


% Functions

init(Server, Lifetime, Interval) ->
  LogFile = atom_to_list(node()) ++ ".log",
  getMessageID(Server, 0, Interval, LogFile).

init(ConfigFile) ->

  % Liest aus der Config - Datei die Parameter
  {ok, Config} = file:consult(ConfigFile),
  {ok, Lifetime} = werkzeug:get_config_value(lifetime, Config),
  {ok, ServerName} = werkzeug:get_config_value(servername, Config),
  {ok, ServerNode} = werkzeug:get_config_value(servernode, Config),
  {ok, ClientCount} = werkzeug:get_config_value(clients, Config),
  {ok, Interval} = werkzeug:get_config_value(sendeintervall, Config),

  Server = {ServerName, ServerNode},
  LogFile = atom_to_list(node()) ++ ".log",
  getMessageID(Server, 0, Interval * 1000, LogFile).

% ############################################### ClientWriter - Logic ################################################################ %
getMessageID(Server, MessageCounter, SleepTime, LogFile) ->

  Server ! {self(), getmsgid},

  case MessageCounter == 5 of
    % Neue Zufallszahl generieren und die Antwort des Servers ausfiltern
    true ->
      receive
        {nid, ID} -> io:format("~p ~n", [ID])
      end,

    werkzeug:logging(LogFile, io:format("Nachrichtnummer: ~p nicht | Zeitstempel:  ~p ~n", [MessageCounter, werkzeug:timeMilliSecond()])),

    % Reader starten
    getMessages(Server, LogFile, 0, SleepTime);

    % Antwort vom Server verarbeiten und Nachricht an Server vorbereiten
    false ->
      receive
        {nid, ID} -> dropMessage(Server, ID, MessageCounter + 1, SleepTime, LogFile)
      end
  end.

% Eine Zufallszeit "schlafen" und anschließend eine neue Nachricht an den Server schicken
dropMessage(Server, MessageID, MessageCounter, SleepTime, LogFile) ->

  timer:sleep(SleepTime),

  werkzeug:logging(LogFile, io:format("Nachrichtnummer: ~p gesendet | Zeitstempel:  ~p ~n", [MessageID, erlang:now()])),

  Server ! {dropmessage, [MessageID, "Hallo Welt", werkzeug:timeMilliSecond()]}, % alternative : erlang:system_time(). -> aktuelle Zeit in Milisekunden
  getMessageID(Server, MessageCounter, SleepTime, LogFile).


% ############################################### ClientReader - Logic ################################################################ %

getMessages(Server, LogFile, MessageCounter, SleepTime) ->

  Server ! {self(), getmessages},
  io:format("Anfrage gestellt ~n "),
  receiveReply(Server, LogFile, MessageCounter, SleepTime).

receiveReply(Server, LogFile, MessageCounter, SleepTime) ->

  receive
    {reply, Message, false} ->
      [MsgNumber, Msg, ClientOut, HBQin, DLQin, DLQout] = Message,
      if
        werkzeug:lessoeqTS(DLQin, DLQout) ->
          werkzeug:logging(LogFile, io:format("Nachrichtnummer: ~p empfangen | Nachricht: ~p | Nachricht aus der Zukunft:  ~p ~n", [MsgNumber, [Msg] , werkzeug:diffTS(DLQin, DLQout)])),
      end

      werkzeug:logging(LogFile, io:format("Nachrichtnummer: ~p empfangen | Nachricht: ~p |Zeitstempel:  ~p ~n", [MsgNumber, [Msg] ,werkzeug:timeMilliSecond()])),

      getMessages(Server, LogFile, MessageCounter, SleepTime);

    {reply, Message, true} ->
      getMessageID(Server, MessageCounter, (rand:uniform(5) * 2000), LogFile)
  end.
