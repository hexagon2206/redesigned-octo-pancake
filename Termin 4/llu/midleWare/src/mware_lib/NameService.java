package mware_lib;


public abstract class NameService {	//­ Schnittstelle zum Namensdienst
	public abstract void rebind(Object servant, String name) throws Exception;  // Meldet ein Objekt (servant) beim Namensdienst an.
	public abstract Object resolve(String name) throws Exception;				// Liefert eine generische Objektreferenz zu einem Namen. (vgl. unten)
}
