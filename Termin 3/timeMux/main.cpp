#include <iostream>
#include "callback.hpp"
#include "ringBuffer.hpp"
#include "udp.hpp"
#include <chrono>
#include <thread>
#include <netinet/in.h>
#include <arpa/inet.h>

#include <mutex>
#include "timux.hpp"

using namespace std;
using namespace llu::callback;
using namespace llu::network;





using namespace timux;

int main(){
    cout << "hallo Welt ?  " << endl;
    Connection *con = new llu::network::UdpConnection();
    ManagedConnection mcon(con);

    sockaddr_in target = resolve("127.0.0.1",6001);




    char text[128];
    sendMessage *msg;
    while(true){
        cin >> text;
        msg = createSendMessage(128,target,text);
        mcon.sendMsg(msg);
    }
    return 0;
}

