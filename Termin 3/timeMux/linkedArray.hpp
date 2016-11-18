#ifndef __LLU_LINKEDARRAY_HPP__
#define __LLU_LINKEDARRAY_HPP__
#include <stdlib.h>
#include <mutex>

namespace llu{
   namespace datastructs{

        template<typename E>
        struct listArrayEntrie{
            struct listArrayEntrie *next;
            unsigned int index;
            E data;
        };

        template <typename E> class LinkedListArray{
            public:
                LinkedListArray(){
                    this->start = {NULL,0,(E)NULL};
                }
                LinkedListArray(E defaultValue){
                    this->start = {NULL,0,defaultValue};
                }


                std::mutex lock;
                listArrayEntrie<E> start;

                int put(unsigned int index,E data){
                    this->lock.lock();

                    index=index+1;
                    listArrayEntrie<E> *ptr = &(this->start);
                    while(ptr->next && ptr->index < index){
                        ptr = ptr->next;
                    }
                    int toret=1;
                    if(ptr->index == index){
                        toret=0;
                    }else{
                        listArrayEntrie<E> *tmp = (listArrayEntrie<E> *)malloc(sizeof(listArrayEntrie<E>));

                        *tmp={ptr->next,index,data};

                        /*tmp->next  = ptr->next;
                        tmp->index =  index;
                        tmp->data  = data;*/

                        ptr->next  = tmp;
                    }
                    this->lock.unlock();
                    return toret;
                }

                E get(unsigned int index){
                    index=index+1;

                    this->lock.lock();
                    listArrayEntrie<E> *ptr = &(this->start);
                    while(ptr->next && ptr->index < index){
                        ptr = ptr->next;
                    }

                    E toret;
                    if(!ptr || ptr->index != index){
                        toret = this->start.data;
                    }else{
                        toret=ptr->data;
                    }
                    this->lock.unlock();
                    return toret;
                }
        };
    };
};
#endif
