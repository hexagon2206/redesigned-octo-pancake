package mware_lib;


public abstract class Stellvertreter {
    private String _name;
    private ObjectBroker _ob;

    public void setBroker(ObjectBroker broker, String name){
        _name = name;
        _ob = broker;
    }
}
