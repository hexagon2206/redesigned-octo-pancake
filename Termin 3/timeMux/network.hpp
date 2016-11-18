#ifndef __LLU_NETWORK_HPP__
#define __LLU_NETWORK_HPP__

#include <netinet/in.h>
#include <stdlib.h>



namespace llu{
    namespace network{

        struct recivedMessage{
            size_t length;
            size_t dataLength;
            sockaddr_in sender;
            void *data;
        };

        struct sendMessage{
            size_t length;
            const void *data;
        };

        recivedMessage *createRecivedMessage(size_t bufferSize);
        void destoryRecivedMessage(recivedMessage *m);

        sendMessage *createSendMessage(size_t bufferSize);
        void destorySendMessage(sendMessage *m);

        //interaface class for a connection
        class Connection{
            //Es wird blockierend empfangen und die verantwortung für m liegt bei dem aufrufer
            virtual recivedMessage *recvMsg()=0;
            //Die nachricht wird nicht blockierend gesendet und die verantwortung für m liebt bei der Connection
            virtual void sendMsg(sendMessage *m)=0;
        };


    };
};


#endif
