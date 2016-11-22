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



bool socketaddrCompare(sockaddr_in A,sockaddr_in B){
    return A.sin_port == B.sin_port && A.sin_addr.s_addr == B.sin_addr.s_addr;
}
LinkedList<sockaddr_in> clientList;
mutex listLock;

void BCHandler(void *c,recivedMessage *m){
    ManagedConnection *mcon = (ManagedConnection*)c;

    listLock.lock();
    if(!clientList.contains(&socketaddrCompare,m->sender)){
        clientList.append(m->sender);
    }
    clientList.lock.lock();

    listEntrie<sockaddr_in> *client = &clientList.start;
    while(client->next){
        client= client->next;
        cout << "response to :" << inet_ntoa(client->data.sin_addr) << ":"<<ntohs(client->data.sin_port) << endl;
        sendMessage *out = createSendMessage(m->dataLength,client->data,m->data);
        mcon->sendMsg(out);
    }
    clientList.lock.unlock();
    listLock.unlock();
    destoryRecivedMessage(m);
}


int main(){
    cout << "Broadcast Server . . . " << endl;
    Connection *con = new llu::network::UdpConnection(1,6001);
    ManagedConnection mcon(con);

    netwokMsgCallback printCallback = {&PrintHandler,NULL};
    netwokMsgCallback bcCallback = {&BCHandler,(void*)&mcon};


    mcon.addClassifier(&PrintMatcher);
    mcon.addCallback(ECHO_SIGNAL,&printCallback);
    mcon.addCallback(ECHO_SIGNAL,&bcCallback);

    while(true){
        std::this_thread::sleep_for(std::chrono::seconds(1));
    }
    return 0;
}

