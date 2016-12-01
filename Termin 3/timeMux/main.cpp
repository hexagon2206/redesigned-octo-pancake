/** @file main.cpp
 *  @brief Startsup the Timux System.
 *  @author Lukas Lühr (hexagon2206)
 *  @bug No known bugs.
 */

 #include <iostream>
#include "callback.hpp"
#include "ringBuffer.hpp"
#include "udp.hpp"
#include <chrono>
#include <thread>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <time.h>

#include <mutex>
#include "timux.hpp"

using namespace std;
using namespace llu::callback;
using namespace llu::network;





using namespace timux;

int main(){
    srand(time(NULL));
    cout << "hallo Welt ?  " << endl;

    llu::network::UdpConnection *con = new llu::network::UdpConnection("225.10.1.2");
    ManagedConnection mcon(con);

    sockaddr_in target = resolve("225.10.1.2",15002);

    mcon.sendMsg(createSendMessage(7,target,"bububa"));

    timux::timux timuxMain(&mcon,1000,25,target);

    timuxMain.loop();

    cout << "lebe noch ";
/*
    char *text=(char *)malloc(sizeof(msg::data));
    sendMessage *msg;
    while(true){
        cin.read(text,sizeof(msg::data));
        cout << text << endl;
    }*/
    return 0;
}


