-module(clientWriter).
-author(flo).


% API
-export([init/1]).

% Logic

init(Server) ->
%  spawn(fun() -> keepAlive(Server) end),
  getMessageID(Server, 0, 2000).

getMessageID(Server, MessageCounter, SleepTime) ->

  Server ! {self(), getmsgid},

  case MessageCounter == 5 of
    % Neue Zufallszahl generieren und die Antwort des Servers ausfiltern
    true ->
        getMessageID(Server, 0, (randdom:uniform(5) * 2000)),

        receive
          {"MessageID", ID} -> io:format("~p \n", ID)
        end;

        %TODO: Loggen

    % Antwort vom Server verarbeiten und Nachricht an Server vorbereiten
    false ->
      receive
        {"MessageID", ID} -> dropMessage(Server, ID, MessageCounter + 1, SleepTime)
      end
  end.

% Eine Zufallszeit "schlafen" und anschließend eine neue Nachricht an den Server schicken
dropMessage(Server, MessageID, MessageCounter, SleepTime) ->

  timer:sleep(SleepTime),

  Server ! {dropMessage, [MessageID, "Hallo Welt", erlang:system_time()]}, % alternative : erlang:system_time(). -> aktuelle Zeit in Milisekunden
  getMessageID(Server, MessageCounter, SleepTime).

keepAlive(Server) ->
  % hostname + group + team
  M = node() ++ "1" ++ "02",
  Server ! {[M, erlang:localtime()]},
  timer:sleep(2000).
