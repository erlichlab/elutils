function [ras,R]=exampleraster(ev, ts,varargin)
% EXAMPLERASTER plot rasters and psth for a cell given some events and
% spike times.
%
% [ax_handle,data]=exampleraster(ev, ts, 'pre',1,'krn',0.2)
%
% These are optional arguments with their default values
% 
% pre = iod('pre',3,varargin);
% post = iod('post',3,varargin);
% binsz = iod('binsz',0.01,varargin);
% cnd = iod('cnd',1,varargin);
% meanflg = iod('meanflg',0,varargin);
% krn = iod('krn',0.1,varargin);
% ax_handle = iod('ax_handle',[],varargin);
% legend_str = iod('legend_str','',varargin);
% renderer =iod('renderer','painters',varargin);
% ref_label=iod('ref_label','REF',varargin);
% psth_height=iod('psth_height',0.248,varargin);
% total_height=iod('total_height',0.8,varargin);
% corner=iod('corner',[0.1 0.1],varargin);
% ax_width=iod('ax_width',0.55,varargin);
% font_name=iod('font_name','Helvetica',varargin);
% font_size=iod('font_size',14,varargin);
% legend_pos=iod('legend_pos',[0.73 0.1 0.2 0.15],varargin);
% clrs=iod('clrs',{'b','m','r','c','k','g','y',[1 0.5 0],[0.5 0.5 0.5]},varargin);
% alpha=iod('alpha',0.3,varargin);
% x_label=iod('x_label','',varargin);
% pre_mask=iod('pre_mask', -inf,varargin);
% post_mask=iod('post_mask',+inf,varargin);
% cout=iod('cout',[],varargin);
% stim_back=iod('stim_back',[],varargin);
% sb_clr=iod('sb_clr',[0.8 0.8 0.4],varargin);
% errorbars=iod('errorbars',1,varargin);
% testfunc=iod('testfunc',[],varargin);
% show_yinfo=iod('show_yinfo',1,varargin);
% sortby=iod('sortby',[],varargin);
% xticks=iod('xticks',[],varargin);
% axis_line_width=iod('axis_line_width',.5,varargin);
%

corner=[];  % this is necessary because corner is a function
iod = @utils.inputordefault;
pre = iod('pre',3,varargin);
post = iod('post',3,varargin);
binsz = iod('binsz',0.01,varargin);
cnd = iod('cnd',1,varargin);
meanflg = iod('meanflg',0,varargin);
krn = iod('krn',0.1,varargin);
ax_handle = iod('ax_handle',[],varargin);
legend_str = iod('legend_str','',varargin);
renderer =iod('renderer','painters',varargin);
ref_label=iod('ref_label','REF',varargin);
psth_height=iod('psth_height',0.248,varargin);
total_height=iod('total_height',0.8,varargin);
corner=iod('corner',[0.1 0.1],varargin);
ax_width=iod('ax_width',0.55,varargin);
font_name=iod('font_name','Helvetica',varargin);
font_size=iod('font_size',14,varargin);
legend_pos=iod('legend_pos',[0.73 0.1 0.2 0.15],varargin);
clrs=iod('clrs',{'b','m','r','c','k','g','y',[1 0.5 0],[0.5 0.5 0.5]},varargin);
alpha=iod('alpha',0.3,varargin);
x_label=iod('x_label','',varargin);
pre_mask=iod('pre_mask', -inf,varargin);
post_mask=iod('post_mask',+inf,varargin);
cout=iod('cout',[],varargin);
stim_back=iod('stim_back',[],varargin);
sb_clr=iod('sb_clr',[0.8 0.8 0.4],varargin);
errorbars=iod('errorbars',1,varargin);
testfunc=iod('testfunc',[],varargin);
show_yinfo=iod('show_yinfo',1,varargin);
sortby=iod('sortby',[],varargin);
xticks=iod('xticks',[],varargin);
axis_line_width=iod('axis_line_width',.5,varargin);

set(gcf, 'Renderer',renderer);

% DEMO Mode
if nargin==0
    stats.simulate_spikes()
    return
end

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

if numel(cnd)==1
    cnd=ones(1,ntrials);
end


if iscell(cnd)
    cnd_nan = cellfun(@(x)any(isnan(x)), cnd); % use any to deal with character arrays.
    cnd(cnd_nan) = {'NaN'};
    cnd = categorical(cnd);
    n_cnd = categories(cnd);
else
    cnd = categorical(cnd);
    n_cnd = categories(cnd);
end

raster_height=total_height-psth_height;
y_ind=psth_height+corner(2)+0.005;

height_per_trial=raster_height/ntrials;
psthax=axes('Position',[corner(1) corner(2) ax_width psth_height]);
hold(psthax,'on');
set(psthax,'FontName',font_name);
set(psthax,'FontSize',font_size)



%[Y,x,W]=warpfilter(ev,ts,krn,'pre',pre,'post',post,'kernel_bin_size',binsz);
[Y,x]=stats.spike_filter(ev,ts,krn,'pre',pre,'post',post,'kernel_bin_size',binsz);
W = ts;

for ci=1:numel(n_cnd)
    sampz=sum(cnd==n_cnd(ci));
    
    ref=cnd==n_cnd(ci);
    if ~isempty(sortby)
        idx=1:ntrials; idx=idx(:); ref=ref(:);
        ref=sortrows([sortby(ref) idx(ref)]);
        ref=ref(:,2);
    end
    
    y=Y(ref,:);
    
    [y2,x2]=draw.rasterplot(ev(ref,1),W,pre,post,'pre_mask',pre_mask(ref),'post_mask',post_mask(ref),'plotthis',0);
    ras(ci)=axes('Position',[corner(1) y_ind ax_width height_per_trial*sampz]);
    y_ind=y_ind+height_per_trial*sampz+0.001;
    
    if ~isempty(stim_back)
        patchplot(stim_back(ref,:),'clr',sb_clr)
    end
    
    
    %% Plot the rasters
    ll=line(x2,y2);
    set(ll,'color','k');
    % Instead of gca, we should plot to ras(ci)
    set(ras(ci),'XTickLabel',[]);
    set(ras(ci),'YTick',[]);
    set(ras(ci),'Box','off')
    set(ras(ci),'YLim',[0 max(y2)])
    set(ras(ci),'XLim',[-pre post]);
    set(ras(ci),'LineWidth',axis_line_width)
    
    
    for rx=1:nrefs
        ll=line([mutau(rx) mutau(rx)],[0 max(y2)]);
        set(ll,'LineStyle','-','color',clrs{ci},'LineWidth',1);
    end
    
    if ~isempty(cout)
        hold on;
        h=plot(ras(ci),cout(ref),1:sampz,'o','Color','k','MarkerFaceColor',clrs{ci},'MarkerSize',2);
    end
    %% Calculate the mean and ci of the
    
    [y x]=draw.maskraster(x,y,pre_mask(ref),post_mask(ref));
    
    ymn(ci,:) = nanmean(y,1);
    yst(ci,:)= stats.nanstderr(y,1);
    R{ci}={y x};
    %axes(psthax);
    hold on
    %     hh=line(x/1000,ymn(ci,:));
    % 	set(hh,'LineWidth',1,'LineStyle','-','Color',clrs{ci});
    if strcmpi(renderer,'opengl')
        sh(ci)=draw.shadeplot(x,ymn(ci,:)-yst(ci,:),ymn(ci,:)+yst(ci,:),{clrs{ci},psthax,alpha});
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
    
    
   
    
    legstr{ci}=[n_cnd{ci} ', n=' num2str(sampz)];
    
end

 cur_ylim=get(psthax,'YLim');
 cur_ylim(cur_ylim<0) = 0;% y-axis not going to negative, this is a problem at somewhere else and we will fix that later
 ylim(psthax,[cur_ylim(1) max(peaky)*1.15]);
 
    for rx=1:nrefs
    ll=plot(psthax,[mutau(rx) mutau(rx)],[0 max(peaky*1.15)]);
    set(ll,'LineStyle','-','color',[0.5 0.5 0.5],'LineWidth',1);
    end
    
ch=get(psthax,'Children');
set(psthax,'Children',[ch(nrefs+1:end); ch(1:nrefs)]);

if ~isempty(xticks)
    set(gca,'XTick',xticks);
else
    xticks=get(psthax,'XTick');
end
set(psthax,'XTick',xticks);
set(ras,'XTick',xticks);
set(psthax,'LineWidth',axis_line_width)

if ~isempty(legend_pos) && ~isempty(legend_str)
    [lh,oh]=legend(sh,legend_str);
    %legend boxoff %this code will generate an unexpected legend
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
    set(psthax,'YLabel',[]);
end
ras(end+1)=psthax;
