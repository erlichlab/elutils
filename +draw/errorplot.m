function h=errorplot(varargin)

% h=errorplot(x,y,e, options)
% h=errorplot(x,y,u,l,options)
% h=errorplot(ax, .....)

toparse=nargin;

if isscalar(varargin{1}) && ishandle(varargin{1})
	ax=varargin{1};
	varargin=varargin(2:end);
	toparse=toparse-1;
else
	figure;
	ax=axes;
end

axes(ax);
x=varargin{1};
y=varargin{2};
u=varargin{3};


toparse=toparse-3;
if toparse>0
	varargin=varargin(4:end);
	if isnumeric(varargin{1})
		l=varargin{1};
		toparse=toparse-1;
		
		if toparse>0
			varargin=varargin(2:end);
        else
            varargin={};
        end
	else
		l=u;
	end
else
	l=u;
	varargin={};
end


pairs={'LineStyle','none';...
	   'Marker','.';...
	   'Color', 'k';...
       'LineWidth',1};
   
parseargs(varargin, pairs);



X=[x(:) x(:) ones(numel(x),1)+nan];
Y=[y(:)-l(:) y(:)+u(:) ones(numel(x),1)+nan];
X=reshape(X', numel(X), 1);
Y=reshape(Y', numel(Y), 1);

h(1)=line(X,Y);
set(h(1), 'Color', Color);

h(2)=line(x,y);

set(h(2), 'LineStyle', LineStyle);
set(h(2), 'Marker', Marker);
set(h(2), 'Color', Color);
set(h(2),'LineWidth', LineWidth);

