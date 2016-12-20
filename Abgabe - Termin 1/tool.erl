% tool.erl
% eine hilfs datei, ist nicht notwendig da die inzelenn funktionen einfach ersetzt werden könnten.
% dient lediglich der Strukturierung des Codes 

-module(tool).
-export([l/3]).	% loging daten im text
-export([l/4]).	% logging mit daten im text
-export([t/0]).	% Generiert einen Timestamp

l(File,Who,Text) ->
	l(File,Who,Text,[]).
l(File,Who,Text,Data) ->
	werkzeug:logging(File,io_lib:format("~p - ~p: "++Text++"~n",[werkzeug:timeMilliSecond(),Who|Data])).

%used for getting a Time Stamp
t() -> erlang:now().