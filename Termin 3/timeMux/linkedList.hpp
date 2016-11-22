/** @file linkedList.hpp
 *  @brief implements a generik Linked List.
 *  @author Lukas Lühr (hexagon2206)
 *  @bug No known bugs.
 */

#ifndef __LLU_LINKEDLIST_HPP__
#define __LLU_LINKEDLIST_HPP__
#include <stdlib.h>
#include <mutex>

namespace llu{
    namespace datastructs{

        /**
         * @brief an list entry for a linked list of type E
         *
         * Can be used to iterate over an compleate listArray, or to manipolate the data in normaly not supported ways,
         * the list should be locked during this
         */
        template<typename E> struct listEntrie{
            struct listEntrie<E> *next;         /**< @brief Pointer to the next element of the linked list or null */
            E data;                             /**< @brief The data of the element in the list*/
        };

        /**
         * @brief very spartanic implementation of a generik thread save Linked list
         *
         * The type E defines the type of elements to put in the list
         * To get the data from the list it is nessasary to direkly use the listEntrie start
         * The list is single linked
         */

        template<typename E> class LinkedList{
            public:

                /**
                 * @brief creates an empty linked list
                 */
                LinkedList(){
                }
                /**
                 * @brief deletes the linekd list and clears memory
                 * @note the data which is in the list, will not be cleared
                 */
                ~LinkedList(){
                    listEntrie<E> *p =start.next;
                    listEntrie<E> *op;

                    while(p){
                        op = p;
                        p = p->next;
                        free(op);
                    }
                }

                /**
                 * @brief the first element of the linekd list
                 *
                 * it does not contain any user data, and must be used to start the interating of the list.
                 */
                listEntrie<E> start;

                /**
                 * @brief Lock for accessing the linekd list threadsave
                 *
                 * this must be used, wenn iterating manualy over the list
                 */
                std::mutex lock;

                /**
                 * @brief appends data to the end of the list
                 * @param data the data to append to the list
                 */
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

                /**
                 * @brief checks if the given element elem is contaned in the list
                 * @param comparer is used to check if two elements of type E are equal
                 * @param elem the element to check for
                 * @return true if elem is in the list otherwise false
                 */
                bool contains(bool (*comparer)(E,E),E elem){
                    bool toret=false;
                    this->lock.lock();

                    listEntrie<E> *ptr = &(this->start);

                    while(ptr->next){
                        ptr = ptr->next;
                        if(comparer(ptr->data,elem)){
                            toret = true;
                            break;
                        }
                    }
                    this->lock.unlock();
                    return toret;
                }
        };

    };
};
#endif
