function [bb_sound, bb_len] = Make_badboy_sound(wn_len, spacer_len, repeats, varargin)

% function [bb_sound, bb_len] = Make_badboy_sound(wn_len, spacer_len, repeats)
%
% Makes the penalty "Bad Boy" sound, which consists of alternating segments
% of white noise and silence, generating a 'shh-shh-shh-' effect.
%
% Input params:
% wn_len: Duration of the whitenoise segment (the "shh") (secs)
% spacer_len: Interval length between "shh"s (secs)
% repeats: Number of whitenoise-interval repeats.
%
% Varargin:
% volume: Sound intensity of BadBoySound - normal, Louder, LOUDEST

pairs = { ...
	'volume', 'normal' ; ...
    'volume_factor',1; ... % linear multiplicative by which to scale sound amplitude
}; parse_knownargs(varargin, pairs);


% set up vars
amp = get_generic('amp');
srate = get_generic('sampling_rate');

if strcmp(wn_len, 'generic')
    wn_len = get_generic('badboy_shh_len');
    spacer_len = get_generic('badboy_spacer_len');
    repeats = get_generic('badboy_reps');
    if nargin > 1
	  %  ['Volume is ' volume]
    	if strcmpi(volume, 'Louder')
		amp = amp*3;
	elseif strcmpi(volume,'LOUDEST')		
	    	amp = amp*8;
   	end;
    end;
else
    if repeats < 1
        error('Repeat number < 1 does not make sense for this sound');
    end;
end;

bb_unit = [amp*rand(1, floor(wn_len*srate)) ...
    zeros(1, floor(spacer_len*srate))];

bb_sound = bb_unit;
for r = 2:repeats
    bb_sound = [bb_sound bb_unit];
end;

bb_len = length(bb_sound)/floor(srate);
bb_sound = bb_sound .* volume_factor;
