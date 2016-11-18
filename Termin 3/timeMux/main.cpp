#include <iostream>
#include "callback.hpp"
#include "ringBuffer.hpp"
#include <chrono>
#include <thread>

using namespace std;
using namespace llu::callback;


typedef callback_registration<int,char*> cbr;

void callbackHandler(int i,char *t){
    cout << i << ":"<<t<<endl;
}

using namespace std::chrono;

int main(){

    Callback<int,char*> cb([](char *A){return A;});
    llu::datastructs::Ringbuffer<int> ringbuf(5);


    cbr callbacks[]={
        {&callbackHandler,1},
        {&callbackHandler,2},
        {&callbackHandler,3},
        {&callbackHandler,4}};

    cb.registerCallback(10,callbacks);
    cb.registerCallback(11,callbacks);
    cb.registerCallback(12,callbacks);
    cb.registerCallback(13,callbacks);
    cb.registerCallback(11,callbacks+1);
    cb.registerCallback(12,callbacks+2);
    cb.registerCallback(13,callbacks+3);

    cb.signal(10,(char *)"zehn");
    cb.signal(11,(char *)"elf");
    cb.signal(12,(char *)"zwoelf");
    cout << "Hello world!" << endl;

    std::this_thread::sleep_for(std::chrono::seconds(20));
    return 0;
}

