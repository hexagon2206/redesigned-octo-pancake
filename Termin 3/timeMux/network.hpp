#ifndef __LLU_NETWORK_HPP__
#define __LLU_NETWORK_HPP__

#include <stdlib.h>
#include <string.h>
#include <thread>
#include <netdb.h>
#include <stdlib.h>


#include <netinet/in.h>
#include <arpa/inet.h>


#include "callback.hpp"
#include "ringBuffer.hpp"
#include "linkedList.hpp"


namespace llu{
    namespace network{

        using namespace std;

        using namespace llu::callback;
        using namespace llu::datastructs;

        sockaddr_in resolve(const char*addr,uint16_t port);

        struct recivedMessage{
            size_t length;
            size_t dataLength;
            sockaddr_in sender;
            void *data;
        };

        struct sendMessage{
            size_t length;
            sockaddr_in target;
            void *data;
        };

        recivedMessage *createRecivedMessage(size_t bufferSize);
        void destoryRecivedMessage(recivedMessage *m);

        sendMessage *createSendMessage(size_t bufferSize,sockaddr_in target,const void *from);
        void destorySendMessage(sendMessage *m);

        //interaface class for a connection, NOT THREAD SAFE
        class Connection{
            public:

                virtual ~Connection(){};
                //Es wird blockierend empfangen und die verantwortung für m liegt bei dem aufrufer
                virtual recivedMessage *recvMsg()=0;
                //Die nachricht wird nicht blockierend gesendet und die verantwortung für m liebt bei der Connection
                virtual void sendMsg(sendMessage *m)=0;

                virtual bool alive()=0;

                virtual void kill()=0;
        };

        recivedMessage *copyRecivedMessage(recivedMessage *r);


        typedef bool (*recivedMessageClassifier)(recivedMessage*,signal*);



        typedef callback_registration<void *,recivedMessage*> netwokMsgCallback;

        class ManagedConnection{
            public:
                ManagedConnection(Connection *con);
                ~ManagedConnection();

                void sendMsg(sendMessage *m);
                void addClassifier(recivedMessageClassifier c);
                void addCallback(signal s,netwokMsgCallback *calback);
                void kill();
                bool alive();

            private:


                thread *senderThread;
                static void sender(Connection *con,Ringbuffer<sendMessage *> *outBuffer);

                thread *reciverThread;
                static void reciver(Connection *con,Callback<void *,recivedMessage *> *callbackHandler,LinkedList<recivedMessageClassifier> *classifiers);

                Connection *con;
                Ringbuffer<sendMessage*> *outBuffer;
                Callback<void *,recivedMessage *> *callbackHandler;
                LinkedList<recivedMessageClassifier> *classifiers;
        };


    };
};


#endif
