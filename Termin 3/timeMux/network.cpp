/** @file network.cpp
 *  @brief Implementation of al general network stuff.
 *  @author Lukas Lühr (hexagon2206)
 *  @bug No known bugs.
 */

 #include "network.hpp"


namespace llu{
    namespace network{

            void toNBO(uint8_t value,uint8_t* target){
            *target=value;
        }
        uint8_t toHBO_8(uint8_t *from){
            return *from;
        }

        void toNBO(uint16_t value,uint8_t* target){
            *(target+1)=(uint8_t)value;
            *(target)=(uint8_t)(value>>8);
        }
        uint16_t toHBO_16(uint8_t *from){
            return ((uint16_t)*(from))<<8|*(from+1);
        }

        void toNBO(uint32_t value,uint8_t* target){
            *(target+3)=(uint8_t)value;
            *(target+3)=(uint8_t)(value>>8);
            *(target+1)=(uint8_t)(value>>16);
            *(target  )=(uint8_t)(value>>24);
        }
        uint32_t toHBO_32(uint8_t *from){
            return  ((uint32_t)*(from+3))     |
                    ((uint32_t)*(from+2))<<8  |
                    ((uint32_t)*(from+1))<<16 |
                    ((uint32_t)*(from  ))<<24 ;
        }

        void toNBO(uint64_t value,uint8_t* target){
            *(target+7)=(uint8_t)value;
            *(target+6)=(uint8_t)(value>> 8);
            *(target+5)=(uint8_t)(value>>16);
            *(target+4)=(uint8_t)(value>>24);
            *(target+3)=(uint8_t)(value>>32);
            *(target+2)=(uint8_t)(value>>40);
            *(target+1)=(uint8_t)(value>>48);
            *(target  )=(uint8_t)(value>>56);
        }
        uint64_t toHBO_64(uint8_t *from){
            return  ((uint64_t)*(from+7))        |
                    ((uint64_t)*(from+6))<< 8 |
                    ((uint64_t)*(from+5))<<16 |
                    ((uint64_t)*(from+4))<<24 |
                    ((uint64_t)*(from+3))<<32 |
                    ((uint64_t)*(from+2))<<40 |
                    ((uint64_t)*(from+1))<<48 |
                    ((uint64_t)*(from  ))<<56 ;
        }

        /*void toNBO(uint8_t value,uint8_t* target){
            *target=value;
        }
        uint8_t toHBO_8(uint8_t *from){
            return *from;
        }

        void toNBO(uint16_t value,uint8_t* target){
            *target=(uint8_t)value;
            *(target+1)=(uint8_t)(value>>8);
        }
        uint16_t toHBO_16(uint8_t *from){
            return ((uint16_t)*(from+1))<<8|*(from);
        }

        void toNBO(uint32_t value,uint8_t* target){
            *target=(uint8_t)value;
            *(target+1)=(uint8_t)(value>>8);
            *(target+2)=(uint8_t)(value>>16);
            *(target+3)=(uint8_t)(value>>24);
        }
        uint32_t toHBO_32(uint8_t *from){
            return  ((uint32_t)*from)         |
                    ((uint32_t)*(from+1))<<8  |
                    ((uint32_t)*(from+2))<<16 |
                    ((uint32_t)*(from+3))<<24 ;
        }

        void toNBO(uint64_t value,uint8_t* target){
            *target=(uint8_t)value;
            *(target+1)=(uint8_t)(value>> 8);
            *(target+2)=(uint8_t)(value>>16);
            *(target+3)=(uint8_t)(value>>24);
            *(target+4)=(uint8_t)(value>>32);
            *(target+5)=(uint8_t)(value>>40);
            *(target+6)=(uint8_t)(value>>48);
            *(target+7)=(uint8_t)(value>>56);
        }
        uint64_t toHBO_64(uint8_t *from){
            return  ((uint64_t)*from)        |
                    ((uint64_t)*(from+1))<< 8 |
                    ((uint64_t)*(from+2))<<16 |
                    ((uint64_t)*(from+3))<<24 |
                    ((uint64_t)*(from+4))<<32 |
                    ((uint64_t)*(from+5))<<40 |
                    ((uint64_t)*(from+6))<<48 |
                    ((uint64_t)*(from+7))<<56 ;
        }*/

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


        void ManagedConnection::lockWrite(){
            this->outBuffer->lock();
        }

        void ManagedConnection::unlockWrite(){
            this->outBuffer->unlock();
        }


        void ManagedConnection::sender(Connection *con,Ringbuffer<sendMessage*> *outBuffer){
            while(true){
                sendMessage * m = outBuffer->get();
                con->sendMsg(m);
            }
        }

        Connection *ManagedConnection::raw(){
            return con;
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


    }
}
