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
% dpi 			[450] this is generally high enough to look good
% size			[5, 5] 5 x 5 cm is good for a single panel. 



if nargin==0
	help('draw.savepng');
	return;
end

inpd = @utils.inputordefault;

[dpi, varargin] = inpd('dpi', 400, varargin);
[fsize, varargin] = inpd('size', [5,4], varargin);

if ~isempty(varargin)
	fprintf(2,'Did not process the following inputs:\n');
	fprintf(2,'%s: %s\n',varargin{1:end});
end

fighandle.PaperUnits = 'centimeters';
fighandle.PaperPosition = [0.25 0.25 fsize];

print(fighandle,'-dpng',sprintf('-r%d',dpi),fname)

	