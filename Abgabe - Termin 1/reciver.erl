%reciver.erl
% nur für debug zwecke

-module(reciver).
-export([start/0]).	%Startet einen Reciver thread welcher alles ausgiebt was er empfängt

start() ->
	spawn( fun() -> loop() end ).

loop() -> 
	receive
		D -> io:format("~p~n",[D]),
			loop()
	end.
