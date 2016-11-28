#include "timux.hpp"


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
        return this->timeOffset;
        this->lock.unlock();
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

        con->addCallback(TIMUX_SotSignal,&MsgCalback);

    }

    void timux::recived(msg *m){

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
        toret->valide=true;

        ti->recived(toret);

        llu::network::destoryRecivedMessage(m);
    }
};
