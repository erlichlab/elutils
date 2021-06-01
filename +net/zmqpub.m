function sock = zmqpub()
    net.addZMQConnecterToPath();
    sock = net.zmqhelper.getPublisher();
end
