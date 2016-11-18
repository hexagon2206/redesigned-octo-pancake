#ifndef __LLU_RINGBUFFER_HPP__
#define __LLU_RINGBUFFER_HPP__
#include <stdlib.h>
#include <condition_variable>
#include <thread>
#include <mutex>

namespace llu{
   namespace datastructs{


        template <typename D>
        class Ringbuffer{

            private :
                D *data;
                size_t mySize;
                size_t readPos;
                size_t writePos;

                std::mutex readCondition_m;
                std::condition_variable readCondition;

                std::mutex writeCondition_m;
                std::condition_variable writeCondition;

            public:
                Ringbuffer(size_t mySize){
                    data = (D*)malloc (sizeof(D)*mySize);
                    this->mySize=mySize;

                    writePos = readPos = 0;

                }

                bool canWrite(){
                    return ((writePos+1)%mySize)!=readPos ;
                }
                bool canRead(){
                    return writePos!=readPos ;
                }


                bool tryPut(D data){
                    writeCondition_m.lock();

                    if(!canWrite()){
                        writeCondition_m.unlock();
                        return false;
                    }
                    data[writePos] = data;
                    writePos=(writePos+1)%mySize;

                    writeCondition_m.unlock();
                    return true;
                }

                void put(D data){
                    std::unique_lock<std::mutex> lk(writeCondition_m);
                    while(!canWrite()){writeCondition.wait(lk);}

                    this->data[writePos] = data;
                    writePos=(writePos+1)%mySize;

                    readCondition.notify_one();
                }


                D get(){
                    std::unique_lock<std::mutex> lk(readCondition_m);
                    while(!canRead()){readCondition.wait(lk);}

                    D toret = data[readPos];
                    readPos=(readPos+1)%mySize;

                    writeCondition.notify_one();
                    return toret;
                }

        };

    };
};

#endif
