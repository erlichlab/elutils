function ht=x_tick_helper(ax,xloc,xtext,varargin)
% ht=x_tick_helper(ax,xloc,xtext,['rot' degrees])
%
% Function to add vertical or angled x tick labels

rot=90;

overridedefaults(who,varargin);

if rot==0
    vert_a='top';
    horz_a='center';
else
    vert_a='middle';
    horz_a='left';
end
    
axes(ax);
curr_tick=get(ax,'XTick');
y_lim=ylim(ax);
y=y_lim(1)-0.08*range(y_lim);
ht=zeros(size(xloc));
keeps=ht==1;
for tx=1:numel(ht)
    if ~isempty(xtext{tx})
    ht(tx)=text(xloc(tx),y,[xtext{tx}]);
    keeps(tx)=1;
    end
end

kxloc=xloc(keeps);
new_tick=sort([kxloc(:); curr_tick(:)]);


set(ax,'XTick',new_tick','XTickLabel',[]);

ht=ht(keeps);

set(ht,'Rotation',rot,'VerticalAlignment',vert_a,'HorizontalAlignment',horz_a);
% set(ax,'Units','points');



