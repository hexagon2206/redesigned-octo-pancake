package tools;

import java.io.File;

/**
 * Erzeugt aus einer .idl - Datei die benötigten Java - Dateien
 */
public interface IDLCompiler {

    /**
     * Erzeugt aus der übergebenen Datei die benötigten Java - Dateien
     * @param idlFile die idl - Datei mit den Schnittstellenbeschreibungen
     */
    void compile(File idlFile);

}
