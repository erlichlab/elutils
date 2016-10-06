function [offset,inc_t,x,y]=align_psth(ev, ts,varargin)
% [offset, inc_t,x,y]=align_psth(ev, ts, [key, val])
%
% Inputs:
% ------
% ev        A list of the time in each trial (relative to session start) of a reference event (in seconds). E.g. Time of stimulus presentation.
% ts        Times (in seconds relative to session start) of spikes (or any point-process of interest)
%
% Optional Inputs (=default value)
%
%
% pre=       3;       % Include 3 seconds before the reference event
% post=      3;       % Include 3 seconds after the reference event
% binsz=     0.001;   % 1 ms bin size
% krn=       0.15;    % Use a Normal smoothing kernel of 150 ms
% pre_mask= -inf;     % This can be a scalar or vector of times relative to the reference event. 
%                     %   Data before this time gets converted to NaN 
% post_mask=+inf;     % Like pre_mask but to mask end of trial 
% max_offset=1;       % How far can each trial be shifted from mean PSTH.
% do_plot= false;     % Plot? Useful for debugging and checking whether fits work.
% max_iter=50;        % Maximum iterations (if var_thres is not reached).
% var_thres=0.05;     % If the difference in the variation of the mean PSTH is less than this fraction
%                     %   then end.
% mark_this= [];      % A list of times (relative to ev) to mark on the plots. (e.g. a go cue)
% save_plot='';       % if you want to save the process to a eps, add a name here.
%
% Outputs
% -------
% offset        A double vector (same length as ev) with the relative time offsets of each trial.
% inc_t         A logical vector (same length as ev) which is false
% x             The time axis of the PSTH (e.g. -pre:binsz:post)
% y             A matrix [ev rows and same columns as x] of the aligned trials.
%
% Example:
%
% ev = (1:30)*5;  
% ts = [];
% for i=1:29
%   ts = [ts; i*5 + normrnd(1+rand*2,0.4,[100,1])]
% end
% ts=sort(ts)
% [offset,inct, ax,ay] = stats.align_psth(ev,ts,'pre',0,'krn',0.1,'do_plot',true);

pre=       3;       % Include 3 seconds before the reference event
post=      3;       % Include 3 seconds after the reference event
binsz=     0.001;   % 1 ms bin size
krn=       0.15;    % Use a Normal smoothing kernel of 150 ms
pre_mask= -inf;     % This can be a scalar or vector of times relative to the reference event. 
                    %   Data before this time gets converted to NaN 
post_mask=+inf;     % Like pre_mask but to mask end of trial 
max_offset=1;       % How far can each trial be shifted from mean PSTH.
do_plot= false;     % Plot? Useful for debugging and checking whether fits work.
max_iter=50;        % Maximum iterations (if var_thres is not reached).
var_thres=0.05;     % If the difference in the variation of the mean PSTH is less than this fraction
                    %   then end.
mark_this= [];      % A list of times (relative to ev) to mark on the plots. (e.g. a go cue)
save_plot='';       % if you want to save the process to a eps, add a name here.

utils.overridedefaults(who,varargin);



if isscalar(pre_mask)
    pre_mask=zeros(1,numel(ev))+pre_mask;
elseif numel(pre_mask)~=numel(ev)
    fprintf(1,'numel(pre_mask) must equal num ref events or be scalar');
    return;
end


if isscalar(post_mask)
    post_mask=zeros(1,numel(ev))+post_mask;
elseif numel(post_mask)~=numel(ev)
    fprintf(1,'numel(post_mask) must equal num ref events or be scalar');
    return;
end

if isscalar(krn)
    % If krn is scalar then create a smoothing kernel that is Normal with S.D. krn.
    dx=ceil(5*krn);
    kx=-dx:binsz:dx;
    krn=normpdf(kx,0, krn);
  %  krn(1:(find(kx==0)-1))=0;
    krn=krn/sum(krn);
end

old_var=10e10;
done=0;
thres=50;
offset=zeros(size(ev));
if do_plot
    clf;ax=axes('Position',[0.1 0.1 0.2 0.2]);
    hold on;
end
cnt=1;
inc_t=ones(size(ev))==1;
inc_t(isnan(ev))=false;
%% Calculate the mean and ci of the
while ~done
    [y,x]=stats.spike_filter(ev+offset,ts,krn,'pre',pre,'post',post,'kernel_bin_size',binsz);
    
    % xcorr doesn't handle nans well, i think. so this was commented out. -jce
    % [y x]=maskraster(x,y,pre_mask(ref),post_mask(ref));
    
    ymn = nanmean(y(inc_t,:));
    yst = stats.nanstderr(y(inc_t,:));
    if cnt==1
        maxy=2*max(ymn);  % this is used to set the ylim for the plot
    end
    if do_plot
        cla
        imagesc(x,[1 maxy],y(inc_t,:),'Parent',ax);
        colormap('hot')
        hold(ax,'on')
        % % This code plotted the average PSTH on top of the heat map. But was a bit distracting.
        %   plot(ax,x,ymn-yst,x,ymn+yst,'Color',[1-0.2*cnt, 0 ,0]);
        %   plot(ax,x,ymn-yst,x,ymn+yst,'Color',[0.2 0.2 0.9],'LineWidth',2);
        xlim([-pre post])
        ylim([1 maxy])
        xlabel('Time (s)')
        %  ylabel('Spike/sec')
        set(ax,'YTick',[]);
        yss=linspace(1,maxy,sum(inc_t==1));
        plot(ax,-offset(inc_t), yss,'c+');
        if ~isempty(mark_this)
            plot(ax,-offset(inc_t)+mark_this(inc_t), yss, 'gx');
        end
        
        if cnt==1
            cbh=colorbar('peer',ax(1),'East');
            
            set(cbh,'Position',get(cbh,'Position')-[0.2 0 0 0])
        end
        drawnow
        if ~isempty(save_plot)
            saveas(gcf,sprintf('ap_%s_%d.eps',save_plot,cnt),'epsc2');
        end
        
        if cnt==1
            set(cbh,'Visible','off')
        end
    end
    
    
    for tx=1:numel(ev);
        
        if inc_t(tx)
            [xcy,xcx]=xcorr(y(tx,:)-mean(y(tx,:)),ymn-mean(ymn));
            [v,peakx]=max(xcy);
            offset(tx)=offset(tx)+xcx(peakx)*binsz;
            if abs(offset(tx))>max_offset
                inc_t(tx)=false;
            end
        end
    end
    
    
    new_var=sum(nanvar(y));
    var_diff=(old_var-new_var)/old_var;

    if do_plot
        fprintf('Variance improved by %2.3g %% of total variance\n',100*var_diff);
    end
    old_var=new_var;
    cnt=cnt+1;
    if abs(var_diff)<var_thres || cnt>max_iter
        done=true;
    end
    
end
