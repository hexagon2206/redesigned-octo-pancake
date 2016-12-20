/** @file udp.cpp
 *  @brief Implementation of a UDP Connection.
 *  @author Lukas Lühr (hexagon2206)
 *  @bug No known bugs.
 */

#include "udp.hpp"
#include <iostream>

namespace llu{
    namespace network{
        UdpConnection::UdpConnection(char *bcGroup,uint16_t myPort,char *interface,char ttl,size_t maxRcvMsgLeng){

            int yes=1;

            //Setting up sender
            if(0>(this->sender=socket(AF_INET,SOCK_DGRAM,0))){
                perror("error setting up sender socket");
            }

            memset((char*)&this->groupAddr,0,sizeof(this->groupAddr));
            this->groupAddr.sin_family = AF_INET;
            this->groupAddr.sin_addr.s_addr = inet_addr(bcGroup);
            this->groupAddr.sin_port = htons(myPort);

            if(0>setsockopt(this->sender, IPPROTO_IP, IP_MULTICAST_LOOP, &yes, sizeof(yes))){
                perror("error setting loopback");
            }

            if(0>setsockopt(this->sender, IPPROTO_IP, IP_MULTICAST_TTL, &yes, sizeof(yes))){
                perror("error setting TTL");
            }

            struct in_addr localInterface;
            memset((char*)&localInterface,0,sizeof(localInterface));

            localInterface.s_addr = inet_addr(interface);
            if(0>setsockopt(sender, IPPROTO_IP, IP_MULTICAST_IF, (char *)&localInterface, sizeof(localInterface))){
              perror("Setting local interface error");
            }

            //setting up Reciver
            reciver = socket(AF_INET, SOCK_DGRAM,0);

            if(0>setsockopt(reciver, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(yes))){
                perror("Setting SO_REUSEADDR error");
            }

            memset((char *) &localSock, 0, sizeof(localSock));
            localSock.sin_family = AF_INET;
            localSock.sin_port = htons(myPort);
            localSock.sin_addr.s_addr = inet_addr(bcGroup);
            if(bind(reciver, (struct sockaddr*)&localSock, sizeof(localSock))){
                perror("Binding datagram socket error");
            }

            memset((char *) &group, 0, sizeof(group));
            group.imr_multiaddr.s_addr = inet_addr(bcGroup);
            group.imr_interface.s_addr = inet_addr(interface);
            if(0>setsockopt(reciver, IPPROTO_IP, IP_ADD_MEMBERSHIP, (char *)&group, sizeof(group))){
                perror("Adding multicast group error");
            }


            this->maxRcvMsgLeng=maxRcvMsgLeng;
        }

        recivedMessage *UdpConnection::recvMsg(){
            currentMsg = llu::network::createRecivedMessage(maxRcvMsgLeng);
            socklen_t len = (socklen_t) sizeof(currentMsg->sender);
            currentMsg->dataLength = recvfrom ( reciver, currentMsg->data, currentMsg->length, 0,(struct sockaddr *) &currentMsg->sender,&len);
            recivedMessage *t=currentMsg;
            currentMsg=nullptr;
            return t;
        }

        void UdpConnection::sendMsg(sendMessage *m){
            sendto(sender,m->data, m->length,0 ,(const sockaddr *)&this->groupAddr, sizeof (this->groupAddr));
            destorySendMessage(m);
        }


        bool UdpConnection::alive(){
            return true; //TODO: FICEN !!!
        }

        void UdpConnection::kill(){
            if(currentMsg!=nullptr)destoryRecivedMessage(currentMsg);
            shutdown(reciver,2);
        }


    }
}
