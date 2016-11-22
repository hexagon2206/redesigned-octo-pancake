#ifndef __LLU_UDP_H__
#define __LLU_UDP_H__
#include <netinet/in.h>
#include <sys/types.h>
#include <sys/socket.h>


#include <cstring>


#include "network.hpp"
#include "ringBuffer.hpp"

namespace llu{
    namespace network{
        using namespace std;
        class UdpConnection : public Connection {
            public :
                UdpConnection(char ttl = 1,uint16_t myPort=0,size_t maxRcvMsgLeng=128);

                recivedMessage *recvMsg();

                void sendMsg(sendMessage *m);

                bool alive();

                void kill();

            private :
                recivedMessage *currentMsg;

                struct sockaddr_in  cliAddr,
                                    tmpAddr;
                size_t maxRcvMsgLeng;
                int s;
                struct hostent *h;


        };
    };
};

#endif
