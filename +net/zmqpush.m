function sock = zmqpush()
    net.addZMQConnecterToPath();
    sock = net.zmqhelper.getPusher();
end
