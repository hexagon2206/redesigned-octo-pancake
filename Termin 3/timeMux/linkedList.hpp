#ifndef __LLU_LINKEDLIST_HPP__
#define __LLU_LINKEDLIST_HPP__
#include <stdlib.h>
#include <mutex>

namespace llu{
    namespace datastructs{

        template<typename E> struct listEntrie{
            struct listEntrie *next;
            E data;
        };

        //very spartanic implementation of a Linked list, which can be used threadsave
        template<typename E> class LinkedList{
            public:

                LinkedList(){
                }

                listEntrie<E> start;

                std::mutex lock;


                LinkedList(E defaultValue);

                void append(E data){
                    this->lock.lock();

                    listEntrie<E> *ptr = &(this->start);

                    while(ptr->next){
                        ptr = ptr->next;
                    }

                    listEntrie<E> *tmp = (listEntrie<E> *)malloc(sizeof(listEntrie<E>));

                    *tmp={NULL,data};

                    ptr->next  = tmp;

                    this->lock.unlock();
                }
        };

    };
};
#endif
