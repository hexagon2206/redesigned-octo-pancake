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

        //This class can be used for callback registration in an Callback
        // the C Data is the context of the function fnc, it will be the first parameter wen caled from Callback
        template<typename C,typename D>
        class callback_registration {
            public :
                void (*fnc)(C,D);
                C data;
        };


        template <typename C,typename D>
        class Callback{
            public :
                //We need to copy the Data we get in signal for each reciver
                D(*copyFun)(D);

                Callback(D(*copyFun)(D)){
                    this->copyFun=copyFun;
                }

                //can be used to register a callboackRegistration for an signal number
                //Zuständigkeit für c liegt bei dem aufruffer
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

                //Send a signal, it will automaticly call all registerd hanbdlers in new threads
                //a coppy of D is given for each thread, the handler is responsable for thr copy
                //the caller for the original
                void signal(signal s,D d ){
                    LinkedList<callback_registration<C,D>*> *tmp = this->registrations.get(s);
                    if(!tmp) return;
                    tmp->lock.lock();

                    listEntrie<callback_registration<C,D>*> *elem = &tmp->start;

                    while(elem->next){
                        elem=elem->next;
                        callback_registration<C,D>*  cbr=elem->data;
                        std::thread(cbr->fnc,cbr->data,copyFun(d)).detach();
                    }

                    tmp->lock.unlock();
                }

            private:
                LinkedListArray< LinkedList< callback_registration<C,D>* >* > registrations;
        };
    };
};

#endif
