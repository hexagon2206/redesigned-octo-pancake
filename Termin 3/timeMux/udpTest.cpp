/** @file udp.cpp
 *  @brief Implementation of a UDP Connection.
 *  @author Lukas Lühr (hexagon2206)
 *  @bug No known bugs.
 */

#include "udpTest.hpp"
#include <iostream>

namespace llu{
    namespace network{
        UdpTestConnection::UdpTestConnection(uint16_t myPort,size_t maxRcvMsgLeng){

            s = socket (AF_INET, SOCK_DGRAM, 0);

            cliAddr.sin_family = AF_INET;
            cliAddr.sin_addr.s_addr = htonl (INADDR_ANY);
            cliAddr.sin_port = htons (myPort);




            if(0>bind ( s, (struct sockaddr *) &cliAddr, sizeof (cliAddr) )){
                perror("bind failed");
            }


            this->maxRcvMsgLeng=maxRcvMsgLeng;
            currentMsg = llu::network::createRecivedMessage(maxRcvMsgLeng);
        }

        recivedMessage *UdpTestConnection::recvMsg(){
            socklen_t len = (socklen_t) sizeof(currentMsg->sender);
            currentMsg->dataLength = recvfrom ( s, currentMsg->data, currentMsg->length, 0,(struct sockaddr *) &currentMsg->sender,&len);
            recivedMessage *t=currentMsg;
            currentMsg = llu::network::createRecivedMessage(maxRcvMsgLeng);
            return t;
        }

        void UdpTestConnection::sendMsg(sendMessage *m){
            sendto(s,m->data, m->length,0 ,(struct sockaddr *) &m->target, sizeof (m->target));
            destorySendMessage(m);
        }


        bool UdpTestConnection::alive(){
            return true; //TODO: FICEN !!!
        }

        void UdpTestConnection::kill(){
            destoryRecivedMessage(currentMsg);
            shutdown(s,2);
        }


    }
}
