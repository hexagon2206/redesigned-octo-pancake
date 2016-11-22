/** @file linkedArray.hpp
 *  @brief Prototypes for a Linked Array.
 *  The Linked array implements acces over simulated index in a linked list.
 *  @author Lukas Lühr (hexagon2206)
 *  @bug No known bugs.
 */

#ifndef __LLU_LINKEDARRAY_HPP__
#define __LLU_LINKEDARRAY_HPP__
#include <stdlib.h>
#include <mutex>

namespace llu{
   namespace datastructs{
        /**
         * @brief An entry of an listArray of type E
         *
         * Can be used to iterate over an compleate listArray, or to manipolate the data in normaly not supported ways,
         * the list array should be locked during this
         */
        template<typename E>
        struct listArrayEntrie{
            struct listArrayEntrie *next;   /**< @brief a pointer to the next element in the list, or Null if there ist none*/
            unsigned int index;             /**< @brief the ined of the entry in the compleet artray
                                              *  @note it is importante that the list is sorted
                                              */
            E data;                         /**< @brief the data stored in the cell can be everything of type E*/
        };

        /**
         * @brief Implementation of a simple generik thread save Array
         *
         * internely this class is implemented as a linked List.
         * therefor the differences in the indizes can be enormus, without much memory consumtion,
         * @note compared to a regular array this is very slow, should not be used if a normal array would fit the task
         */
        template <typename E> class LinkedListArray {
            public:
                /**
                 * @brief creates an empty LinkedListArray with the default value ((E)NULL)
                 */
                LinkedListArray(){
                    this->start = {NULL,0,(E)NULL};
                }

                /**
                 * @brief creates an empty LinkedListArray with the spezified default value
                 * @param defaultValue The default value for en empty cell
                 */
                LinkedListArray(E defaultValue){
                    this->start = {NULL,0,defaultValue};
                }

                /**
                 * @brief deletes this objekt, an clears memory
                 * @note the stored data is still preserved, and must be cleared elsewere
                 */
                ~LinkedListArray(){
                    listArrayEntrie<E> *p =start.next;
                    listArrayEntrie<E> *op;

                    while(p){
                        op = p;
                        p = p->next;
                        free(op);
                    }

                }


                /**
                 * @brief lock for the Array.
                 * @note should be used, if accessing the Raw Linked List from outside
                 */
                std::mutex lock;

                /**
                 * @brief the first element of the listArray
                 *
                 * no actual user data is stored here, it is an empty element.
                 * can be used to acces the Raw linked list
                 */
                listArrayEntrie<E> start;

                /**
                 * @brief Puts the element data at position index
                 *
                 * can be used to put an element at a spezific index, if the index was allready taken nothing would happen
                 * @param index the inex in the array
                 * @param data of type E
                 * @return 0 if nothing was done otherwise 1
                 */
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


                /**
                 * @brief returns an element from index
                 *
                 * @param index the index to get the element from
                 * @return the element at index if there is no element at index, it will return the default value
                 */

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
