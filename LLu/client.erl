-module(numberService).
-export([start/0]).


start() ->
	{ok, Clients} = file:consult("server.cfg"),
    {ok, Lifetime} = werkzeug:get_config_value(clientlifetime, ConfigListe),
	{ok, Servername} = werkzeug:get_config_value(servername, ConfigListe),
	{ok, Servernode} = werkzeug:get_config_value(servername, ConfigListe),
	{ok, Sendeintervall} = werkzeug:get_config_value(servername, ConfigListe),


	{clients, 1}.
	{lifetime, 42}.
	{servername, wk}.
	{servernode, 'SERVER@WERUM2293.werum.net'}.
	{sendeintervall, 3}.