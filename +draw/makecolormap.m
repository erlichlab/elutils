function C = makecolormap(colors,varargin)

if nargin==1
    spacing = ones(size(colors,1)-1,1);
else
    spacing = varargin{1};
end


nsteps = 100/sum(spacing);

C = nan(100,3);
endind=0;
for sx = 1:numel(spacing)
    startind = endind+1;
    endind = nsteps*spacing(sx)+startind-1;
    for cx = 1:3
    C(startind:endind,cx) = linspace(colors(sx,cx),colors(sx+1,cx),nsteps*spacing(sx));
    end
end
