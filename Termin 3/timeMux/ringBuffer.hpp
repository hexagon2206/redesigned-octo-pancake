/** @file ringBuffer.hpp
 *  @brief Impelemnts a generik Ging buffer.
 *  @author Lukas Lühr (hexagon2206)
 *  @bug No known bugs.
 */

#ifndef __LLU_RINGBUFFER_HPP__
#define __LLU_RINGBUFFER_HPP__
#include <stdlib.h>
#include <condition_variable>
#include <thread>
#include <mutex>

namespace llu{
   namespace datastructs{

        /**
         * @brief Basic implementation of a generik and thread save Ring buffer
         *
         * D is the type of data the buffer accepts
         */
        template <typename D>
        class Ringbuffer{
            public:
                /**
                 * @brief creates a Ringbuffer of spezified size
                 *
                 * @param mySize number of D to be put into the buffer
                 */
                Ringbuffer(size_t mySize){
                    data = (D*)malloc (sizeof(D)*mySize);
                    this->mySize=mySize;

                    writePos = readPos = 0;

                }
                ~Ringbuffer(){
                    free(data);
                }
                /**
                 * @brief Used to check if space for data is available to
                 * @return True if it is possible to write data, may be not corect, wen used without lock
                 */
                bool canWrite(){
                    return ((writePos+1)%mySize)!=readPos ;
                }


                /**
                 * @brief Used to check if data is available to be read
                 * @return True if it is possible to read data, may be not corect, wen used without lock
                 */
                bool canRead(){
                    return writePos!=readPos ;
                }


                /**
                 * @brief tryes to append D data if there is space in the Ring
                 * @param data the data to put in the ring
                 * @return true if it was possible, otherwise false
                 */
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

                /**
                 * @brief Putes D data to the ring, blocks till done
                 * @param data the data to put in the ring
                 */
                void put(D data){
                    std::unique_lock<std::mutex> lk(writeCondition_m);
                    while(!canWrite()){writeCondition.wait(lk);}

                    this->data[writePos] = data;
                    writePos=(writePos+1)%mySize;

                    readCondition.notify_one();
                }


                /**
                 * @brief reads data form the buffer, blocks till done
                 * @return data from the ring
                 */
                D get(){
                    std::unique_lock<std::mutex> lk(readCondition_m);
                    while(!canRead()){readCondition.wait(lk);}

                    D toret = data[readPos];
                    readPos=(readPos+1)%mySize;

                    writeCondition.notify_one();
                    return toret;
                }


            private :
                D *data;
                size_t mySize;
                size_t readPos;
                size_t writePos;

                std::mutex readCondition_m;
                std::condition_variable readCondition;

                std::mutex writeCondition_m;
                std::condition_variable writeCondition;

        };

    };
};

#endif
