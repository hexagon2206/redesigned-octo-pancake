#include "callback.hpp"



namespace llu{
    namespace callback{

/*
        typedef unsigned int signal;
typedef void (*callback_fnc)(CONTEXT,DATA);
typedef struct {
    callback_fnc fnc;
    CONTEXT data;
}callback_registration;
*/

        template <typename CONTEXT,typename DATA>
        void Callback<CONTEXT,DATA>::registerCallback(signal s,callback_registration *c){
            this->registrations.get(s);
        }
/*
                void signal(signal s,DATA d );

            private:
                llu::datastructs::LinkedListArray<llu::datastructs::LinkedList<callback_registration> > registrations;
    ;*/
    };
};
