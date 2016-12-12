import mware_lib.NameService;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.ByteBuffer;
import java.nio.channels.SocketChannel;

/**
 * Created by Jolly Joker on 12.12.2016.
 */
public class Main {
// http://crunchify.com/java-nio-non-blocking-io-with-server-client-example-java-nio-bytebuffer-and-channels-selector-java-nio-vs-io/

    public static void main(String[] args) {
        int port = 8888;
        new Thread(() -> {
            NameService ns = new NameService(port);
        }).start();


        new Thread(() -> {
            InetSocketAddress isa = new InetSocketAddress("localhost", port);

            SocketChannel sc = null;
            try {
                sc = SocketChannel.open(isa);

                System.out.println("habe channel geöffnet");
                byte[] message = "1".getBytes();
                ByteBuffer bb = ByteBuffer.wrap(message);
                sc.write(bb);
                message = "Hallo Welt".getBytes();
                bb = ByteBuffer.wrap(message);
                sc.write(bb);
                sc.close();
            } catch (IOException e) {
                e.printStackTrace();
            }

        }).start();
    }
}
