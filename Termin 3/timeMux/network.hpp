

namespace llu{
    namespace network{

        struct recivedMessage{
            size_t length;
            size_t dataLength;
            sockaddr_in sender;
            void *data;
        }

        struct sendMessage{
            size_t length;
            const void *data;
        }

        recivedMessage *createRecivedMessage(size_t bufferSize);

        sendMessage *createSendMessage(size_t bufferSize);


        class Connection{
            //Es wird blockierend empfangen und die verantwortung für m liegt bei dem aufrufer
            virtual recivedMessage *recv()=0;
            //Die nachricht wird nicht blockierend gesendet und die verantwortung für m liebt bei der Connection
            virtual send(sendMessage *m)=0;
        }

    };
};
