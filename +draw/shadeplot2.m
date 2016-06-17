function fhand=shadeplot2(x,y1,y2,varargin)

%
% shadeplot2(x,y1,y2,settings)
%   plots two shaded regions without the use of alpha, this allows the renderer to be
%     set as painters rather than openGL, giving a vector rather than raster image.
%   use shadeplot to quickly view graphs and choose colors, use shadeplot2 for final
%     rendered plot.
%   calls my_shadeplot over and over again onto the same figure to draw each region
%   relies on find_blocks in order to find contiguous regions of overlapping and
%     non-overlapping regions.
%   relies on mydeal to instantiate variables from structure called "options"
%   relies on find_xcross for interpolating between boundaries of overlapping and
%    non-overlapping regions.
% x - x vector
% y1 - 2 by x vector, 1st row contains lower bound, 2nd row contains upper bounds
% y2 - "
% options
%   .colors - 3x3 matrix, each row is an rgb color for y1, y2, and intersection, respectively
%   .fhand  - figure handle to plot into, if not specified creates new one
% 
% Written by Joseph Jun, 09.23.2008
%

pairs={ 'colors'    [0.498*ones(1,3); 0.898*ones(1,3); 0.647*ones(1,3)];...
        'fhand'     [];...
        };
    parseargs(varargin, pairs);
    if isempty(fhand)
    fhand=axes; 
    end
if size(x,1)>size(x,2),   x=x'; end
if size(y1,1)>size(y1,2), y1=y1'; end
if size(y2,1)>size(y2,2), y2=y2'; end

nx=length(x);
isOverlap=true(1,nx); % true whenever bounds overlap

dy.ll=y1(1,:)-y2(1,:); % the four combinations of differences between lower and upper bounds of curve 1 and 2
dy.lh=y1(1,:)-y2(2,:);
dy.hl=y1(2,:)-y2(1,:);
dy.hh=y1(2,:)-y2(2,:);

blocks.non = dy.lh>0 | dy.hl<0;                     % all bins where curves do not overlap
blocks.o12 = dy.hh>0 & dy.lh<0 & dy.ll>0;           % curves overlap with 1 on top
blocks.o21 = dy.hh<0 & dy.hl>0 & dy.ll<0;           % curves overlap with 2 on top
blocks.i12 = dy.hh<=0 & dy.ll>=0;                   % curves overlap with 1 inside of 2
blocks.i21 = dy.hh>=0 & dy.ll<=0;                   % curves overlap with 2 inside of 1

% calculate curves of overlapping regions
% c1 and c2 are 1D vectors that define upper (c2) and lower (c1) bounds of overlapped curves
c2(blocks.o12)=y2(2,blocks.o12); % 1 over 2
c1(blocks.o12)=y1(1,blocks.o12);
c2(blocks.o21)=y1(2,blocks.o21); % 2 over 1
c1(blocks.o21)=y2(1,blocks.o21);
c2(blocks.i12)=y1(2,blocks.i12); % 1 inside 2
c1(blocks.i12)=y1(1,blocks.i12);
c2(blocks.i21)=y2(2,blocks.i21); % 2 inside 1
c1(blocks.i21)=y2(1,blocks.i21);

% fill in non-overlapping points for interpolation of boundaries between blocks
temp=blocks.non & dy.lh>=0;
c1(temp)=y1(1,temp); 
c2(temp)=y2(2,temp);
temp=blocks.non & dy.hl<=0;
c1(temp)=y2(1,temp); 
c2(temp)=y1(2,temp);

hold on;
% -------- first plot y1 then y2 as shade plots
my_shadeplot(x,y1(1,:),y1(2,:),{colors(1,:),fhand,1});
my_shadeplot(x,y2(1,:),y2(2,:),{colors(2,:),fhand,1});
% -------- next plot over the two curves wherever there is an overlap (must be done in blocks)
if sum(~blocks.non)>0
  [b,v]=find_blocks(blocks.non);  % each row of b has where blocks are, v has whether block is overlapping (false) or non (true)
  nb=length(v);
  for k=1:nb
    if ~v(k)
      if sum(b(k,:))>1
        my_shadeplot(x(b(k,:)), c1(b(k,:)),c2(b(k,:)), {colors(3,:),fhand,1}); 
      end
    end
  end
end
% -------- now worry about interpolation inbetween discretization
% ---- first detect any intersection of lines
isll = dy.ll.*[dy.ll(2:end) dy.ll(end)]<0;
islh = dy.lh.*[dy.lh(2:end) dy.lh(end)]<0;
ishl = dy.hl.*[dy.hl(2:end) dy.hl(end)]<0;
ishh = dy.hh.*[dy.hh(2:end) dy.hh(end)]<0;

inds=find(isll | islh | ishl | ishh);
ninds=length(inds);

for k=1:ninds
  il=inds(k);
  ir=inds(k)+1;
  xl=x(il);
  xr=x(ir);
  templateType=0;
  % ---- check to see what kind of overlap exists, create new labeled lines that push
  %        intersections into templates
  if     y1(2,il)<y2(1,il)
    gy=[y1(1,il) y1(1,ir); y1(2,il) y1(2,ir)];
    ry=[y2(1,il) y2(1,ir); y2(2,il) y2(2,ir)];
    templateType=1;
  elseif y2(2,il)<y1(1,il)
    ry=[y1(1,il) y1(1,ir); y1(2,il) y1(2,ir)];
    gy=[y2(1,il) y2(1,ir); y2(2,il) y2(2,ir)];
    templateType=1;
  elseif y1(1,il)>y2(1,il) && y1(1,il)<y2(2,il) && y1(2,il)>y2(2,il)
    gy=[y1(1,il) y1(1,ir); y1(2,il) y1(2,ir)];
    ry=[y2(1,il) y2(1,ir); y2(2,il) y2(2,ir)];
    templateType=2;
  elseif y2(1,il)>y1(1,il) && y2(1,il)<y1(2,il) && y2(2,il)>y1(2,il)
    ry=[y1(1,il) y1(1,ir); y1(2,il) y1(2,ir)];
    gy=[y2(1,il) y2(1,ir); y2(2,il) y2(2,ir)];
    templateType=2;
  elseif y1(1,il)>y2(1,il) && y1(1,il)<y2(2,il) && y1(2,il)>y2(1,il) && y1(2,il)<y2(2,il)
    gy=[y1(1,il) y1(1,ir); y1(2,il) y1(2,ir)];
    ry=[y2(1,il) y2(1,ir); y2(2,il) y2(2,ir)];
    templateType=3;
  elseif y2(1,il)>y1(1,il) && y2(1,il)<y1(2,il) && y2(2,il)>y1(1,il) && y2(2,il)<y1(2,il)
    ry=[y1(1,il) y1(1,ir); y1(2,il) y1(2,ir)];
    gy=[y2(1,il) y2(1,ir); y2(2,il) y2(2,ir)];
    templateType=3;
  end
  
  [xll yll]=calc_xcross([xl xr],gy(1,:),[xl xr],ry(1,:));
  [xlh ylh]=calc_xcross([xl xr],gy(1,:),[xl xr],ry(2,:));
  [xhl yhl]=calc_xcross([xl xr],gy(2,:),[xl xr],ry(1,:));
  [xhh yhh]=calc_xcross([xl xr],gy(2,:),[xl xr],ry(2,:));
 
  if xll<xl || xll>xr, xll=[]; yll=[]; end
  if xlh<xl || xlh>xr, xlh=[]; ylh=[]; end
  if xhl<xl || xhl>xr, xhl=[]; yhl=[]; end
  if xhh<xl || xhh>xr, xhh=[]; yhh=[]; end
  
  switch templateType
    case 1       % case where green is below red and not intersecting
      if isempty(xll)     
        if isempty(xhh), px=[xhl xr xr]; py=[yhl gy(2,2) ry(1,2)];
        else             px=[xhl xhh xr xr]; py=[yhl yhh ry(2,2) ry(1,2)]; 
        end
      else
        if isempty(xhh), px=[xhl xr xr xll]; py=[yhl gy(2,2) gy(1,2) yll];
        else
          if isempty(xlh), px=[xhl xhh xr xr xll]; py=[yhl yhh ry(2,2) ry(1,2) yll];
          else             px=[xhl xhh xlh xll];   py=[yhl yhh ylh yll];
          end
        end
      end
    case 2       % case where green straddles red from below
      if ~isempty(xlh)
        px=[xl xl xlh]; py=[gy(1,1) ry(2,1) ylh];
      else
        if isempty(xll)
          px=[xl xl xhh xr xr]; py=[gy(1,1) ry(2,1) yhh gy(2,2) gy(1,2)];
        else
          if isempty(xhh)
            px=[xl xl xr xr xll]; py=[gy(1,1) ry(2,1) ry(2,2) ry(1,2) yll];
          else
            if isempty(xhl)
              px=[xl xl xhh xr xr xll]; py=[gy(1,1) ry(2,1) yhh gy(2,2) ry(1,2) yll];
            else
              px=[xl xl xhh xhl xll]; py=[gy(1,1) ry(2,1) yhh yhl yll];
            end
          end
        end
      end
    case 3
      if isempty(xhh)
        if isempty(xhl)
          px=[xl xl xr xr xll]; py=[gy(1,1) gy(2,1) gy(2,2) ry(1,2) yll];
        else
          px=[xl xl xhl xll]; py=[gy(1,1) gy(2,1) yhl yll];
        end
      else
        if isempty(xll)
          if isempty(xlh)
            px=[xl xl xhh xr xr]; py=[gy(1,1) gy(2,1) yhh ry(2,2) gy(1,2)];
          else
            px=[xl xl xhh xlh]; py=[gy(1,1) gy(2,1) yhh ylh];
          end
        else
          px=[xl xl xhh xr xr xll]; py=[gy(1,1) gy(2,1) yhh ry(2,2) ry(1,2) yll];
        end
      end
  end
  
  patch(px,py,colors(3,:),'linestyle','none');
  
end


% -------- return a VECTOR graphic hurray!
set(gcf,'renderer','painters');



function h=my_shadeplot(x,y1,y2,opt)
% function h=shadeplot(x,y1,y2,opt)
% you need x, sorry
% y1, y2 can be for example lower and upper confidence intervals.
% opt={color, fighandle, alpha}

if nargin <4
h=axes;
clr='k';
alp=0.5;
else
h=opt{2};
alp=opt{3};
clr=opt{1};
end

y2=y2(:)-y1(:);
y1=y1(:);

Y=[y1, y2];

h1=area(h,x,Y);
set(h1(2),'EdgeColor','none','FaceColor',clr);
if ~isempty(alp), alpha(alp); end
set(h1(1),'EdgeColor','none','FaceColor','none');


function [b,v]=find_blocks(x)

%
% [b,v]=find_blocks(x)
%   x - single dimensional vector, assumed to be row
%   b - boolean matrix containing one row for each discovered block, 
%       and one column for each element of x, true means that element belongs in the block
%

x=x(:)';

nx=length(x);

cval=x(1);
block_beg=1;
nblocks=0;

if isnumeric(x(end)), x(end+1)=x(end)+1;
else                  x(end+1)=~x(end);
end

for k=1:(nx+1)
  if x(k)~=cval
    nblocks=nblocks+1;
    b(nblocks,:)=false(1,nx);
    b(nblocks,block_beg:(k-1))=true;
    block_beg=k;
    v(nblocks)=cval;
    cval=x(k);
  end
end

if block_beg==1, b=true(1,nx); end
v=v';

function [xstar,ystar]=calc_xcross(x,y,u,v)

%
% [xstar,ystar]=calc_xcross(x,y,u,v)
%   calculates where two lines cross and value at meeting point
%   x - 2 element vector, defines x-coord of 1st line
%   y - 2 element vector, defines y-coord of 1st line
%   u - 2 element vector, defines x-coord of 2nd line
%   v - 2 element vector, defines y-coord of 2nd line
%

y0=(y(1)*x(2)-y(2)*x(1))/(x(2)-x(1));
v0=(v(1)*u(2)-v(2)*u(1))/(u(2)-u(1));

a=(y(2)-y(1))/(x(2)-x(1));
b=(v(2)-v(1))/(u(2)-u(1));

xstar=(y0-v0)/(b-a);
ystar=y0+a*xstar;





