function zmqlistener = test_nonblocking()
    zmqlistener = timer();
    zmqlistener.StartFcn = @setup_zmq;
    zmqlistener.TimerFcn = @wait_for_msg;
    zmqlistener.ExecutionMode = 'fixedSpacing';
    zmqlistener.BusyMode = 'drop';
    zmqlistener.Period = 2;
    zmqlistener.TasksToExecute = +inf;
    zmqlistener.StartDelay = 0.1;

    start(zmqlistener)

end

function setup_zmq(obj,event)
    obj.userdata = net.zmqsub('hammer');
end

function wait_for_msg(obj,event)
    sub = obj.userdata;
    [addr, data] = sub.recvjson();
    if ~isempty(data)
        disp(data)
    else
        disp('no data')
    end
end