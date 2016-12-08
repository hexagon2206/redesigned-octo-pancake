
            sender = socket (AF_INET, SOCK_DGRAM, 0);

                //NUR BEIM SENDER
            if(0>setsockopt(sender, IPPROTO_IP, IP_MULTICAST_LOOP, &yes, sizeof(yes)))perror("multicastLoopFailed");

                //NUR BEIM SENDER
            if(0>setsockopt(sender, IPPROTO_IP, IP_MULTICAST_TTL, &ttl, sizeof(ttl)))perror("MulticastTTLFailed");



            s = socket (AF_INET, SOCK_DGRAM, 0);
            if(setsockopt(s, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(yes))<0){
                perror("AddrReuse Failed");
            }
            //setsockopt(s, SOL_SOCKET, SO_REUSEPORT, &yes, sizeof(yes));




            cliAddr.sin_family = AF_INET;


            //inet_aton(bcGroup,&cliAddr.sin_addr);

            cliAddr.sin_addr.s_addr = htonl (INADDR_ANY);
            cliAddr.sin_port = htons (myPort);




            if(0>bind ( s, (struct sockaddr *) &cliAddr, sizeof (cliAddr) )){
                perror("bind failed");
            }

            if(bcGroup){

                //NUR BEIM SENDER
                //if(0>setsockopt(s, IPPROTO_IP, IP_MULTICAST_LOOP, &yes, sizeof(yes)))perror("multicastLoopFailed");

                //NUR BEIM SENDER
//                if(0>setsockopt(s, IPPROTO_IP, IP_MULTICAST_TTL, &ttl, sizeof(ttl)))perror("MulticastTTLFailed");


                myMreq.imr_multiaddr.s_addr = inet_addr(bcGroup);

                inet_aton(bcGroup,&myMreq.imr_address);

                //Interface IP Adresse holen und nach
                //imr Interface packen

                //myMreq.imr_address.s_addr = htonl(INADDR_ANY);
                myMreq.imr_ifindex = if_nametoindex(interface);

                if(0>setsockopt(s, IPPROTO_IP, IP_MULTICAST_IF, &myMreq, sizeof(myMreq)))perror("COULD not set interface");

                if( setsockopt (s, IPPROTO_IP, IP_ADD_MEMBERSHIP, &myMreq, sizeof(myMreq))<0){
                    perror("could not join MC Group");
                }
            }
