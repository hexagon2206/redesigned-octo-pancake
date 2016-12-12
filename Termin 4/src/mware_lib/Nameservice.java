package mware_lib;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.ByteBuffer;
import java.nio.channels.SelectionKey;
import java.nio.channels.Selector;
import java.nio.channels.ServerSocketChannel;
import java.nio.channels.SocketChannel;
import java.util.Iterator;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;


public class NameService implements NameServiceInterface {

    private ConcurrentHashMap<String, String> _clients = new ConcurrentHashMap<>();

    public NameService(int port){
        listenOnPort(port);
    }

    private void listenOnPort(int port) {
        // Verwaltet die einzelnen Channels
        Selector sel = null;
        ServerSocketChannel ssc = null;
        try {
            // Erstellung des Serverchannels und anschließende Konfigiration
            sel = Selector.open();
            ssc = ServerSocketChannel.open();
            ssc.bind(new InetSocketAddress("localhost", port));
            ssc.configureBlocking(false);
            int ops = ssc.validOps();
            SelectionKey key = ssc.register(sel, ops, null);

            // Server läuft ewig!!!!
            while (true) {
                // Wählt aus dem ServerSocketChannel, gültige Channel aus
                sel.select();
                // Wird benötigt, um die ausgewählten Channels durchzulaufen
                Set<SelectionKey> keys = sel.selectedKeys();
                Iterator<SelectionKey> iterator = keys.iterator();


                while (iterator.hasNext()) {
                   SelectionKey tmpKey = iterator.next();
                   // Prüft ob Verbindung angenommen werden können
                    if (tmpKey.isAcceptable()) {
                        SocketChannel sc = ssc.accept();

                        if (sc != null && sc.isConnected()) {
                            sc.configureBlocking(false);
                            sc.register(sel, SelectionKey.OP_READ);
                            System.out.println("Verbindung von IP - Adresse: " + sc.getRemoteAddress() + " aktzeptiert");
                        }

                    // Prüft ob aus den Channels gelesen werden kann
                    }else if (tmpKey.isReadable()){
                       SocketChannel sc = (SocketChannel) tmpKey.channel();
                       evaluateMessage(sc);
                       sc.close();
                    }
                }

            }

        } catch (IOException e) {
            e.printStackTrace();
        }
    }


    private void evaluateMessage(SocketChannel sc) throws IOException {
        ByteBuffer typeBuffer = ByteBuffer.allocate(1);
        ByteBuffer msgBuffer = ByteBuffer.allocate(256);
        sc.read(typeBuffer);
        sc.read(msgBuffer);
        String type = new String(typeBuffer.array()).trim();
        String msg = new String(msgBuffer.array()).trim();


        switch (type) {
            // rebind
            case "1":
                System.out.println("Type: " + type);
                System.out.println("Nachricht: " + msg);
                break;
            // Namen auflösen
            case "2":
                break;
            default:
                System.out.println("Fehler");
        }
    }

    /**
     * Mit der Funktion sollen sich Objekte beim Namensdienst registrieren
     *
     * @param servant die Objektreferenz
     * @param name    der Name des Objekts
     */
    @Override
    public void rebind(Object servant, String name) {

    }

    /**
     * Liefert eine Objektreferenz zu einem Namen zurück
     *
     * @param name der Name der Objektrefrenz
     * @return die Objektreferenz zum übergebenen Namen
     */
    @Override
    public Object resolve(String name) {
        return null;
    }
}
