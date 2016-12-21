/** @file callback.hpp
 *  @brief Prototypes for a Callback Handler.
 *  @author Lukas Lühr (hexagon2206)
 *  @bug No known bugs.
 */

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

        /**
         * singal is the type, which can be used to signal an event in the Callback class
         */
        typedef unsigned int signal;

        /**
         * @brief Calback registration, containing functon and
         *
         * This class can be used for callback registration in an Callback class
         * the C is the context of the function fnc, it will be the first parameter wen caled from Callback
         * D is the sort of daten wich could be pased from a signal
         */
        template<typename C,typename D>
        class callback_registration {
            public :
                void (*fnc)(C,D);   /**< @brief The pointer which will be caled if registered
                                      *
                                      * must acept an C at first place and data D at the second, twill be called form context in an own thread
                                      * should not implement a hole bunch of functionality.
                                      */

                C data;             /**< @brief The context of the callback, will be given to the fnc
                                      *
                                      * This will be given to the function fnc everytime it is caled from the Callback handler Class.
                                      * it could be used to give the fnc a Object of some sort.
                                      * @note will not be thread save
                                      */
        };

        /**
         * @brief Calback manager class
         *
         * This class can be used for callbackmanagement, it impelemtnts functionality to use in a observer pattern
         * the C is the context of a callback_registration usuali a void*
         * D is the Data which must be given wen signaling listeners
         */
        template <typename C,typename D>
        class Callback{
            public :
                /**
                 * @brief Creates a new callback handler
                 *
                 * initialiese  the callback handler.
                 * @param copyFun a funktion to copy an D will be stored in this->copyFun
                 */
                Callback(D(*copyFun)(D)){
                    this->copyFun=copyFun;
                }

                /**
                 * @brief registers the given callback c for a signal s

                 * @param s the signal on which the callback should be called
                 * @param c a pointer to the compelte callback conext the responesbiliety for c is by the caller, if this class will be deletet, all registrations will continue to exist
                 * @note the context c could be changed wile it is registerd
                 */
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

                /**
                 * @brief Send a signal, it will automaticly call all registerd hanbdlers in a new threads
                 *
                 *
                 * @param s the signal to send
                 * @param d the Data to send to the Listeners, a coppy of D is given for each thread, the handler is responsable for the copy the caller for the original
                 */

                void signal(signal s,D d ){
                    LinkedList<callback_registration<C,D>*> *tmp = this->registrations.get(s);
                    if(!tmp) return;
                    tmp->lock.lock();

                    listEntrie<callback_registration<C,D>*> *elem = &tmp->start;
                    while(elem->next){
                        elem=elem->next;
                        callback_registration<C,D>*  cbr=elem->data;
                        std::thread(cbr->fnc,cbr->data,copyFun(d)).detach();
                        //t->detach();
                    }
                    tmp->lock.unlock();
                }

            private:
                /**
                  * @brief A function pointer to a function which copies an D
                  *
                  * Each listener in the event of a callback onely becomes a copy of the original data,
                  * therefor we must know how to copy D
                  */
                D(*copyFun)(D);

                /**
                 * @brief contains an linked list onely for the indexes on which a calback_context is registerd, the linked list contains all the registrations
                 */
                LinkedListArray< LinkedList< callback_registration<C,D>* >* > registrations;
        };
    }
}

#endif
