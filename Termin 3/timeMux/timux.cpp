/** @file timux.cpp
 *  @brief Implementation of The TIMUX logic.
 *  @author Lukas Lühr (hexagon2206)
 *  @bug No known bugs.
 *  @todo remove screen output
 *  @todo
 */

#include "timux.hpp"
#include <iostream>


#define DEBUG(X)
using namespace llu::callback;
using namespace llu::network;
using namespace std::chrono;

namespace timux{

    bool TimeSynchronizeSignal(recivedMessage* m,signal* s){
        if(sizeof(package) != m->dataLength ) return false;
        if('A' != ((package * )m->data)->klasse[0]) return false;

        *s=TIMUX_TimeSignal;
        return true;
    }

    void timing::synchronize(package *p){
        unsigned long n = this->now();
        this->lock.lock();
        unsigned long o = toHBO_64(p->time);
        this->timeOffset = 0;//(this->timeOffset+(n-o))/2;
        this->lock.unlock();
    }

    unsigned long timing::now(){
        long ofset=getOffset();
        milliseconds ms = duration_cast< milliseconds >(system_clock::now().time_since_epoch());
        return ms.count()+ofset;
    }

    long timing::getOffset(){
        this->lock.lock();
        long offset =this->timeOffset;
        this->lock.unlock();
        return offset;
    }
    timing::timing(llu::network::ManagedConnection *con,long offset){
        timeOffset=offset;
        con->addClassifier(&TimeSynchronizeSignal);

        this->timeSynchronizeCalback.data = (void* )this;
        this->timeSynchronizeCalback.fnc  = &TimeSynchronizeHandler;

        con->addCallback(TIMUX_TimeSignal,&timeSynchronizeCalback);

    }


    void TimeSynchronizeHandler(void* timingClass,llu::network::recivedMessage* m){
        timing *t = (timing *)timingClass;
        t->synchronize((package *)m->data);
        destoryRecivedMessage(m);
    }

    timux::timux(llu::network::ManagedConnection *con,unsigned long frameLength,unsigned long slotCount,sockaddr_in target):t(con){
        this->frameLength = frameLength;
        this->slotCount = slotCount;

        con->addClassifier(&MsgSignal);

        this->MsgCalback.data = (void* )this;
        this->MsgCalback.fnc  = &MsgHandler;

        this->con = con;
        this->con->lockWrite();

        this->target = target;

        setupNextFrame();
        con->addCallback(TIMUX_SotSignal,&MsgCalback);
     }
     void timux::setupNextFrame(){
        nextSlotLock.lock();
        this->freeNextSlot = (bool *)malloc(sizeof(bool)*this->slotCount);
        memset(freeNextSlot,0,sizeof(bool)*this->slotCount);
        this->collisions = (int *)malloc(sizeof(int)*this->slotCount);
        memset(collisions,0,sizeof(int)*this->slotCount);
        nextSlotLock.unlock();
     }

    void timux::recived(msg *m){
        if(m->frame!=this->curentFrame){
            std::cout << "Wrong Frame MyFrame:" << this->curentFrame << " recived:" <<m->frame << std::endl;
            return ;
        }
        nextSlotLock.lock();
        this->freeNextSlot[m->nextSlot]=true;
        collisions[m->slot]++;
        nextSlotLock.unlock();
    }

    package *timux::build(){
        package *p=(package *)malloc(sizeof(package));
        toNBO(this->stationClass,p->klasse);
        toNBO((uint8_t)this->mySlot, p->nextSlot);

        if(this->stationClass == 'B'){
            this->stationClass = 'A';
        }else{
            this->stationClass = 'B';
        }

        this->sendDataLock.lock();
        if(this->sendData){
            memcpy(p->data,this->sendData,sizeof(p->data));
        }else{
            memcpy(p->data,this->dummyData,sizeof(p->data));
        }
        this->sendDataLock.unlock();
        return p;
    }
    void timux::send(package *p){
        this->con->raw()->sendMsg(createSendMessage(sizeof(package),this->target,p));
        free(p);
    }

    void timux::loop(){
        unsigned long now = this->t.now();
        unsigned long curentFrame = now/this->frameLength;
        this->curentFrame = curentFrame;
        while(this->curentFrame == curentFrame){            //Wait for the start of a new frame
            now = this->t.now();
            curentFrame = now/this->frameLength;
        }

        bool *nextFree=this->freeNextSlot;
        int *collisions = this->collisions;
        this->curentFrame = curentFrame;
        setupNextFrame();                               //Clear the trash data
        free(nextFree);
        free(collisions);

        while(true){
            now = this->t.now();
            curentFrame = now/this->frameLength;
            if( curentFrame > this->curentFrame){
                nextFree=this->freeNextSlot;
                collisions = this->collisions;
                this->curentFrame = curentFrame;
                setupNextFrame();

                DEBUG(std::cout << "frame Übergang : " << now << std::endl;)
                if(-1==this->mySlot){
                    if(0==rand()%TIMUX_TRYTOJOIN){
                        std::cout << "ttj" <<std::endl;
                        for(unsigned int i = 0;i!=this->slotCount;i++){
                            if(false==nextFree[i]){
                                if(0==(rand()%TIMUX_TRY_TAKE_SLOT)){
                                    this->mySlot=i;
                                    DEBUG(std::cout << "mySlot ist :"<<this->mySlot<<std::endl;)
                                    break;
                                }
                            }
                        }
                    }
                }else{
                    if((this->lastSendIn != curentFrame-1) || (1!=collisions[this->mySlot])){
                        this->mySlot=-1;
                    }
                }
                free(nextFree);
                free(collisions);

                DEBUG(std::cout << "took : " << (this->t.now()-now) << std::endl;)
            }else if(-1!=this->mySlot){
                unsigned int slot = (now%this->frameLength)/(this->frameLength/this->slotCount);
                if(this->lastSendIn < curentFrame && (unsigned int)this->mySlot == slot){
                    this->lastSendIn=curentFrame;
                    package *p=build();
                    unsigned long sendAt = this->frameLength*curentFrame + (mySlot*2+1)*(this->frameLength/this->slotCount/2);

                    while(sendAt > (now=this->t.now())){}//Wait till middle of the slot

                    toNBO((uint64_t)now,p->time);
                    send(p);
                    std::cout<<"sending slot :"<<mySlot<<" at: " << this->t.now()<<endl;
                }
            }
            std::this_thread::sleep_for(std::chrono::microseconds(1));
        }

    }

    bool MsgSignal(llu::network::recivedMessage* m,llu::callback::signal* s){
        if(sizeof(package) != m->dataLength ) return false;
        *s=TIMUX_SotSignal;
        return true;
    }

    void MsgHandler(void* timuxClass,llu::network::recivedMessage* m){
        timux * ti = (timux*)timuxClass;


        msg *toret = (msg*)malloc(sizeof(msg));

        package *p= (package *)m->data;
        unsigned long timestamp = toHBO_64(p->time);

        toret->frame= timestamp / ti->frameLength;
        toret->slot = (int)((timestamp%ti->frameLength)/(ti->frameLength/ti->slotCount));
        toret->nextSlot = toHBO_8(p->nextSlot);
        memcpy(toret->data,p->data,sizeof(toret->data));
        ti->recived(toret);
        std::cout << "Recived MSG F:" << toret->frame << "Slot : "<<  toret->slot << std::endl << toret->data << std::endl << std::endl;

        llu::network::destoryRecivedMessage(m);
    }
};
