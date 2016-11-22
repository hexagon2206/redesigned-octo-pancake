#ifndef __LLU_COLLECTIONS_H__
#define __LLU_COLLECTIONS_H__
namespace llu{
    namespace datastructs{
        template<typename E> class Interator{
            public:
                virtual bool next() = 0 ;
                virtual bool hasNext()  = 0 ;
                virtual E data()  = 0 ;
                virtual void close()  = 0 ;
        };
        template<typename E> class Interatable{
            public:
                virtual Interator<E> *iterate()  = 0 ;
        };

    };
};


#endif
