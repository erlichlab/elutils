function ip = get_ip()

%% 
if ispc
[r,p]=system('ipconfig /all')
else
    [r,p] = system('ifconfig')
end
%%
ind = strfind(p,'inet ');
ipind = 1;
for ix = 1:numel(ind)
    thisip = strtrim(strtok(p(ind(ix)+5:ind(ix)+20),' '));
    if ~strcmp(thisip, {'127.0.0.1','127.0.1.1'})
        IP(ipind) = thisip;
    end
end

if numel(IP)==1
    ip = IP{1};
else 
    