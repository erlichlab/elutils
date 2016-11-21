% [snd lrate rrate data] = make_pbup(R, g, srate, T, varargin)
%
% Makes Poisson bups
% bup events from the left and right speakers are independent Poisson
% events
%
% =======
% inputs:
%
%	R		total rate (in clicks/sec) of bups from both left and right
%	      speakers (r_L + r_R). Note that if distractor_rate > 0, then R
%	      includes these stereo distractor bups as well.
%
%	g		the natural log ratio of right and left rates: log(r_R/r_L)
%
%	srate	sample rate
%
%	T		total time (in sec) of Poisson bup trains to be generated
%
% =========
% varargin:
%
% bup_width
%			width of a bup in msec  (Default 3)
% base_freq       
%           base frequency of an individual bup, in Hz. The individual bup
%           consists of this in combination with ntones-1 octaves above the
%           base frequency. (Default 2000)
% 
% ntones
%           number of tones comprising each individual bup. The bup is the
%           basefreq combined with ntones-1 higher octaves. (Default 5)
% 
% bup_ramp        
%           the duration in msec of the upwards and downwards volume ramps
%           for individual bups. The bup volume ramps up following a cos^2
%           function over this duration and it ramps down in an inverse
%           fashion.
% 
% first_bup_stereo
%			if 1, then the first bup to occur is forced to be stereo
%
% distractor_rate
%			if >0, then this is the rate of stereo distractors (bups that
%			are played on both speakers).  These stereo bups are generated
%			as Poisson events and then combined with those generated for
%			left and right sides.
%			note that this value affects the R used to compute independent
%			Poisson rates for left and right sides, such that
%			R = R - 2*distractor_rate
%
% generate_sound
%			if 1, then generate the snd vector
%			if 0, the snd vector will be empty; data will still contain the
%			bups times
%
% fixed_sound
%			if [], then generate new pbups sound
%			if not empty, then should contain a struct D with fields:
%				D.left  = [left bup times]
%				D.right = [right bup times]
%				D.lrate
%				D.rrate
%			these two vectors should be at least as long as T, so there's
%			no gap in the sound that's generated
%
% crosstalk
%			[left_crosstalk right_crosstalk]
%			between 0 and 1, determines volume of left clicks that are
%			heard in the right channel, and vice versa.
%			if only number is provided, the crosstalk is assumed to be
%			symmetric (i.e., left_crosstalk = right_crosstalk)
%
% avoid_collisions
%           produces a pseudo-poisson clicks train where no clicks are
%           allowed to overlap.  If the click rate is so high that
%           collisions are unavoidable a warning will be displayed
%           added: Chuck 2010-10-05
%
% force_count
%           produces a pseudo-poisson click train where the precise number 
%           of clicks is predetermined. The rate variables are interpreted 
%           as counts.  
%           added: Chuck 2010-10-05
%
% ========
% outputs:
%
% snd		a vector representing the sound generated
%
% lrate		rate of Poisson events generated only on the left
%
% rrate		rate of Poisson events generated only on the right
%
% data		a struct containing the actual bup times (in sec, centered in
%			middle of every bup) in snd.
%			data.left and data.right
%

function [snd lrate rrate data] = make_pbup(R, g, srate, T, varargin)

pairs = {...
    'bup_width',        3; ...
    'base_freq',        2000; ...
    'ntones',           5; ...
    'bup_ramp',         2; ...
	'first_bup_stereo'  0; ...
	'distractor_rate'   0; ...
	'generate_sound'    1; ...
	'fixed_sound'      []; ...
	'crosstalk'     [0 0]; ...
    'avoid_collisions'  0; ...
    'force_count'       0; ...
    }; parseargs(varargin, pairs);

if isempty(crosstalk), crosstalk = [0 0]; end; %#ok<NODEF>
if numel(crosstalk) < 2, crosstalk = crosstalk*[1 1]; end;

if isempty(fixed_sound),
	if distractor_rate > 0,
		R = R - distractor_rate*2;
	end;

	% rates of Poisson events on left and right
	rrate = R/(exp(-g)+1);
	lrate = R - rrate;
    if force_count == 1
        %rates are interpreted as counts and therefore must be integers
        rrate = round(rrate);
        lrate = round(lrate);
    end

	%t = linspace(0, T, srate*T);
    lT = srate*T; %the length of what previously was the t vector

    if avoid_collisions == 1
        lT2 = ceil(T * 1e3 / bup_width);
        if force_count == 1
            if ~isnan(lrate); temp = randperm(lT2); tp1 = temp(1:lrate); tp1 = sortrows(tp1')'; else tp1 = []; end
            if ~isnan(rrate); temp = randperm(lT2); tp2 = temp(1:rrate); tp2 = sortrows(tp2')'; else tp2 = []; end
        else
            if ~isnan(lrate); tp1 = find(rand(1,lT2) < lrate/(1e3/bup_width)); else tp1 = []; end
            if ~isnan(rrate); tp2 = find(rand(1,lT2) < rrate/(1e3/bup_width)); else tp2 = []; end
        end
        
        if first_bup_stereo,
            first_bup = min([tp1 tp2]);
            bupwidth = 1;
            if first_bup <= bupwidth, extra_bup = first_bup;
            else                      extra_bup = ceil(rand(1)*(first_bup-bupwidth));
            end;
            tp1 = union(extra_bup, tp1);
            tp2 = union(extra_bup, tp2);
        end
        
        if distractor_rate > 0,
            if force_count == 1
                temp = randperm(lT2); td = temp(1:round(distractor_rate)); td = sortrows(td')'; 
            else
                td  = find(rand(1,lT2) < distractor_rate/(1e3/bup_width));
            end
            tp1 = union(td, tp1);
            tp2 = union(td, tp2);
        end
        if (lrate + distractor_rate) * bup_width > 200 || (rrate + distractor_rate) * bup_width > 200
            disp('Warning: Click rate is set to high to ensure Poisson train with avoid_collisions on');
        end
        
        tp1 = tp1 * (srate / (1e3 / bup_width));
        tp2 = tp2 * (srate / (1e3 / bup_width));
        
    else
        % times of the bups are Poisson events
        if force_count == 1
            if ~isnan(lrate); temp = randperm(lT); tp1 = temp(1:lrate); tp1 = sortrows(tp1')'; else tp1 = []; end
            if ~isnan(rrate); temp = randperm(lT); tp2 = temp(1:rrate); tp2 = sortrows(tp2')'; else tp2 = []; end
        else
            if ~isnan(lrate); tp1 = find(rand(1,lT) < lrate/srate); else tp1 = []; end
            if ~isnan(rrate); tp2 = find(rand(1,lT) < rrate/srate); else tp2 = []; end
        end
        % in order not to alter the difference in bup numbers between left and
        % right, the extra stereo bup is placed randomly somewhere between 0 and
        % the earliest bup on either side
        if first_bup_stereo,
            first_bup = min([tp1 tp2]);
            bupwidth = bup_width*srate/2;
            if first_bup <= bupwidth,
                extra_bup = first_bup;
            else
                extra_bup = ceil(rand(1)*(first_bup-bupwidth) + bupwidth);
            end;
            tp1 = union(extra_bup, tp1);
            tp2 = union(extra_bup, tp2);
        end;

        if distractor_rate > 0,
            if force_count == 1
                temp = randperm(lT); td = temp(1:round(distractor_rate)); td = sortrows(td')'; 
            else
                td  = find(rand(1,lT) < distractor_rate/srate);
            end
            tp1 = union(td, tp1);
            tp2 = union(td, tp2);
        end;
    end

	data.left  = tp1/srate;
	data.right = tp2/srate;
else  % if we've provided bupstimes for which a sound will be made
	lrate = fixed_sound.lrate;
	rrate = fixed_sound.rrate;
	
	data.left = fixed_sound.left;
	data.right = fixed_sound.right;
	
	tp1 = round(fixed_sound.left*srate);
	tp2 = round(fixed_sound.right*srate);
	%t = linspace(0, T, srate*T);
    lT = srate*T;
end;

if generate_sound,
    bup = singlebup(srate, 0, 'ntones', ntones, 'width', bup_width, 'basefreq', base_freq, 'ntones', ntones, 'ramp', bup_ramp);
	w = floor(length(bup)/2);

	snd = zeros(2, lT);
	for i = 1:length(tp1), % place left bups
		if tp1(i) > w && tp1(i) < lT-w,
			snd(1,tp1(i)-w:tp1(i)+w) = snd(1,tp1(i)-w:tp1(i)+w)+bup;
		end;
	end;
	for i = 1:length(tp2), % place right bups
		if tp2(i) > w && tp2(i) < lT-w,
			snd(2,tp2(i)-w:tp2(i)+w) = snd(2,tp2(i)-w:tp2(i)+w)+bup;
		end;
	end;

	if sum(crosstalk) > 0, % implement crosstalk
		temp_snd(1,:) = snd(1,:) + crosstalk(2)*snd(2,:);
		temp_snd(2,:) = snd(2,:) + crosstalk(1)*snd(1,:);
		
		% normalize the sound so that the volume (summed across both
		% speakers) is the same as the original snd before crosstalk
		ftemp_snd = fft(temp_snd,2);
		fsnd      = fft(snd,2);
		Ptemp_snd = ftemp_snd .* conj(ftemp_snd);
		Psnd      = fsnd .* conj(fsnd);
		vol_scaling = sqrt(sum(Psnd(:))/sum(Ptemp_snd(:)));
		
		snd = real(ifft(ftemp_snd * vol_scaling));
	end;
		
	snd(snd>1) = 1;
	snd(snd<-1) = -1;
else
	snd = [];
end;