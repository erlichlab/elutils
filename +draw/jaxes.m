function ax = jaxes(pos)
if nargin==0
    pos = [0.15 0.15 0.75 0.75];
end
ax=axes('Position',pos,'Box','off','NextPlot','add','TickDir','out','TickLength',[0.018 0.01]); 
