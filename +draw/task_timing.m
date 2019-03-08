function task_timing(statetable, varargin)
% draw.task_timing(statetable)
%  
% names = {   "Start Cue", "Nose in Fixation","Target Cue","Go Sound", "Nose in Target"}';
% start_state = [ 0,   0.15, 0.3, 1.3, 1.65]';
% stop_state =  [ 0.15, 1.5, 1.65, 1.35, 1.8]';
% color = cellfun(@(x)x/255, {[48, 110, 29], [0,0,0], [48, 122, 242], [241, 151, 55],[140,40,93]}, 'UniformOutput',0)';
% 
% T = table(names, start_state, stop_state, color);
% 
% draw.task_timing(T)
%
% % You can adjust the width after using Position
% set(gca,'Position',[0.1 0.1 0.3 0.7])
% saveas(gcf, 'mytask.pdf')


if nargin==0
  names = {"Test State"};
  color = {'r'};
  start_state = 0;
  stop_state = 0.3;
  statetable = table(names, color, start_state, stop_state);
end



clf;
ax = draw.jaxes;
for x = 1:size(statetable,1)
    plot_state(ax,statetable(x,:), -0.2, max(statetable.stop_state)+0.2, 9.5-x)
end

plot(ax,[0 0.5],[x-1 x-1],'k','LineWidth',2);
sh = text(0.1,x-1.5,'0.5 s');
sh.HorizontalAlignment = 'center';

ax.Visible = 'off';
ax.YLim = [-1 10];



end

function [lh, th] = plot_state(ax, row, pre , post, ypos)
startx = row.start_state;
stopx = row.stop_state;
color = row.color{1};
sname = row.names{1};
x = [pre, startx, startx, stopx, stopx, post]; 
y = ypos + [0, 0, 0.6, 0.6, 0, 0];
lh = plot(ax, x,y, 'Color',color,'LineWidth',2);
th = text((pre)/2,ypos + 0.3, sname);
set(th,'Color',color,'HorizontalAlignment','right','FontWeight','bold');



end