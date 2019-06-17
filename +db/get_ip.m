function ip = get_ip()

%% 
if ispc
    [r,p]=system('ipconfig /all')
elseif ismac
    [r,p] = system('ifconfig');
    ind = strfind(p,'inet ');
    indshift = 5;
else
    [r,p] = system('ip route get 1 | grep -oP "src \K\S+"');
    ip = strtrim(p);
    return;
end
%%
ipind = 1;
found = false;
for ix = 1:numel(ind)
    thisip = strtrim(strtok(p(ind(ix)+indshift:ind(ix)+indshift+15),' '));
    if ~strcmp(thisip, {'127.0.0.1','127.0.1.1'})
        IP{ipind} = thisip;
        found = true;
    end
end

if found
if numel(IP)>1
    fprintf(2,'GOt multiple IPs returning first');
end

ip = IP{1};
else
    fprintf(2,'In db.get_ip no valid IP addresses found. Maybe this OS has a different format for ifconfig.\n')
end