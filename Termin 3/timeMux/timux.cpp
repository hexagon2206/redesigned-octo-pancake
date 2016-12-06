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
        unsigned long n = this->raw();

        unsigned long o = toHBO_64(p->time);
        synchronize(n-o);
    }

    void timing::synchronize(signed long no){
        this->lock.lock();
        this->timeOffset += no;
        this->sampleCount++;
        this->lock.unlock();
    }

    unsigned long timing::now(){
        return raw()+getOffset();
    }

    unsigned long timing::raw(){
        milliseconds ms = duration_cast< milliseconds >(system_clock::now().time_since_epoch());
        return ms.count();
    }

    long timing::getOffset(){
        this->lock.lock();
        long offset =this->timeOffset/this->sampleCount;
        this->lock.unlock();
        return offset;
    }
    timing::timing(llu::network::ManagedConnection *con,long offset){
        timeOffset=offset;
        /*con->addClassifier(&TimeSynchronizeSignal);

        this->timeSynchronizeCalback.data = (void* )this;
        this->timeSynchronizeCalback.fnc  = &TimeSynchronizeHandler;

        con->addCallback(TIMUX_TimeSignal,&timeSynchronizeCalback);
        */
    }


    void TimeSynchronizeHandler(void* timingClass,llu::network::recivedMessage* m){
        timing *t = (timing *)timingClass;
        t->synchronize((package *)m->data);
        destoryRecivedMessage(m);
    }

    timux::timux(llu::network::ManagedConnection *con,unsigned long frameLength,unsigned long slotCount,sockaddr_in target,uint8_t stationClass,llu::datastructs::DataBuffer<data> *dataSource):t(con){
        this->frameLength = frameLength;
        this->slotCount = slotCount;
        this->dataSource = dataSource;
        this->stationClass = stationClass;


        con->addClassifier(&MsgSignal);

        this->MsgCalback.data = (void* )this;
        this->MsgCalback.fnc  = &MsgHandler;

        this->con = con;
        this->con->lockWrite();

        this->target = target;

        setupNextFrame();
        con->addCallback(TIMUX_SotSignal,&MsgCalback);
     }
     llu::datastructs::LinkedListArray<msg*> *timux::setupNextFrame(){
        llu::datastructs::LinkedListArray<msg*> *tmp;
        msgLock.lock();
        tmp = msgForTimeSync;
        msgForTimeSync = new llu::datastructs::LinkedListArray<msg*>();
        msgLock.unlock();
        return tmp;
    }

    void destroyFrameData(llu::datastructs::LinkedListArray<msg*> *frameData){
        frameData->lock.lock();
        listArrayEntrie<msg*> *s=&frameData->start;
        s=s->next;
        while(s){
            free(s->data);
            s=s->next;
        }
        frameData->lock.unlock();
        delete frameData;
    }

    void timux::recived(msg *m){
        if(m->frame!=this->curentFrame){
            std::cout << "Wrong Frame MyFrame:" << this->curentFrame << " recived:" <<m->frame << std::endl;
            free(m);
            return ;
        }
        m->valide= true;
        msgLock.lock();
        int i = 0;
        while(0==this->msgForTimeSync->put(m->rawRecivedTime+i,m)){
            i++;
        }
        msgLock.unlock();
    }


    package *timux::build(){
        package *p=(package *)malloc(sizeof(package));
        toNBO(this->stationClass,p->klasse);
        toNBO((uint8_t)(this->mySlot+1), p->nextSlot);

        this->sendDataLock.lock();
        data *d = this->dataSource->getData();

        if(d){
            if(this->sendData)free(this->sendData);
            this->sendData = (uint8_t*)d;
        }
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

    void timux::frameEnd(llu::datastructs::LinkedListArray<msg*> *frameData){
        freeSlotList sl = removeColisons(frameData);

        DEBUG(std::cout << "frame Übergang : " << now << std::endl;)
        if(-1==this->mySlot && sl.freeSlots!=0){
            if(0==rand()%joinPropability){
                DEBUG(std::cout << "ttj" <<std::endl;)
                int chosen = rand()%sl.freeSlots;
                this->mySlot = sl.data[chosen];
                DEBUG(std::cout << "mySlot ist :"<<this->mySlot<<std::endl;)
            }
        }
        free(sl.data);
        destroyFrameData(frameData);
        DEBUG(std::cout << "took : " << (this->t.now()-now) << std::endl;)
    }



    freeSlotList timux::removeColisons(llu::datastructs::LinkedListArray<msg*> *frameData){
        freeSlotList toret;
        toret.freeSlots = 0;
        toret.data      = (int*)malloc(sizeof(int)*this->slotCount);
        bool *used       = (bool*)malloc(sizeof(bool)*this->slotCount);

        frameData->lock.lock();
        listArrayEntrie<msg*> *s=&frameData->start;

        s=s->next;
        bool msok=false;
        while(s){
            if(s->next && s->data->slot == s->next->data->slot){
                s->data->valide = false;
                s->next->data->valide=false;
            }
            if(s->data->valide){
                if(this->mySlot!=-1 && this->mySlot == s->data->slot){
                    msok = true;
                    std::cout << "mySlotBestätigt"<<std::endl;
                }

                used[s->data->nextSlot]=true;
                if(s->data->klasse=='A'){
                    this->t.synchronize((s->data->rawRecivedTime)-(s->data->sendeTime));
                }
            }
            s=s->next;
        }
        if(!msok){
            this->mySlot=-1;
        }
        frameData->lock.unlock();
        for(unsigned int i = 0 ;i< this->slotCount;i++){
            if(!used[i]){
                toret.data[toret.freeSlots] = i;
                toret.freeSlots++;
            }
        }

        free(used);
        return toret;
    }

    void timux::loop(){
        unsigned long now = this->t.now();
        unsigned long curentFrame = now/this->frameLength;
        this->curentFrame = curentFrame;

        while(this->curentFrame == curentFrame){            //Wait for the start of a new frame
            now = this->t.now();
            curentFrame = now/this->frameLength;
        }

        this->curentFrame = curentFrame;
        destroyFrameData(setupNextFrame());

        while(true){
            now = this->t.now();
            curentFrame = now/this->frameLength;
            if( curentFrame > this->curentFrame){
                this->curentFrame = curentFrame;

                frameEnd(setupNextFrame());


            }else if(-1!=this->mySlot){
                unsigned int slot = (now%this->frameLength)/(this->frameLength/this->slotCount);
                if(this->lastSendIn < curentFrame && (unsigned int)this->mySlot == slot){
                    this->lastSendIn=curentFrame;
                    package *p=build();
                    unsigned long sendAt = this->frameLength*curentFrame + (mySlot*4+1)*(this->frameLength/this->slotCount/4);

                    while(sendAt > (now=this->t.now())){}//Wait till middle of the slot

                    toNBO((uint64_t)now,p->time);
                    send(p);
                    std::cout<<"sending slot :"<<mySlot<<" at: " << now <<endl;
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
        toret->slot = (int)((timestamp%ti->frameLength)/(ti->frameLength/ti->slotCount));
        toret->nextSlot = toHBO_8(p->nextSlot)-1;
        memcpy(toret->data,p->data,sizeof(toret->data));
        toret->sendeTime = timestamp;

        toret->klasse = toHBO_8(p->klasse);

        toret->rawRecivedTime = ti->t.raw();
        ti->recived(toret);

        std::cout << "Recived MSG F:" << toret->frame << "Slot : "<<  toret->slot << std::endl << toret->data << std::endl << std::endl;

        llu::network::destoryRecivedMessage(m);
    }
}
