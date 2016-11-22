#include "network.hpp"


namespace llu{
    namespace network{


        sockaddr_in resolve(const char*ip,uint16_t port){
            sockaddr_in remoteServAddr;
            remoteServAddr.sin_family = AF_INET;
            remoteServAddr.sin_port = htons (port);
            inet_aton(ip,&remoteServAddr.sin_addr);
            return remoteServAddr;
        }

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


        sendMessage *createSendMessage(size_t bufferSize,sockaddr_in target,const void *from){
            sendMessage *m = (sendMessage *)malloc(sizeof(sendMessage)+sizeof(char)*bufferSize);
            m->length   = bufferSize;
            m->target   = target;
            m->data     = (void*)(m+1);
            memcpy(m->data,from,bufferSize);
            return m;
        }

        void destorySendMessage(sendMessage *m){
            free(m);
        }

        recivedMessage *copyRecivedMessage(recivedMessage *r){
            size_t gesSize=sizeof(recivedMessage );
            gesSize += r->length;
            recivedMessage *toret=(recivedMessage *)malloc(gesSize);
            memcpy(toret,r,gesSize);
            return toret;
        }


        ManagedConnection::ManagedConnection(Connection *con){
            this->con = con;
            this->classifiers = new LinkedList<recivedMessageClassifier>();
            this->outBuffer = new Ringbuffer<sendMessage *>(128);
            this->callbackHandler = new Callback<void *,recivedMessage *> (&copyRecivedMessage);
            this->reciverThread = new thread(reciver,con,this->callbackHandler,this->classifiers);
            this->senderThread  = new thread(sender,con,outBuffer);
        }


        ManagedConnection::~ManagedConnection(){


            delete this->reciverThread;
            delete this->senderThread;

            this->con->kill();
            delete this->con;

            delete this->classifiers;
            delete this->outBuffer;
            delete this->callbackHandler;
        }

        void ManagedConnection::sendMsg(sendMessage *m){
            this->outBuffer->put(m);
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


        void ManagedConnection::sender(Connection *con,Ringbuffer<sendMessage*> *outBuffer){
            while(true){
                sendMessage * m = outBuffer->get();
                con->sendMsg(m);
            }
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
                destoryRecivedMessage(msg);
            }
        }


    };
};
