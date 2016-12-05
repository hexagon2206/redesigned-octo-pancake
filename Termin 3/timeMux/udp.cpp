/** @file udp.cpp
 *  @brief Implementation of a UDP Connection.
 *  @author Lukas Lühr (hexagon2206)
 *  @bug No known bugs.
 */

#include "udp.hpp"
#include <iostream>

namespace llu{
    namespace network{
        UdpConnection::UdpConnection(char *bcGroup,uint16_t myPort,char ttl,size_t maxRcvMsgLeng){

            sender = socket (AF_INET, SOCK_DGRAM, 0);

            s = socket (AF_INET, SOCK_DGRAM, 0);
            unsigned int yes=1;
            if(setsockopt(s, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(yes))<0){
                perror("AddrReuse Failed");
            }
            //setsockopt(s, SOL_SOCKET, SO_REUSEPORT, &yes, sizeof(yes));



            cliAddr.sin_family = AF_INET;
            cliAddr.sin_addr.s_addr = htonl (INADDR_ANY);
            cliAddr.sin_port = htons (myPort);




            if(0>bind ( s, (struct sockaddr *) &cliAddr, sizeof (cliAddr) )){
                perror("bind failed");
            }

            if(bcGroup){
                if(0>setsockopt(s, IPPROTO_IP, IP_MULTICAST_LOOP, &yes, sizeof(yes)))perror("multicastLoopFailed");

                if(0>setsockopt(s, IPPROTO_IP, IP_MULTICAST_TTL, &ttl, sizeof(ttl)))perror("MulticastTTLFailed");

                myMreq.imr_multiaddr.s_addr = inet_addr(bcGroup);
                myMreq.imr_interface.s_addr = htonl(INADDR_ANY);

                if( setsockopt (s, IPPROTO_IP, IP_ADD_MEMBERSHIP, &myMreq, sizeof(myMreq))<0){
                    perror("could not join MC Group");
                }
            }

            this->maxRcvMsgLeng=maxRcvMsgLeng;
            currentMsg = llu::network::createRecivedMessage(maxRcvMsgLeng);
        }

        recivedMessage *UdpConnection::recvMsg(){
            socklen_t len = (socklen_t) sizeof(currentMsg->sender);
            currentMsg->dataLength = recvfrom ( s, currentMsg->data, currentMsg->length, 0,(struct sockaddr *) &currentMsg->sender,&len);
            std::cout << "msg empfangen" << std::endl;
            recivedMessage *t=currentMsg;
            currentMsg = llu::network::createRecivedMessage(maxRcvMsgLeng);
            return t;
        }

        void UdpConnection::sendMsg(sendMessage *m){
            sendto(sender,m->data, m->length,0 ,(struct sockaddr *) &m->target, sizeof (m->target));
            destorySendMessage(m);
        }


        bool UdpConnection::alive(){
            return true; //TODO: FICEN !!!
        }

        void UdpConnection::kill(){
            destoryRecivedMessage(currentMsg);
            shutdown(s,2);
        }


    }
}
