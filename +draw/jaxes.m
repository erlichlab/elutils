function ax = jaxes(pos)
if nargin==0
    pos = [0.1 0.1 0.8 0.8];
end
ax=axes('Position',pos,'Box','off','NextPlot','add','TickDir','out','TickLength',[0.025 0.01]); 
