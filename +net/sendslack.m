function ok = sendslack(message,varargin)
% ok = sendslack(message,[url, payload])
%
% Sends a message to erlich-team/#bot-notices
% Inputs:
% url		if not specified will try to read from ~/.dbconf
% payload 	if not specified will construct a simple payload from message. Complex messages can be send with custom payloads: https://api.slack.com/docs/message-attachments



	inpd = @utils.inputordefault;

	url = inpd('url',[],varargin);
	payload = inpd('payload',[],varargin);
	%channel = '#bot-notices';

	if isempty(payload)
		payload = sprintf('{"text":"%s"}',message);
	else
		if ~isempty(message)
			fprintf(2,'Using payload and ignoring channel and message content.');
		end
	end


	if isempty(url)
		try
			out = utils.ini2struct('~/.dbconf');
			url = out.slack.url;
		catch me
			if strcmp(me.identifier, 'MATLAB:FileIO:InvalidFid')
				fprintf('Cannot find ~/.dbconf');
			elseif strcmp(me.identifier, 'MATLAB:nonExistentField')
				fprintf('Your ~/.dbconf does not contain the url for slack');
			else
				rethrow(me);
			end
			ok = false;
			return;
		end
	end

	ok = webwrite(url, 'payload', payload);

