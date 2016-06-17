function conn = ConfigParse(varargin)

if nargin == 0
    fileName = '~/.dbconf';
elseif nargin == 1
    fileName = varargin{1};
else
    error('Too much input arguments.');
end

if ~exist(fileName,'file')
    error(['File ' fileName ' does not exist.']);
end

fh = fopen(fileName,'r');
if fh == -1
    error(['File: ''' fileName ''' does not exist or can not be opened.']);
end

declare = fgetl(fh);
if strfind(declare,'client')
    data = textscan(fh, ...
            '%s', ...
            'delimiter', '=', ...
            'endOfLine', '\r\n');
    fclose(fh);
    data = strtrim(data{1});
    config = cell2struct(data(2:2:6)', data(1:2:5)',2);
    conn = database('',config.user, config.passwd, 'Vendor','MySQL','Server',config.host);
else
    error(['File: ''' fileName ''' is a wrong format.']);
end
missed = checkConfig(config);
if ~isempty(missed)
    error(['File: ''' fileName ''' parameter ''' missed ''' neccessary.']);
end    
if ~find(strcmp('port',fieldnames(config)))
    config.port = 3306;
end
%=========================================================================
function missed = checkConfig(config)

missed = {};
needPara = {'host','user','passwd','db'};
field = fieldnames(config);
for i =1:length(needPara)
    if ~find(strcmp(needPara{i},field))
        missed = {missed needPara{i}};
    end
end

        


