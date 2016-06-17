function D=psychoheat(x,y,went_right,varargin)

plot_contour=false;
E=[];
nan_val=nan;

overridedefaults(who,varargin);

% Check inputs are the same length
nx=numel(x);
ny=numel(y);
nwr=numel(went_right);
if nx~=ny || nx~=nwr || ny~=nwr
    error('Inputs must be same size')
end

X_R=[x(went_right==1) y(went_right==1)];
X_L=[x(went_right==0) y(went_right==0)];

if isempty(E)
E=linspace(min(x),max(x),20);
end


[N_r,C_r] = hist3(X_R,'Edges',{E E});
[N_l,C_l] = hist3(X_L,'Edges',{E E});

I=(N_r./(N_l+N_r));
% I=smoothn(I,'robust');
% 
% for a=1:size(I,1)
%    for b=1:size(I,2)
%       if E(a)+E(b)>=E(end);
%          I(a,b)=nan;
%       end
%    end
% end

figure
if plot_contour
contourf(E,E,I*100,0:10:100);
else
    II=I;
    II(isnan(I))=nan_val;
    imagesc(E,E,II*100);
    axis xy;
end
D.E=E;
D.I=I;


colormap(gray);
axis equal
xlim([0 30]);

set(gca,'FontSize',16);
ch=get(gca,'Children');
ch2=get(ch,'Children');
set(ch2,'EdgeColor',[0.5 0.5 0.5]);
ylabel('# of Left Clicks')

xlabel('# of Right Clicks')
set(gca,'TickDir','out')
h=colorbar;
axis tight;