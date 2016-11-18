#include "network.hpp"


namespace llu{
    namespace network{

        recivedMessage *createRecivedMessage(size_t bufferSize){
            recivedMessage *m = (recivedMessage*)malloc(sizeof(recivedMessage)+sizeof(char)*bufferSize);
            m->length       = bufferSize;
            m->dataLength   = 0;
            m->data         = (void*)(m+1);
            return m;
        }
        void destoryRecivedMessage(recivedMessage *m){
            free(m);
        }


        sendMessage *createSendMessage(size_t bufferSize){
            sendMessage *m = (sendMessage *)malloc(sizeof(sendMessage)+sizeof(char)*bufferSize);
            m->length   = bufferSize;
            m->data     = (void*)(m+1);
            return m;
        }

        void destorySendMessage(sendMessage *m){
            free(m);
        }

        recivedMessage *copyRecivedMessage(recivedMessage *r){
            size_t gesSize=sizeof(recivedMessage ) + r->dataLength;
            recivedMessage *toret=(recivedMessage *)malloc(gesSize);
            memcpy(toret,r,gesSize);
            return toret;
        }


        ManagedConnection::ManagedConnection(Connection *con){
            this->con = con;
            this->classifiers = new LinkedList<recivedMessageClassifier>();
            this->outBuffer = new Ringbuffer<sendMessage>(128);
            this->callbackHandler = new Callback<void *,recivedMessage *> (&copyRecivedMessage);
            this->reciverThread = new thread(reciver,con,this->callbackHandler,this->classifiers);
            this->senderThread  = new thread(sender,con,outBuffer);
        }


        ManagedConnection::~ManagedConnection(){
            this->con->kill();
            delete this->con;

            delete this->reciverThread;
            delete this->senderThread;

            delete this->classifiers;
            delete this->outBuffer;
            delete this->callbackHandler;
        }

        void ManagedConnection::sendMsg(sendMessage *m){

        }

        void ManagedConnection::addClassifier(recivedMessageClassifier c){
            this->classifiers->append(c);
        }

        void ManagedConnection::addCallback(signal s,callback_registration<void *,recivedMessage*> *callback){
            this->callbackHandler->registerCallback(s,callback);
        }

        void ManagedConnection::kill(){
            con->kill();
        }

        bool ManagedConnection::alive(){
            return con->alive();
        }


        void ManagedConnection::sender(Connection *con,Ringbuffer<sendMessage> *outBuffer){

        }

        void ManagedConnection::reciver(Connection *con,Callback<void *,recivedMessage *> *callbackHandler,LinkedList<recivedMessageClassifier> *classifiers){
            recivedMessage *msg ;
            signal s=0;

            while(true){
                msg = con->recvMsg();
                classifiers->lock.lock();

                listEntrie<recivedMessageClassifier> *start = &(classifiers->start);
                while(start->next){
                    start = start->next;
                    if(start->data(msg,&s)){
                        callbackHandler->signal(s,msg);
                    }
                }
                classifiers->lock.unlock();
            }
        }


    };
};
