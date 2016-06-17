function [offset,inc_t,x,y]=align_hv(ev,ts,val,varargin)
% [offset,inc_t,x,y]=align_hv(ev, ts,val, varargin)
%
% pairs={'pre'        3;...
%        'post'       3;...
%        'binsz'      0.001;...
%        'meanflg'    0;...
%        'krn'        0.25;...
%       'max_offset' 1;...
%     'pre_mask', -inf;...
%     'post_mask',+inf;...
%     'do_plot'  false;...
%     'max_iter' 100;...
%     'max_peak' 1000;...
%     'var_thres' 0.05;...
%     'save_plot' '';...
%     'col_axis'  [-50 500];...
%     'col_map'   jet;...
%     'mark_this',[];...
% 	}; parseargs(varargin,pairs,{},1);
% %

pairs={'pre'        3;...
    'post'       3;...
    'binsz'      0.001;...
    'pre_mask', -inf;...
    'post_mask',+inf;...
    'max_offset' 1;...
    'do_plot'  false;...
    'max_iter' 100;...
    'max_peak' 1000;...
    'var_thres' 0.05;...
    'save_plot' '';...
    'col_axis'  [-50 500];...
    'col_map'   jet;...
    'mark_this',[];...
    }; parseargs(varargin,pairs,{},1);



old_var=10e10;
done=0;
thres=1000;
offset=zeros(size(ev));
if do_plot
    clf;ax(1)=axes('Position',[0.1 0.1 0.2 0.2]);
    ax(2)=axes('Position',[0.1 0.1 0.2 0.2]);
    hold on;
end
cnt=1;
inc_t=ones(size(ev))==1;
%% Calculate the mean and ci of the
while ~done
    [y,x]=cdraster(ev+offset,ts(:),val(:),pre,post,binsz);
    y(isnan(y))=0;
    [rowi,coli]=find(abs(y)>max_peak);
    inc_t(unique(rowi))=false;
    % [y x]=maskraster(x,y,pre_mask(ref),post_mask(ref));
    
    ymn = nanmean(y(inc_t,:));
    yst = nanstderr(y(inc_t,:));
    
    if do_plot
        plot_this(ax,x,y,inc_t,offset,save_plot,pre,post,cnt,0,col_axis,col_map,mark_this);
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
        
        if do_plot
            plot_this(ax,x,y,inc_t,offset,save_plot,pre,post,cnt+1,0,col_axis,col_map,mark_this);
        end
    end
    
    
end


function plot_this(ax,x,y,inc_t,offset,save_plot,pre,post,cnt,do_sort,col_axis,col_map,mark_this)
cla(ax(1));
cla(ax(2));

ymn = nanmean(y(inc_t,:));
yst = nanstderr(y(inc_t,:));
if mean(mean(y))<0
    iy=-y;
else
    iy=y;
end

if do_sort
    [so,si]=sort(-offset);
    offset=offset(si);
    inc_t=inc_t(si);
    iy=iy(si,:);
end

imagesc(x,[],iy(inc_t,:),'Parent',ax(1));
set(ax(1), 'Ydir','normal')
hold(ax(1),'on');
caxis(ax(1),col_axis);
colormap(ax(1),col_map);
if cnt==1
    cbh=colorbar('peer',ax(1),'East');
    
    set(cbh,'Position',get(cbh,'Position')-[0.2 0 0 0])
    
end

%   plot(ax,x,ymn-yst,x,ymn+yst,'Color',[1-0.2*cnt, 0 ,0]);
%   plot(ax(2),x,ymn-yst,x,ymn+yst,'Color',[0.2 0.2 0.9],'LineWidth',2);
%   set(ax(1),'YTick',[]);
set(ax,'YTick',[]);
set(ax(2),'Color','none');
set(ax,'XLim', [-pre post],'YLim',[1 sum(inc_t)])
%ylim([0 maxy])
xlabel(ax(2),'Time (s)')
%   ylabel(ax(2),'degrees/sec')
yss=1:sum(inc_t==1);
plot(ax(1),-offset(inc_t),yss(:) ,'w.');
if ~isempty(mark_this)
    plot(ax(1),-offset(inc_t)+mark_this(inc_t), yss(:), 'gx');
end


drawnow
if ~isempty(save_plot)
    saveas(gcf,sprintf('ahv_%s_%d.eps',save_plot,cnt),'epsc2');
end
if cnt==1
    set(cbh, 'Visible','off')
end