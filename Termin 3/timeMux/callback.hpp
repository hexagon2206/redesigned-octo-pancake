#ifndef __LLU_CALLBACK_HPP__
#define __LLU_CALLBACK_HPP__
#include <stdlib.h>
#include <thread>
#include <mutex>
#include "linkedList.hpp"
#include "linkedArray.hpp"

namespace llu{
    namespace callback{

        using namespace llu::datastructs;

        typedef unsigned int signal;


        template<typename C,typename D>
        class callback_registration {
            public :
                void (*fnc)(C,D);
                C data;
        };


        template <typename C,typename D>
        class Callback{
            public :
                Callback(){
                }
                void registerCallback(signal s,callback_registration<C,D> *c){
                    LinkedList<callback_registration<C,D>*> *tmp = this->registrations.get(s);
                    if(!tmp){
                        tmp = new LinkedList<callback_registration<C,D>*>();
                        if(0 == this->registrations.put(s,tmp)){
                            delete tmp;
                            tmp = this->registrations.get(s);
                        }
                    }
                    tmp->append(c);
                }


                void signal(signal s,D d ){
                    LinkedList<callback_registration<C,D>*> *tmp = this->registrations.get(s);
                    if(!tmp) return;
                    tmp->lock.lock();

                    listEntrie<callback_registration<C,D>*> *elem = &tmp->start;

                    while(elem->next){
                        elem=elem->next;
                        callback_registration<C,D>*  cbr=elem->data;
                        std::thread(cbr->fnc,cbr->data,d).detach();
                    }

                    tmp->lock.unlock();
                }

            private:

                LinkedListArray< LinkedList< callback_registration<C,D>* >* > registrations;
        };
    };
};

#endif
