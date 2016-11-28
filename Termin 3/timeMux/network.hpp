/** @file network.hpp
 *  @brief Prototypes for network comunikation.
 *  @author Lukas Lühr (hexagon2206)
 *  @bug No known bugs.
 */

#ifndef __LLU_NETWORK_HPP__
#define __LLU_NETWORK_HPP__

#include <stdlib.h>
#include <string.h>
#include <thread>
#include <netdb.h>
#include <stdlib.h>


#include <netinet/in.h>
#include <arpa/inet.h>


#include "callback.hpp"
#include "ringBuffer.hpp"
#include "linkedList.hpp"


namespace llu{
    namespace network{

        using namespace std;

        using namespace llu::callback;
        using namespace llu::datastructs;


        /**
         * @brief convertes a given value to the Network byte order (big endian)
         * @param value the value to be converted
         * @param target a pointer to the data field, where the result should be stored
         * @note is host byte order agnostic
         */
        void toNBO(uint8_t value,uint8_t* target);

        /**
         * @brief convertes a given byte fiedl in Network byte order to host byte order
         * @param from where to finde thy byte field ( must be length 8bit)
         * @return Host byte order representation of the data
         */
        uint8_t toHBO_8(uint8_t *from);

        /**
         * @brief convertes a given value to the Network byte order (big endian)
         * @param value the value to be converted
         * @param target a pointer to the data field, where the result should be stored
         * @note is host byte order agnostic
         */
        void toNBO(uint16_t value,uint8_t* target);

        /**
         * @brief convertes a given byte fiedl in Network byte order to host byte order
         * @param from where to finde thy byte field ( must be length 16bit)
         * @return Host byte order representation of the data
         */
        uint16_t toHBO_16(uint8_t *from);

        /**
         * @brief convertes a given value to the Network byte order (big endian)
         * @param value the value to be converted
         * @param target a pointer to the data field, where the result should be stored
         * @note is host byte order agnostic
         */
        void toNBO(uint32_t value,uint8_t* target);

        /**
         * @brief convertes a given byte fiedl in Network byte order to host byte order
         * @param from where to finde thy byte field ( must be length 32bit)
         * @return Host byte order representation of the data
         */
        uint32_t toHBO_32(uint8_t *from);

        /**
         * @brief convertes a given value to the Network byte order (big endian)
         * @param value the value to be converted
         * @param target a pointer to the data field, where the result should be stored
         * @note is host byte order agnostic
         */
        void toNBO(uint64_t value,uint8_t* target);

        /**
         * @brief convertes a given byte fiedl in Network byte order to host byte order
         * @param from where to finde thy byte field ( must be length 64bit)
         * @return Host byte order representation of the data
         */
        uint64_t toHBO_64(uint8_t *from);

        /**
         * @brief resolves an Ipv4 and an port to a sockaddr_in
         * @param addr an ascii encodes IPv4 Address
         * @param port an Port Number
         * @return the Sockaddr_in for the spezified Data
         * @todo Was wennn die daten nicht gültig sind
         */
        sockaddr_in resolve(const char*addr,uint16_t port);

        /**
         * @brief an recived message from an Connection object
         */
        struct recivedMessage{
            size_t length;      /**< @brief the length of the data Buffer */
            size_t dataLength;  /**< @brief how much of the data Buffer is actualy used by data*/
            sockaddr_in sender; /**< @brief if availabe the sender of the Message */
            void *data;         /**< @brief a pointer to an data field containig the acutal message*/
        };

        /**
         * @brief A message ready to be send
         */
        struct sendMessage{
            size_t length;      /**< @brief the length of the data field */
            sockaddr_in target; /**< @brief the reciver ot the message */
            void *data;         /**< @brief Pointer to the data field */
        };

        /**
         * @brief creates an empry recivedMessage object
         *
         * the buffer is allocated togetter with the Object, is is right behind it, it is suffisiant to delete the element
         * @param bufferSize the amout of space to reserve of recivable data
         */
        recivedMessage *createRecivedMessage(size_t bufferSize);
        /**
         * @brief deletes a recived Massage, the data field itself is not touched
         * @param m the message to be deleted
         */
        void destoryRecivedMessage(recivedMessage *m);

        /**
         * @brief creates a Message ready to be send to a connection
         *
         * the buffer is allocated togetter with the Object, is is right behind it, it is suffisiant to delete the element
         * bufferSize elements of from are copied to the Data buffer
         * @param bufferSize the number of bytes to put in the Data buffer
         * @param target the reciver of this message
         * @param from the data source
         */
        sendMessage *createSendMessage(size_t bufferSize,sockaddr_in target,const void *from);
        /**
         * @brief deletes a send Massage, the data field itself is not touched
         * @param m is the message to be deleted
         */
        void destorySendMessage(sendMessage *m);

        //interaface class for a connection, NOT THREAD SAFE
        class Connection{
            public:

                virtual ~Connection(){};

                /**
                 * @brief recives a recivedMessage from the connection
                 *
                 * Blocks untill data is avaliable
                 * @return the recivedMessage rescived the responsebilety for the result belonges to the caller
                 */
                virtual recivedMessage *recvMsg()=0;

                /**
                 * @brief sends the message m over the Connection
                 *
                 * this methode is not blocking
                 * m will be deletet using destorySendMessage
                 */
                virtual void sendMsg(sendMessage *m)=0;

                /**
                 * @brief used to check if the connection is usable
                 * @return true if usable, otherwise false
                 */
                virtual bool alive()=0;

                /**
                 * @brief closes a connection
                 */
                virtual void kill()=0;
        };

        /**
         * @brief copies an compleate recivedMessage
         * @param r the original recivedMessage
         * @return a compleate copy of r
         */
        recivedMessage *copyRecivedMessage(recivedMessage *r);


        typedef bool (recivedMessageClassifierType)(recivedMessage*,signal*);
        typedef bool (*recivedMessageClassifier)(recivedMessage*,signal*);



        typedef callback_registration<void *,recivedMessage*> netwokMsgCallback;

        class ManagedConnection{
            public:
                ManagedConnection(Connection *con);
                ~ManagedConnection();

                void sendMsg(sendMessage *m);
                void addClassifier(recivedMessageClassifier c);
                void addCallback(signal s,netwokMsgCallback *calback);
                void kill();
                bool alive();

            private:


                thread *senderThread;
                static void sender(Connection *con,Ringbuffer<sendMessage *> *outBuffer);

                thread *reciverThread;
                static void reciver(Connection *con,Callback<void *,recivedMessage *> *callbackHandler,LinkedList<recivedMessageClassifier> *classifiers);

                Connection *con;
                Ringbuffer<sendMessage*> *outBuffer;
                Callback<void *,recivedMessage *> *callbackHandler;
                LinkedList<recivedMessageClassifier> *classifiers;
        };


    };
};


#endif
