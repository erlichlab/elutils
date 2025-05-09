function sock = zmqgamepub()
    net.addZMQConnecterToPath();
    sock = net.zmqhelper.getGameServerPublisher();
end
