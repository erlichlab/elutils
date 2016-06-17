function [offset,inc_t,x,y]=align_cd(ev, ts,val,varargin)
% [ax_handle,data]=align_cd(ev, ts,val, varargin)

% pairs={'pre'        3;...
%        'post'       3;...
%        'binsz'      0.005;...
%        'meanflg'    0;...
%        'krn'        0.25;...
%     'pre_mask', -inf;...
%     'post_mask',+inf;...
%  'do_plot'  false;...
%     'max_iter' 50;...
%     'max_peak' 1e10;...
%      

pairs={'pre'        3;...
	'post'       3;...
	'binsz'      0.005;...
    'pre_mask', -inf;...
    'post_mask',+inf;...
    'max_offset' 1;...
    'do_plot'  false;...
    'max_iter' 50;...
    'max_peak' [];...
    'var_thres' 0.05;...
	}; parseargs(varargin,pairs,{},1);



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


old_var=10e10;
    done=0;
    offset=zeros(size(ev));
    if do_plot
    clf;ax=axes;
    hold on;
    end
    cnt=1;
    inc_t=ones(size(ev))==1;
        
	%% Calculate the mean and ci of the
while ~done
    [y,x]=cdraster(ev+offset,ts(:),val(:),pre,post,binsz);
    if cnt==1 && ~isempty(max_peak)
            thresh=prctile(y(:),max_peak);
    else
        thresh=+inf;
    end
    
    y(abs(y)>thresh)=0;
    y(isnan(y))=0;
    % [y x]=maskraster(x,y,pre_mask(ref),post_mask(ref));
    
	ymn = nanmean(y(inc_t,:));
    yst = nanstderr(y(inc_t,:));
    
    if do_plot
    plot(ax,x,ymn-yst,x,ymn+yst,'Color',[1-0.2*cnt, 0 ,0]);
    drawnow
    end   
    
    for tx=1:numel(ev);
        if inc_t(tx)
          
        [xcy,xcx]=xcorr(y(tx,:)-nanmean(y(tx,:)),ymn-nanmean(ymn));
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
	