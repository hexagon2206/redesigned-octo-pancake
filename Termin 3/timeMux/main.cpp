#include <iostream>
#include "callback.hpp"
#include "ringBuffer.hpp"
#include "udp.hpp"
#include <chrono>
#include <thread>
#include <netinet/in.h>
#include <arpa/inet.h>

#include <mutex>

using namespace std;
using namespace llu::callback;
using namespace llu::network;


#define ECHO_SIGNAL (1)
bool PrintMatcher(recivedMessage* m,signal* s){
    *s=ECHO_SIGNAL;
    return true;
}

mutex screenLock;
void PrintHandler(void *c,recivedMessage *m){
    screenLock.lock();
    char *p = ((char*)m->data);
    p[m->dataLength-1]=0x0;
    cout << inet_ntoa(m->sender.sin_addr) << ":"<<ntohs(m->sender.sin_port) << " > " << p << endl;
    screenLock.unlock();
    destoryRecivedMessage(m);
}


namespace timux{
    class package{
        uint8_t klasse[1];
        uint8_t data[24];
        uint8_t nextSlot[1];
        uint8_t time[8];
    }__attribute__((packed));

};


int main(){
    cout << "hallo Welt ?  " << endl;
    Connection *con = new llu::network::UdpConnection();
    ManagedConnection mcon(con);

    netwokMsgCallback printCallback = {&PrintHandler,NULL};


    mcon.addClassifier(&PrintMatcher);
    mcon.addCallback(ECHO_SIGNAL,&printCallback);

    char text[128];
    sendMessage *msg;
    sockaddr_in target = resolve("127.0.0.1",6001);
    while(true){
        cin >> text;
        msg = createSendMessage(128,target,text);
        mcon.sendMsg(msg);
    }
    return 0;
}

