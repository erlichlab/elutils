function sock = zmqgamepull()
    % zmqgamepush - Create a ZMQ game push socket for the game server
    net.addZMQConnecterToPath();
    sock = net.zmqhelper.getGameServerPull();
end