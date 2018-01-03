function ok = sendmattermost(channel,message,varargin)
%	ok = sendmattermost(channel,message,[url, payload])
%
% Sends a message to any channel in the mattermost team.
% Inputs:
% channel   required. Will send the message to this channel.
% message   required if payload not set.  Message can use markdown. THe message is parsed with an printf like parser. So be careful of special characters (e.g. \n splits lines but if you want to use a \ in code you need to put \\) 
% url		if not specified will try to read from ~/.dbconf
% payload 	if not specified will construct a simple payload from message. 


	inpd = @utils.inputordefault;

	url = inpd('url',[],varargin);
	payload = inpd('payload',[],varargin);

	if isempty(payload)
		payload = sprintf('{"channel":"%s", "text":%s}',channel,jsonencode(message));
	else
		if ~isempty(channel) || ~isempty(message)
			fprintf(2,'Using payload and ignoring channel and message content.');
		end
	end

	if isempty(url)
		try
			out = utils.ini2struct('~/.dbconf');
			url = out.mattermost.url;
		catch me
			if strcmp(me.identifier, 'MATLAB:FileIO:InvalidFid')
				fprintf('Cannot find ~/.dbconf');
			elseif strcmp(me.identifier, 'MATLAB:nonExistentField')
				fprintf('Your ~/.dbconf does not contain the url for mattermost');
			else
				rethrow(me);
			end
			ok = false;
			return;
		end
	end

	ok = webwrite(url, 'payload', payload);

