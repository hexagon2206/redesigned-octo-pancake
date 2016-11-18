#include "udp.hpp"

namespace llu{
    namespace network{
        UdpConnection::UdpConnection(const char *server,uint16_t targetPort,char ttl,uint16_t myPort,size_t maxRcvMsgLeng){
            this->maxRcvMsgLeng = maxRcvMsgLeng;

            struct hostent *h = gethostbyname (server);

            remoteServAddr.sin_family = h->h_addrtype;
            memcpy ( (char *) &remoteServAddr.sin_addr.s_addr,h->h_addr_list[0], h->h_length);
            remoteServAddr.sin_port = htons (targetPort);

            //free(h);//TODO:?

            s = socket (AF_INET, SOCK_DGRAM, 0);
            setsockopt(s, IPPROTO_IP, IP_TTL, &ttl, sizeof(ttl));

            cliAddr.sin_family = AF_INET;
            cliAddr.sin_addr.s_addr = htonl (INADDR_ANY);
            cliAddr.sin_port = htons (myPort);

            bind ( s, (struct sockaddr *) &cliAddr, sizeof (cliAddr) );

            currentMsg = llu::network::createRecivedMessage(maxRcvMsgLeng);
        }
        UdpConnection::~UdpConnection(){
            destoryRecivedMessage(currentMsg);
            kill();
        }


        recivedMessage *UdpConnection::recvMsg(){
            socklen_t len = (socklen_t) sizeof(currentMsg->sender);
            currentMsg->length = recvfrom ( s, currentMsg->data, currentMsg->dataLength, 0,(struct sockaddr *) &currentMsg->sender,&len);
            recivedMessage *t=currentMsg;
            currentMsg = llu::network::createRecivedMessage(maxRcvMsgLeng);
            return t;
        }

        void UdpConnection::sendMsg(sendMessage *m){
            sendto (s,m->data , m->length,0 ,(struct sockaddr *) &remoteServAddr, sizeof (remoteServAddr));
        }


        bool UdpConnection::alive(){
            return true; //TODO: FICEN !!!
        }

        void UdpConnection::kill(){
            shutdown(s,2);
        }


    };
};
