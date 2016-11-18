#ifndef __LLU_UDP_H__
#define __LLU_UDP_H__
#include <netinet/in.h>
#include <sys/types.h>
#include <sys/socket.h>

#include "network.hpp"


namespace llu{
    namespace network{
        class UdpConnection : public Connection {

            UdpConnection(const char *server,uint16_t port,char ttl = 1);

            recivedMessage *recvMsg();

            void sendMsg(sendMessage *m);

        };
    };
};

#endif
