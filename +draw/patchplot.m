function h=patchplot(X,varargin)
% Take an n x 2 matrix X and plots bar on the ith row on a figure that goes
% from X(i,1) to X(i,2)

opts.clr=[1 1 .6];
opts.y_s=[];


parseargs(varargin,opts,[],1);

if isempty(y_s)
    y_s=1:size(X,1);
end

for rx=1:size(X,1)
    xM(rx,:)=[X(rx,1), X(rx,1), X(rx,2), X(rx,2) X(rx,1)];
    yM(rx,:)=[y_s(rx)-1 y_s(rx) y_s(rx) y_s(rx)-1 y_s(rx)-1];
end

yM=yM';
xM=xM';
h=patch(xM,yM,clr);
set(h,'LineStyle','none');

    
