function sock = zmqpub()
    net.addZMQConnecterToPath();
    sock = net.zmqhelper.getPusher();
end
