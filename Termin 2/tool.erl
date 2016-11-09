% tool.erl
% eine hilfs datei, ist nicht notwendig da die inzelenn funktionen einfach ersetzt werden könnten.
% dient lediglich der Strukturierung des Codes 

-module(tool).
-export([l/3]).	% loging daten im text
-export([l/4]).	% logging mit daten im text
-export([t/0]).	% Generiert einen Timestamp

-export([format/2]).	% Erfragt eim NameService Die PID des Empfängers und sendet MSG fals möglich an ihn

-export([send/3]).	% Erfragt eim NameService Die PID des Empfängers und sendet MSG fals möglich an ihn


l(File,Who,Text) ->
	l(File,Who,Text,[]).
l(File,Who,Text,Data) ->
	werkzeug:logging(File,io_lib:format("~p - ~p: "++Text++"~n",[werkzeug:timeMilliSecond(),Who|Data])).

%used for dictgetting a Time Stamp
t() -> erlang:system_time().

format(Text,List) -> 
	lists:flatten(io_lib:format(Text,List)).

send(To,NSName,MSG) -> 
	NSPID = global:whereis_name(NSName),
	NSPID ! {self(),{lookup,To}},
	receive 
		{pin,X} -> 
			X ! MSG,
			ok;
        not_found -> 
        	nok 
	end.