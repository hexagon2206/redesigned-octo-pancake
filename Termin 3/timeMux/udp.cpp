/** @file udp.cpp
 *  @brief Implementation of a UDP Connection.
 *  @author Lukas Lühr (hexagon2206)
 *  @bug No known bugs.
 */

#include "udp.hpp"
#include <iostream>

namespace llu{
    namespace network{
        UdpConnection::UdpConnection(char ttl,uint16_t myPort,size_t maxRcvMsgLeng){

            s = socket (AF_INET, SOCK_DGRAM, 0);
            setsockopt(s, IPPROTO_IP, IP_TTL, &ttl, sizeof(ttl));

            cliAddr.sin_family = AF_INET;
            cliAddr.sin_addr.s_addr = htonl (INADDR_ANY);
            cliAddr.sin_port = htons (myPort);

            bind ( s, (struct sockaddr *) &cliAddr, sizeof (cliAddr) );
            this->maxRcvMsgLeng=maxRcvMsgLeng;
            currentMsg = llu::network::createRecivedMessage(maxRcvMsgLeng);
        }



        recivedMessage *UdpConnection::recvMsg(){
            socklen_t len = (socklen_t) sizeof(currentMsg->sender);
            currentMsg->dataLength = recvfrom ( s, currentMsg->data, currentMsg->length, 0,(struct sockaddr *) &currentMsg->sender,&len);
            recivedMessage *t=currentMsg;
            currentMsg = llu::network::createRecivedMessage(maxRcvMsgLeng);
            return t;
        }

        void UdpConnection::sendMsg(sendMessage *m){
            sendto(s,m->data, m->length,0 ,(struct sockaddr *) &m->target, sizeof (m->target));
            destorySendMessage(m);
        }


        bool UdpConnection::alive(){
            return true; //TODO: FICEN !!!
        }

        void UdpConnection::kill(){
            destoryRecivedMessage(currentMsg);
            shutdown(s,2);
        }


    };
};
