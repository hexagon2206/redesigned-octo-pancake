#include "network.hpp"


namespace llu{
    namespace network{
         recivedMessage *createRecivableMessage(size_t bufferSize){
            recivedMessage *m = (recivedMessage*)malloc(sizeof(recivedMessage)+sizeof(char)*bufferSize);
            m->length       = bufferSize;
            m->dataLength   = 0;
            m->data         = (void*)(m+1);
        }

        sendMessage *createSendMessage(size_t bufferSize){
            sendMessage *m = (sendMessage *)malloc(sizeof(sendMessage)+sizeof(char)*bufferSize);
            m->length   = bufferSize;
            m->data     = (void*)(m+1);
        }

    };
};
