/** @file timux.cpp
 *  @brief Implementation of The TIMUX logic.
 *  @author Lukas Lühr (hexagon2206)
 *  @bug No known bugs.
 *  @todo remove screen output
 */

#include "timux.hpp"
#include <iostream>


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
        this->timeOffset = (this->timeOffset+(n-o))/2;
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

    timux::timux(llu::network::ManagedConnection *con,unsigned long frameLength,unsigned long slotCount):t(con){
        this->frameLength = frameLength;
        this->slotCount = slotCount;

        con->addClassifier(&MsgSignal);

        this->MsgCalback.data = (void* )this;
        this->MsgCalback.fnc  = &MsgHandler;


        setupNextFrame();
        con->addCallback(TIMUX_SotSignal,&MsgCalback);
     }
     void timux::setupNextFrame(){
        nextSlotLock.lock();
        this->freeNextSlot = (bool *)malloc(sizeof(bool)*this->slotCount);
        this->collisions = (int *)malloc(sizeof(int)*this->slotCount);
        nextSlotLock.unlock();
     }

    void timux::recived(msg *m){
        if(m->frame!=this->curentFrame)return ;
        nextSlotLock.lock();
        this->freeNextSlot[m->nextSlot]=true;
        collisions[m->slot]++;
        nextSlotLock.unlock();
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
                std::cout << "frame Übergang : " << now << std::endl;
                if(-1==this->mySlot){
                    if(0==rand()%TIMUX_TRYTOJOIN){
                        std::cout << "ttj" <<std::endl;
                        for(unsigned int i = 0;i!=this->slotCount;i++){
                            if(false==nextFree[i]){
                                if(0==(rand()%TIMUX_TRY_TAKE_SLOT)){
                                    this->mySlot=i;
                                    std::cout << "mySlot ist :"<<this->mySlot<<std::endl;
                                    break;
                                }
                            }
                        }
                    }
                }else if(1<(collisions[this->mySlot])){
                    this->mySlot=-1;

                }
                free(nextFree);
                free(collisions);

                std::cout << "took : " << (this->t.now()-now) << std::endl;
            }else if(-1!=mySlot){
                unsigned int slot = (now-(this->frameLength * curentFrame))/(this->frameLength/this->slotCount);
                if(this->lastSendIn < curentFrame && (unsigned int)mySlot == slot){
                    this->lastSendIn=curentFrame;
                    std::cout<<"sending slot :"<<mySlot<<" at: " << this->t.now()<<endl;
                    //TODO Build mesaage and send it at half slot
                }

            }
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
        toret->slot = (int)((timestamp - (ti->frameLength * toret->frame))/(ti->frameLength/ti->slotCount));
        toret->nextSlot = toHBO_8(p->nextSlot);
        memcpy(toret->data,p->data,sizeof(toret->data));
        ti->recived(toret);

        llu::network::destoryRecivedMessage(m);
    }
};
