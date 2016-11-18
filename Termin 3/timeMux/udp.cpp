#include "udp.hpp"

namespace llu{
    namespace network{
        UdpConnection::UdpConnection(const char *server,uint16_t targetPort,char ttl,uint16_t myPort,size_t queueSize,size_t maxMsgLeng){
            this->maxMsgLeng = maxMsgLeng;
            this->outQueue = new llu::datastructs::Ringbuffer<sendMessage *>(queueSize);

            struct hostent *h = gethostbyname (server);

            remoteServAddr.sin_family = h->h_addrtype;
            memcpy ( (char *) &remoteServAddr.sin_addr.s_addr,h->h_addr_list[0], h->h_length);
            remoteServAddr.sin_port = htons (targetPort);

            free(h);//TODO:?

            s = socket (AF_INET, SOCK_DGRAM, 0);

            cliAddr.sin_family = AF_INET;
            cliAddr.sin_addr.s_addr = htonl (INADDR_ANY);
            cliAddr.sin_port = htons (myPort);

            bind ( s, (struct sockaddr *) &cliAddr, sizeof (cliAddr) );

            currentMsg = llu::network::createRecivedMessage(maxMsgLeng);
        }
        UdpConnection::~UdpConnection(){
            delete this->outQueue;
        }


        recivedMessage *UdpConnection::recvMsg(){
            socklen_t len = (socklen_t) sizeof(currentMsg->sender);
            currentMsg->length = recvfrom ( s, currentMsg->data, currentMsg->dataLength, 0,(struct sockaddr *) &currentMsg->sender,&len);
            recivedMessage *t=currentMsg;
            currentMsg = llu::network::createRecivedMessage(maxMsgLeng);
            return t;
        }

        void UdpConnection::sendMsg(sendMessage *m){
            this->outQueue->put(m);
        }


    };
};
