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

    Connection *con = new llu::network::UdpConnection();
    ManagedConnection mcon(con);

    sockaddr_in target = resolve("127.0.0.1",6001);


    timux::timux timuxMain(&mcon,1000,25,target);

    timuxMain.loop();

    cout << "lebe noch ";

    char text[128];
    sendMessage *msg;
    while(true){
        cin >> text;
        msg = createSendMessage(128,target,text);
        mcon.sendMsg(msg);
    }
    return 0;
}


