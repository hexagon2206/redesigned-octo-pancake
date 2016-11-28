#ifndef __TIMUX_H__
#define __TIMUX_H__

#include <stdlib.h>
#include <mutex>

#include "callback.hpp"
#include "network.hpp"


#include <chrono>

#define TIMUX_TimeSignal (1)
#define TIMUX_SotSignal (1)


namespace timux{
    /**
     * @brief a package as recived from the UDP socket can be direkly written to
     */
    struct package{
            uint8_t klasse[1];  /**< @brief the class of the Station (A or B) */
            uint8_t data[24];   /**< @brief the data payload */
            uint8_t nextSlot[1];/**< @brief the next slot, the clint will send on */
            uint8_t time[8];    /**< @brief the time, the data was send on */
    }__attribute__((packed));

    /**
     * @brief more user friendly representation of a package
     * does not containn all data, because it is no longer relevant
     */
    struct msg{
        unsigned int slot;      /**< @brief the slot the package was recived in */
        unsigned long frame;    /**< @brief the frame the package was recived in */
        uint8_t data[sizeof(package::data)]; /**< The unchanged payload */
        uint8_t nextSlot;       /**< @brief the next slot the client is going to use */
        bool valide;            /**< @brief determens if the pacakge is valide */
    };

    /**
     * @brief used for timing and time synchronisation
     * is thread save
     */
    class timing{
            long timeOffset;    /**< @brief stores the offset of this system clock */
            std::mutex lock;    /**< @brief used for synchronisation */
            llu::network::netwokMsgCallback timeSynchronizeCalback; /**< @brief the callback for the A class massages */
        public :
            /**
             * @brief initialsises a timing class, and registers the Callbacks for con
             * @param con the connection to listen on for pacakges of type A
             * @param offset the initials offset of this system clock
             */
            timing(llu::network::ManagedConnection *con,long offset=0);
            /**
             * @brief synchronizes the clock with a given msg
             */
            void synchronize(package *p);

            /**
             * @brief calculates the current time, also uses offset ot this
             */
            unsigned long now();

            /**
             * @brief returnes the offset
             */
            long getOffset();

    };

    class timux{
        private:
            llu::network::netwokMsgCallback MsgCalback;

            msg *hisory[3];

            long curentFrame;

        public:
            timing t;
            unsigned long frameLength;
            unsigned long slotCount;
            void recived(msg *m);
            timux(llu::network::ManagedConnection *con,unsigned long frameLength,unsigned long slotCount);
    };

    /**
     * @brief signals a TIMUX_TimeSignal , if the gven message m is from an A-Station
     * @see recivedMessageClassifier
     */
    bool TimeSynchronizeSignal(llu::network::recivedMessage* m,llu::callback::signal* s);
    /**
     * @brief adjusts the offset of a timing class
     * @param timingClass the timing class, which should be adjusted
     * @param m           the message M which courses the adjustmend
     */
    void TimeSynchronizeHandler(void* timingClass,llu::network::recivedMessage* m);

    /**
     * @brief signals a TIMUX_SotSignal if a message is recived
     * @see recivedMessageClassifier
     */
    bool MsgSignal(llu::network::recivedMessage* m,llu::callback::signal* s);
    /**
     * @brief handels an MSG from the Line
     * @param timuxClass the timux class, which does the logic
     * @param m           the message M which courses the adjustmend
     */
    void MsgHandler(void* timuxClass,llu::network::recivedMessage* m);


};


#endif
