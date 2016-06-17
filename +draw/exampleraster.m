function [ras,R]=exampleraster(ev, ts,varargin)
% [ax_handle,data]=rasterC(ev, ts, varargin)
% pairs={'pre'        3;...
%        'post'       3;...
%        'binsz'      0.050;...
%        'cnd'        1;...
%        'meanflg'    0;...
%        'krn'        0.25;...
%        'ax_handle'  [];...
%        'legend_str' '';...
%        'renderer', 'opengl';...
%        'ref_label', 'REF';...
%        'psth_height', 0.248;...
%        'total_height' 0.8;...
%        'corner'       [0.1 0.1];...
%        'ax_width'      0.55;...
% 	   'font_name'	   'Helvetica';...
% 	   'font_size'		9;...
% 	   'legend_pos'     [0.73 0.1 0.2 0.15];...
% 	   'clrs'	{'c','b','r','m','r','g','m'};...
% 	   'x_label','';...
%     'pre_mask', -inf;...
%     'post_mask',+inf;...
%     'cout',[];...
%     'stim_back',[];...
%     'errorbars', 0;...
%     'testfunc', [];...
%     'sortby', [];...
%

corner=[];  % this is necessary because corner is a function
pairs={'pre'        3;...
    'post'       3;...
    'binsz'      0.01;...
    'cnd'        1;...
    'meanflg'    0;...
    'krn'        0.1;...
    'ax_handle'  [];...
    'legend_str' '';...
    'renderer', 'painters';...
    'ref_label', 'REF';...
    'psth_height', 0.248;...
    'total_height' 0.8;...
    'corner'       [0.1 0.1];...
    'ax_width'      0.55;...
    'font_name'	   'Helvetica';...
    'font_size'		14;...
    'legend_pos'     [0.73 0.1 0.2 0.15];...
    'clrs'	{'b','m','r','c','k','g','y',[1 0.5 0],[0.5 0.5 0.5]};...
    'x_label','';...
    'pre_mask', -inf;...
    'post_mask',+inf;...
    'cout',[];...
    'stim_back',[];...
    'sb_clr',[0.8 0.8 0.4];...
    'errorbars', 1;...
    'testfunc', [];...
    'show_yinfo', 1;...
    'sortby', [];
    }; parseargs(varargin,pairs,{},1);


set(gcf, 'Renderer',renderer);
[ntrials,nrefs]=size(ev);


mutau=zeros(1,nrefs);
for rx=2:nrefs
    mutau(rx)=nanmedian(ev(:,rx)-ev(:,1));
end

if isscalar(pre_mask)
    pre_mask=zeros(1,ntrials)+pre_mask;
elseif numel(pre_mask)~=ntrials
    fprintf(1,'numel(pre_mask) must equal num ref events or be scalar');
    return;
end


if isscalar(post_mask)
    post_mask=zeros(1,ntrials)+post_mask;
elseif numel(post_mask)~=ntrials
    fprintf(1,'numel(post_mask) must equal num ref events or be scalar');
    return;
end

if isscalar(krn)
    dx=ceil(5*krn);
    kx=-dx:binsz:dx;
    krn=normpdf(kx,0, krn);
	if isempty(find(kx==0, 1))
		error('Your binsz needs to divide 1 second into interger # of bins');
	end
    krn(kx<0)=0;
    krn=krn/sum(krn);
end



n_cnd=unique(cnd(~isnan(cnd)));
raster_height=total_height-psth_height;
y_ind=psth_height+corner(2)+0.005;

height_per_trial=raster_height/ntrials;
psthax=axes('Position',[corner(1) corner(2) ax_width psth_height]);
hold(psthax,'on');
set(psthax,'FontName',font_name);
set(psthax,'FontSize',font_size)

if numel(cnd)==1
    cnd=ones(1,ntrials);
end


[Y,x,W]=warpfilter(ev,ts,krn,'pre',pre,'post',post,'kernel_bin_size',binsz);


for ci=1:numel(n_cnd)
    sampz=sum(cnd==n_cnd(ci));
    
    ref=cnd==n_cnd(ci);
    if ~isempty(sortby)
        idx=1:ntrials; idx=idx(:); ref=ref(:);
        ref=sortrows([sortby(ref) idx(ref)]);
        ref=ref(:,2);
    end
    
    y=Y(ref,:);
    
    [y2,x2]=rasterplot(ev(ref,1),W,pre,post,'pre_mask',pre_mask(ref),'post_mask',post_mask(ref),'plotthis',0);
    ras(ci)=axes('Position',[corner(1) y_ind ax_width height_per_trial*sampz]);
    y_ind=y_ind+height_per_trial*sampz+0.001;
    
    if ~isempty(stim_back)
        patchplot(stim_back(ref,:),'clr',sb_clr)
    end
    
    
    %% Plot the rasters
    ll=line(x2,y2);
    set(ll,'color','k');
    set(gca,'XTickLabel',[]);
    set(gca,'YTick',[]);
    set(gca,'Box','off')
    set(gca,'YLim',[0 max(y2)])
    set(gca,'XLim',[-pre post]);
    
    
    for rx=1:nrefs
    ll=line([mutau(rx) mutau(rx)],[0 max(y2)]);
    set(ll,'LineStyle','-','color',clrs{ci},'LineWidth',1);
    end
    
    if ~isempty(cout)
        hold on;
        h=plot(ras(ci),cout(ref),1:sampz,'o','Color','k','MarkerFaceColor',clrs{ci},'MarkerSize',2);
    end
    %% Calculate the mean and ci of the
    
    [y x]=maskraster(x,y,pre_mask(ref),post_mask(ref));
    
    ymn(ci,:) = nanmean(y,1);
    yst(ci,:)= nanstderr(y,1);
    R{ci}={y x};
    %axes(psthax);
    hold on
    %     hh=line(x/1000,ymn(ci,:));
    % 	set(hh,'LineWidth',1,'LineStyle','-','Color',clrs{ci});
    if strcmpi(renderer,'opengl')
        sh(ci)=shadeplot(x,ymn(ci,:)-yst(ci,:),ymn(ci,:)+yst(ci,:),{clrs{ci},psthax,0.3});
        % lh=line(x,ymn(ci,:),'Color',clrs{ci},'LineWidth',2);
    else
        if errorbars
            hh(1)=line(x,ymn(ci,:)-yst(ci,:),'Parent',psthax);
            hh(2)=line(x,ymn(ci,:)+yst(ci,:),'Parent',psthax);
            set(hh,'LineWidth',1,'LineStyle','-','Color',clrs{ci});
            %lh=line(x,ymn(ci,:),'Color',clrs{ci},'LineWidth',1,'Parent',psthax);
            lh=hh(1);
            sh(ci)=lh;
        else
            hh(1)=line(x,ymn(ci,:),'Parent',psthax);
            set(hh,'LineWidth',2,'LineStyle','-','Color',clrs{ci});
            %lh=line(x,ymn(ci,:),'Color',clrs{ci},'LineWidth',1,'Parent',psthax);
            lh=hh(1);
            sh(ci)=lh;
        end
            
    end
    peaky(ci)=max(ymn(ci,:)+yst(ci,:));
       
    set(psthax,'XLim',[-pre,post]);
    
    
   
    
    legstr{ci}=[num2str(n_cnd(ci)) ', n=' num2str(sampz)];
    
end

 cur_ylim=get(psthax,'YLim');
 ylim(psthax,[cur_ylim(1) max(peaky)*1.15]);
 
    for rx=1:nrefs
    ll=plot(psthax,[mutau(rx) mutau(rx)],[0 max(peaky*1.15)]);
    set(ll,'LineStyle','-','color',[0.5 0.5 0.5],'LineWidth',1);
    end
    
ch=get(psthax,'Children');
set(psthax,'Children',[ch(nrefs+1:end); ch(1:nrefs)]);


xticks=get(psthax,'XTick');
set(psthax,'XTick',xticks);
set(ras,'XTick',xticks);

if ~isempty(legend_pos) && ~isempty(legend_str)
[lh,oh]=legend(sh,legend_str);
legend boxoff
% keyboard
set(lh,'Position',legend_pos);
end

hold off
%set(gca,'FontSize',36);
if isempty(x_label)
    xh=xlabel(psthax,['Time from ' ref_label '(sec)']); set(xh,'interpreter','none');
else
    xh=xlabel(psthax,x_label);set(xh,'interpreter','none');
end
if show_yinfo
ylabel(psthax,'Hz \pm SE')
else
    set(psthax,'YTick',[]);
end
ras(end+1)=psthax;
