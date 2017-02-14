% [X Y E]= isosum_psycho(x1,x2,wr,varargin)
% A function to plot psychometrics with isosum lines.


function [X Y E bfit bci]= isosum_psycho(x1,x2,wr,varargin)

nsumbins=5;
sum_bin_e=[];
x_bin_e=[];
nxbins=6;
ax=[];
plot_it=true;
clrs=[.85  0  0;
      0 .1 .8; 
      0 .8 .1;   
      .8  0  1;
       1 .5  0; 
       0  0  0;
       ];
   
fit=false;
mod=@erf3;
beta=[0 1 0.5];
model_marker_size=0.3;
data_marker_size=2;



utils.overridedefaults(who,varargin);
if isempty(ax) && plot_it
    ax=axes;
end

if isempty(clrs)
    clrs=clrs(1:nsumbins,:) ;
end

sumx=x1+x2;
diffx=x2-x1;

if isempty(sum_bin_e)
    pbins=linspace(0,100,nsumbins+1);
    sum_bin_e=prctile(sumx,pbins);
end

if isempty(x_bin_e)
    pbins=linspace(0,100,nxbins+1);
    x_bin_e=prctile(diffx,pbins);
end

Y=nan(nsumbins,nxbins);
E=Y;
X=Y;

set(ax,'NextPlot','add');


if fit
    [bfit,resid,J,Sigma]=nlinfit([x1 x2],wr,mod,beta);
    bci=nlparci(bfit,resid,'covar',Sigma);
    [ll,bb]=loglikelihood(mod(bfit,[x1 x2]),wr,numel(beta));
    fprintf('The BIC is %0.2f\n',bb);
    fprintf('The -LL is %0.2f\n',-ll);

else
    bfit=0;
    bci=[0 0];
end



for sx=1:nsumbins
    gt=sumx>=sum_bin_e(sx) & sumx<sum_bin_e(sx+1);
    dc=diffx(gt);
    x_bin_e=prctile(dc,pbins);
    [X(sx,:) Y(sx,:) E(sx,:)]=binned(dc,wr(gt),'bin_e',x_bin_e);
    if plot_it
        if fit
            mp=plot(ax,dc,mod(bfit,[x1(gt) x2(gt)]),'.','Color',(clrs(sx,:)+1)/2);
            set(mp,'MarkerSize',model_marker_size);
        end
        he=draw.errorplot(ax,X(sx,:)+0.2*sx,Y(sx,:), E(sx,:),'Color',clrs(sx,:),'Marker','o');
        set(he(2),'MarkerFaceColor',clrs(sx,:),'MarkerSize',data_marker_size);

        
    end
end
if fit
ch=get(ax,'Children');
mch=findobj(ch,'Marker','.');
cdh=setdiff(ch,mch);
set(ax,'Children',[cdh; mch]);
end


function y=erf2(b,x)

lapse=b(1);
gain=b(2);

ipsC=x(:,1);
conC=x(:,2);
inp=gain*(conC-ipsC)./(ipsC+conC).^0.5;
y=lapse + (1-2*lapse)*(0.5*(erf(inp)+1));




function y=erf3(b,x)

lapse=b(1);
gain=b(2);
noise=b(3);

ipsC=x(:,1);
conC=x(:,2);
inp=gain*(conC-ipsC)./(ipsC+conC).^noise;
y=lapse + (1-2*lapse)*(0.5*(erf(inp)+1));


