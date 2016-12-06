/** @file main.cpp
 *  @brief Startsup the Timux System.
 *  @author Lukas Lühr (hexagon2206)
 *  @bug No known bugs.
 */
//define UDP_BC


 #include <iostream>
#include "callback.hpp"
#include "ringBuffer.hpp"
#ifdef UDP_BC
    #include "udp.hpp"
#else
    #include "udpTest.hpp"
#endif
#include <chrono>
#include <thread>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <time.h>

#include <mutex>
#include "timux.hpp"

#include "DataBuffer.hpp"

using namespace std;
using namespace chrono;
using namespace llu::callback;
using namespace llu::network;





using namespace timux;

int main(int argc,char **args){


    srand(duration_cast< nanoseconds >(system_clock::now().time_since_epoch()).count());

    char *interfaceName = nullptr;
    char *mcastAddress  = nullptr;
    char *receivePort   = nullptr;
    int port;
    char *stationClass  = nullptr;

    for(int i =1;i<argc;i++){
        cout << args[i] <<endl;
        switch(*args[i]){
            case 'i':
                interfaceName = args[i]+1;
                break;
            case 'a':
                mcastAddress = args[i]+1;
                break;
            case 'p':
                receivePort = args[i]+1;
                break;
            case 'c':
                stationClass = args[i]+1;
                break;
        }
    }

    if(nullptr==mcastAddress || nullptr == receivePort || nullptr==stationClass){
        cout << "Not Enough parameters" << endl;
        return 1;
    }
    port = atoi(receivePort);

    cout << "hallo Welt ?  " << endl;

    llu::network::Connection *con;
    #ifdef UDP_BC
        con = new llu::network::UdpConnection(mcastAddress,port);
    #else
        con = new llu::network::UdpTestConnection();
    #endif


    ManagedConnection mcon(con);

    sockaddr_in target = resolve(mcastAddress,port);
    #ifndef UDP_BC
        mcon.sendMsg(createSendMessage(7,target,"bububa"));
    #endif

    llu::datastructs::DataBuffer<timux::data> db(&cin);
    timux::timux timuxMain(&mcon,1000,25,target,*stationClass,&db);




    //TODO: Buffer schreiben
    timuxMain.loop();
    return 0;
}


