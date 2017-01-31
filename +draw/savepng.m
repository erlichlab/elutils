function savepng(fighandle,fname,varargin)
% savepng(fighandle, filename, [options])
% Saves a pretty PNG.
%
% Inputs
%
% fighandle 	a figure handle to save
% filename		the full path and filename where it will be saved. 
%
% Optional Inputs [defaults]
%
% dpi 			[180] this is ok for screen, for print should be 450 or 600
% size			[5, 5] 5 x 5 cm is good for a single panel. 



if nargin==0
	help('draw.savepng');
	return;
end


inpd = @utils.inputordefault;

[dpi, varargin] = inpd('dpi', 180, varargin);
[XMARGIN, varargin] = inpd('x_margin', 1.2, varargin);
[YMARGIN, varargin] = inpd('y_margin', 1, varargin);
[fsize, varargin] = inpd('size', [5,4], varargin);


if ~isempty(varargin)
	fprintf(2,'Did not process the following inputs:\n');
	fprintf(2,'%s: %s\n',varargin{1:end});
end

%% Fix margins.
% In order for the margins to work well, we need to make sure there is
% enough space aroung the edge of all the axes.



fighandle.Units = 'centimeters';

set(fighandle.Children, 'Units','normalized');
figpos = fighandle.Position;
fighandle.Position = [figpos(1:2) fsize + [2*XMARGIN, 2*YMARGIN]];
% 
% ch = get(fighandle, 'Children');
% axpos = nan(numel(ch), 4);
% shiftx = 0;
% shifty = 0;
% for cx = 1:numel(ch)
%     if isprop(ch(cx),'Type') && strcmp('axes',ch(cx).Type)
%        ch(cx).Units = 'centimeters';
%        pos = ch(cx).Position;
%        shiftx = max(shiftx, XMARGIN-pos(1));
%        shifty = max(shifty, YMARGIN-pos(2));
%     end
% end
% 
% fighandle.Position = fighandle.Position + [0, 0, shiftx, shifty];
% 
% for cx = 1:numel(ch)
%     if isprop(ch(cx),'Type') && strcmp('axes',ch(cx).Type)
%        ch(cx).Position = ch(cx).Position + [shiftx, shifty, 0, 0];
%      end
% end
% 


fighandle.PaperUnits = 'centimeters';
fighandle.PaperPosition = [0.5 0.5 fsize*1.5];

fighandle.PaperSize = fsize*1.8;

print(fighandle,'-dpng',sprintf('-r%d',dpi),fname)
fighandle.Position = figpos;
	