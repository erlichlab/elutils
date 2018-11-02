function ax = plot_poke_wall(varargin)

    iod = @utils.inputordefault;
    [ax, varargin] = iod('ax',[],varargin);
    marker = iod('Marker','o',varargin);
    MarkerSize = iod('MarkerSize',10,varargin);
    
    
    row_height = 0.8;
    x = [-2 -1 -1  0 0 1  1 2];
    y = [0   row_height -row_height -row_height*1.5 0 row_height -row_height 0];
    
    if isempty(ax)
        ax = draw.jaxes();
    end
    ax.Visible = 'off';
    h = plot(ax, x,y);    
    h.Marker = marker;
    h.LineStyle = 'none';
    h.MarkerSize = MarkerSize;
    keyboard
end
