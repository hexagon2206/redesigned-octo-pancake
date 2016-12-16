package mware_lib;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.ByteBuffer;
import java.nio.channels.SelectionKey;
import java.nio.channels.Selector;
import java.nio.channels.ServerSocketChannel;
import java.nio.channels.SocketChannel;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;


public class NameService implements NameServiceInterface {

    // Speichert die Referenzen der Objekte mit einem dazugehörigen Namen
    private ConcurrentHashMap<String, String> _clients = new ConcurrentHashMap<>();

 /*   private static final int _TYPEBUFFERSIZE = 1;
    private static final int _NAMEBUFFERSIZE = 10;
    private static final int _REFERENCEBUFFERSIZE = 246;
    private static final String _CHARSET = "UTF-8";

    public NameService(int port){
        listenOnPort(port);
    }


    private void listenOnPort(int port) {
        // Verwaltet die einzelnen Channels
        Selector sel;
        ServerSocketChannel ssc;
        try {
            // Erstellung des Serverchannels und anschließende Konfigiration
            sel = Selector.open();
            ssc = ServerSocketChannel.open();
            ssc.bind(new InetSocketAddress("localhost", port));
            ssc.configureBlocking(false);
            int ops = ssc.validOps();
            ssc.register(sel, ops, null);

            // Server läuft ewig!!!!
            while (ssc.isOpen()) {

                // Wählt aus dem ServerSocketChannel, gültige Channel aus
                sel.select();
                // Wird benötigt, um die ausgewählten Channels durchzulaufen
                Set<SelectionKey> keys = sel.selectedKeys();


                for (SelectionKey tmpKey : keys) {
                    // Prüft ob Verbindung angenommen werden können
                    if (tmpKey.isAcceptable()) {
                        SocketChannel sc = ssc.accept();

                        if (sc != null && sc.isConnected()) {
                            sc.configureBlocking(false);
                            sc.register(sel, SelectionKey.OP_READ);
                            System.out.println("Verbindung von IP - Adresse: " + sc.getRemoteAddress() + " aktzeptiert");
                        }

                        // Prüft ob aus den Channels gelesen werden kann
                    } else if (tmpKey.isReadable()) {
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
        ByteBuffer typeBuffer = ByteBuffer.allocate(_TYPEBUFFERSIZE);
        ByteBuffer nameBuffer;
        ByteBuffer referenceBuffer;
        String name;
        String reference;

        sc.read(typeBuffer);
        String type = new String(typeBuffer.array(), _CHARSET).trim();

        switch (type) {
            // rebind
            case "1":
                // Neuen ByteBuffer erstellen um evtl alte Daten zu löschen
                nameBuffer = ByteBuffer.allocate(_NAMEBUFFERSIZE);
                referenceBuffer = ByteBuffer.allocate(_REFERENCEBUFFERSIZE);
                // Auslesen der Infos aus dem Stream
                sc.read(nameBuffer);
                sc.read(referenceBuffer);
                // Umwandeln in einen String
                name = new String(nameBuffer.array(),_CHARSET).trim();
                reference = new String(referenceBuffer.array(), _CHARSET).trim();

                System.out.println("Type: " + type);
                System.out.println("Name: " + name);
                System.out.println("Reference: " + reference);

                rebind(reference, name);

                break;

            // Namen auflösen
            case "2":
                nameBuffer = ByteBuffer.allocate(_NAMEBUFFERSIZE);
                sc.read(nameBuffer);
                name = new String(nameBuffer.array()).trim();

                String resolvedName = resolve(name);
                ByteBuffer typeAnswer = ByteBuffer.allocate(_TYPEBUFFERSIZE);
                ByteBuffer nameAnswer = ByteBuffer.allocate(_NAMEBUFFERSIZE);
                ByteBuffer referenceAnswer = ByteBuffer.allocate(_REFERENCEBUFFERSIZE);

                if (resolvedName != null) {
                    typeAnswer.put("3".getBytes(_CHARSET));
                    nameAnswer.put(name.getBytes(_CHARSET));
                    referenceAnswer.put(resolvedName.getBytes(_CHARSET));

                    sc.write(typeAnswer);
                    sc.write(nameAnswer);
                    sc.write(referenceAnswer);
                } else {
                    typeAnswer.put("4".getBytes(_CHARSET));
                    nameAnswer.put(name.getBytes(_CHARSET));

                    sc.write(typeAnswer);
                    sc.write(nameAnswer);
                }

                break;
            default:
                // TODO: Timeout nachricht einpflegen

                System.out.println("Fehler");
        }
    }
*/
    /**
     * Mit der Funktion sollen sich Objekte beim Namensdienst registrieren.
     * Erhält der Namensdienst mehrmals  den gleichen Key, dann wird die dazugehröge Referenz überschrieben
     *
     * @param servant die Objektreferenz
     * @param name    der Name des Objekts
     */
    @Override
    public void rebind(String servant, String name) {

        if (_clients.containsKey(name)){
            _clients.replace(name, servant);
        }else{
            _clients.put(name, servant);
        }
    }

    /**
     * Liefert eine Objektreferenz zu einem Namen zurück
     *
     * @param name der Name der Objektrefrenz
     * @return die Objektreferenz zum übergebenen Namen; null wenn der Name nicht gefunden werden konnte
     */
    @Override
    public String resolve(String name) {
        if (_clients.containsKey(name)){
            return _clients.get(name);
        }else{
            return null;
        }
    }
}
