function sock = zmqgamesub(substr)
    net.addZMQConnecterToPath();
    sock = net.zmqhelper.getGameServerSubscriber(substr);
end
