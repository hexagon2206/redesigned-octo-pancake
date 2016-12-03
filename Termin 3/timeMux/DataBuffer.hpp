/** @file dataBuffer.hpp
 *  @brief Prototypes for a DataBuffer.
 *  @author Lukas Lühr (hexagon2206)
 *  @bug No known bugs.
 */

#ifndef __LLU_DATABUFFER_H__
#define __LLU_DATABUFFER_H__

#include <iostream>
#include <mutex>
#include <thread>

namespace llu{
   namespace datastructs{

        /**
         * @brief Thread Save Non Blockiung Data Buffer Implementation
         * The buffer always contains the newest D from the given stream
         */
        template <typename D>
        class DataBuffer{

            private:

                D*data = nullptr;

                std::thread *dataGetter;

                std::mutex dataLock;

                std::istream *stream;

                static void dataReader(DataBuffer<D> *db){
                    while(true){
                        D* tmp=(D*)malloc(sizeof(D));
                        db->stream->read((char*)tmp,sizeof(D));

                        db->dataLock.lock();
                        if(nullptr!=db->data)free(db->data);
                        std::cout  << (char*)tmp<<std::endl;
                        db->data=tmp;
                        db->dataLock.unlock();
                    }

                }



            public :
                /**
                 * @brief Creates a Data Buffer that listens on stream
                 * A reader thread is created for reading the stream
                 */
                DataBuffer(std::istream *stream){
                    this->stream = stream;
                    this->dataGetter=new std::thread(dataReader,this);
                }

                /**
                 * @brief destory the reader thread and frees Data that is still available
                 */
                ~DataBuffer(){
                    delete this->dataGetter;
                    if(this->data) free(this->data);
                }

                /**
                 * @brief returns the newest D from the stream, if htere is no new data available it returns null
                 * @note the caler is responsable for the return value
                 */
                D *getData(){
                    D *toret;
                    this->dataLock.lock();
                    toret = this->data;
                    this->data=nullptr;
                    this->dataLock.unlock();
                    return toret;
                }
        };
    }
}

#endif // __LLU_DATABUFFER_H__
