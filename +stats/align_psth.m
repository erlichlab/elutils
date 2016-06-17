function [offset,inc_t,x,y]=align_psth(ev, ts,varargin)
% [offset, inc_t,x,y]=align_psth(ev, ts, varargin)
% 'pre'        3;...
% 	'post'       3;...
% 	'binsz'      0.001;...
% 	'meanflg'    0;...
% 	'krn'        0.25;...
%     'pre_mask', -inf;...
%     'post_mask',+inf;...
%     'max_offset' 1;...
%     'do_plot'  false;...
%     'max_iter' 50;...
%     'var_thres' 0.05;...
%     'mark_this', [];...
%     'save_plot' '';...

pairs={'pre'        3;...
    'post'       3;...
    'binsz'      0.001;...
    'meanflg'    0;...
    'krn'        0.15;...
    'pre_mask', -inf;...
    'post_mask',+inf;...
    'max_offset' 1;...
    'do_plot'  false;...
    'max_iter' 50;...
    'var_thres' 0.05;...
    'mark_this', [];...
    'save_plot' '';...
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

if isscalar(krn)
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
    [y,x]=spike_filter(ev+offset,ts,krn,'pre',pre,'post',post,'kernel_bin_size',binsz);
    
    % xcorr doesn't handle nans well, i think. so this was commented out. -jce
    % [y x]=maskraster(x,y,pre_mask(ref),post_mask(ref));
    
    ymn = nanmean(y(inc_t,:));
    yst = nanstderr(y(inc_t,:));
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
