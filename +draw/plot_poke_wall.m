function [ax,x,y,names] = plot_poke_wall(varargin)

    iod = @utils.inputordefault;
    [ax, varargin] = iod('ax',[],varargin);
    marker = iod('Marker','s',varargin);
    MarkerSize = iod('MarkerSize',50,varargin); 
    
    
    row_height = 0.8;
    x = [2 1 1  0  -1  -1 -2 0];
    y = [0 row_height -row_height  0 row_height -row_height 0 -row_height*1.5];
    names = getPokeList();
    
    if isempty(ax)
        ax = draw.jaxes();
    end
    ax.Visible = 'off';
    h = plot(ax, x,y);    
    h.Marker = marker;
    h.LineStyle = 'none';
    h.MarkerSize = MarkerSize;
    h.Color = 'k';
    
end
