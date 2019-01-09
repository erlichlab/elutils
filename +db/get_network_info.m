function [ip,mac,hostname]=get_network_info
ip = '0.0.0.0'; mac='0000000000'; hostname='unknown';  % Default values in case ip address cannot be determined

import java.net.*;
try
    % This gets the info as seen by the outside world
    dbc = db.labdb.getConnection();
    userstr=dbc.get('select user()');
    userstr=userstr{1};
    atx=find(userstr=='@');
    hostn=userstr(atx+1:end);
    IA=InetAddress.getAllByName(hostn);
catch
    % We are not connected to bdata.  just use java to get the hostname
    % This is basically the same as calling system('hostname');
    IA=InetAddress.getAllByName(InetAddress.getLocalHost().getHostName());
end


try
    
    keeps=zeros(size(IA));
    for ix=1:numel(IA)
        if contains(class(IA(ix)),'4') % this is an IPv4 address
            ip=char(IA(ix).getHostAddress);
            if ip(1)=='0' || isequal(ip,'127.0.0.1') || isequal(ip,'127.0.1.1') % ignore localhost and microsoft tv/video connector
                keeps(ix)=0;
            else
                keeps(ix)=1;
            end
        end
    end
    
    
    if sum(keeps)==1;
        good_IA=find(keeps==1);
    elseif sum(keeps)>1
        warning('Not sure what my IP address is');
        good_IA=find(keeps==1,1,'first');
    else
        'Could not find any IP'
        [ip,mac,hostname] = deal([]);
        return
    end
        
    
    
    ip=char(IA(good_IA).getHostAddress);
    if nargout>1
        ni=NetworkInterface.getByInetAddress(IA(good_IA));
    
        if ~isempty(ni)
            CA=double(ni.getHardwareAddress);
            hostname=char(IA(good_IA).getHostName);
            try
                for hx=1:6
                    mac(2*hx-1:2*hx)=dec2hex(mod(CA(hx),2^8),2);
                end
            catch
                mac = '00:00:00:00:00:00';
            end
        end
    end
    
catch
    utils.showerror;
end