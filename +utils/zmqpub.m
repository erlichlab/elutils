function zmqpub(msg,varargin)

import org.zeromq.ZMQ
%%
context = ZMQ.context(1);
sub = context.socket(ZMQ.SUB);
sub.connect('tcp://localhost:6001');
sub.subscribe(uint8('416'));



while 1
    try
       msg = sub.recvStr(ZMQ.NOWAIT);
       char(msg');
    catch
        fprintf(2,'no msg\n')
        pause(0.1);
    end
    
end


end
