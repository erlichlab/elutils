function ax=twodcomp(A,B,varargin)


plot_type='surf';
plot_ax='v';
ax_h=0.2;
ax_w=0.2;
ax_h_off=0.1;
ax_w_off=0.1;
x=1:size(A,2);
y=1:size(A,1);
fig=[];
gap=0.05;
cmin=min([A(:);B(:);B(:)-A(:)]);
cmax=max([A(:);B(:);B(:)-A(:)]);
ax=[];
plot_colorbar=false;

utils.overridedefaults(who,varargin)

if isempty(fig)
    fig=figure;
end

if isempty(ax)
    ax=make_axes(plot_ax,ax_w,ax_h,gap,ax_w_off,ax_h_off);
end


switch plot_type,
    case 'img'
      
                   
        imagesc(x,y,A,'parent',ax(3)); 
        imagesc(x,y,B,'parent',ax(2)); %colorbar('peer',ax(2));
        imagesc(x,y,B-A,'parent',ax(1));%colorbar('peer',ax(3));
        set(ax,'CLim',[cmin,cmax]);
        axis(ax,'xy');
        if plot_colorbar
            pos=get(ax(3),'Position');
            colorbar('peer',ax(3),'Position',[pos(1)+pos(3)+0.01 pos(2) 0.03 pos(4)]);
        end
        case 'surf'
      
                   
        surf(ax(3),x,y,A); 
        surf(ax(2),x,y,B); %colorbar('peer',ax(2));
        surf(ax(1),x,y,B-A);%colorbar('peer',ax(3));
        set(ax,'CLim',[cmin,cmax]);
        axis(ax,'xy');
        if plot_colorbar
            pos=get(ax(3),'Position');
            colorbar('peer',ax(3),'Position',[pos(1)+pos(3)+0.01 pos(2) 0.03 pos(4)]);
        end
    case 'scatter'
        switch style
            case 'plane'
                plot(ax(1),A(:),B(:),'.');
                delete(ax(2));
                delete(ax(3));
                unity(ax(1));
        end

        
end



function ax=make_axes(a,ax_w,ax_h,gap,ax_w_off,ax_h_off)
  if a=='h'
            
        ax(1)=axes('Position',[ax_w_off              ax_h_off ax_w ax_h]);
        ax(2)=axes('Position',[ax_w_off+ax_w+gap     ax_h_off ax_w ax_h]);
        ax(3)=axes('Position',[ax_w_off+2*ax_w+2*gap ax_h_off ax_w ax_h]);
        else
        ax(1)=axes('Position',[ax_w_off ax_h_off              ax_w ax_h]);
        ax(2)=axes('Position',[ax_w_off ax_h_off+ax_h+gap     ax_w ax_h]);
        ax(3)=axes('Position',[ax_w_off ax_h_off+2*ax_h+2*gap ax_w ax_h]);
        
  end