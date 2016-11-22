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


int main(){
    cout << "hallo Welt ?  " << endl;
    Connection *con = new llu::network::UdpConnection(1,6002);
    ManagedConnection mcon(con);

    netwokMsgCallback printCallback = {&PrintHandler,NULL};

    sendMessage *msg = createSendMessage(128,resolve("127.0.0.1",6001),"test");

    mcon.addClassifier(&PrintMatcher);
    mcon.addCallback(ECHO_SIGNAL,&printCallback);

    mcon.sendMsg(msg);

    while(true){
        std::this_thread::sleep_for(std::chrono::seconds(1));
    }
    return 0;
}

