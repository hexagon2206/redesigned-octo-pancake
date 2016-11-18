#ifndef __LLU_UDP_H__
#define __LLU_UDP_H__
#include <netinet/in.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>

#include <cstring>


#include "network.hpp"
#include "ringBuffer.hpp"

namespace llu{
    namespace network{
        using namespace std;
        class UdpConnection : public Connection {
            public :
                UdpConnection(const char *server,uint16_t targetPort,char ttl = 1,uint16_t myPort=0,size_t queueSize=128,size_t maxMsgLeng=128);
                ~UdpConnection();

                recivedMessage *recvMsg();

                void sendMsg(sendMessage *m);

            private :
                recivedMessage *currentMsg;
                llu::datastructs::Ringbuffer<sendMessage *> *outQueue;

                struct sockaddr_in  cliAddr,
                                    tmpAddr,
                                    remoteServAddr;
                size_t maxMsgLeng;
                int s;
                struct hostent *h;


        };
    };
};

#endif
