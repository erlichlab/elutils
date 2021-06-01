function sock = zmqsub(substr)
    net.addZMQConnecterToPath();
    sock = net.zmqhelper.getSubscriber(substr);
end
