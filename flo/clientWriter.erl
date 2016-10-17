-module(clientWriter).
-author(flo).


% API
-export([init/2]).

% Logic

init(Server, LogFile) ->

%  werkzeug:logging(LogFile, node() ++ "Startzeit: " ++ erlang:localtime()),
  werkzeug:logging(LogFile, io:format("~p Startzeit: ~p ~n", [node(), erlang:localtime()]),
  getMessageID(Server, 0, 2000, LogFile).

getMessageID(Server, MessageCounter, SleepTime, LogFile) ->

  Server ! {self(), getmsgid},

  case MessageCounter == 5 of
    % Neue Zufallszahl generieren und die Antwort des Servers ausfiltern
    true ->
        getMessageID(Server, 0, (randdom:uniform(5) * 2000), LogFile),
		    werkzeug:logging(LogFile, node() ++ "Nachricht: " ++ MessageCounter ++ " nicht gesendet" ++ werkzeug:timeMilliSecond()),

        receive
          {"MessageID", ID} -> io:format("~p \n", ID)
        end;

    % Antwort vom Server verarbeiten und Nachricht an Server vorbereiten
    false ->
      receive
        {"MessageID", ID} -> dropMessage(Server, ID, MessageCounter + 1, SleepTime, LogFile)
      end
  end.

% Eine Zufallszeit "schlafen" und anschlieߟend eine neue Nachricht an den Server schicken
dropMessage(Server, MessageID, MessageCounter, SleepTime, LogFile) ->

  timer:sleep(SleepTime),

  werkzeug:logging(LogFile, node() ++ "Nachrichtnummer: " ++ MessageCounter ++ " gesendet | Out" ++ werkzeug:timeMilliSecond()),

  Server ! {dropMessage, [MessageID, "Hallo Welt", erlang:system_time()]}, % alternative : erlang:system_time(). -> aktuelle Zeit in Milisekunden
  getMessageID(Server, MessageCounter, SleepTime, LogFile).
