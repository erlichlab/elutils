function [H, bits] = norm_entropy(data,varargin)
% This returns the normalized entropy for discrete data 
% Works on 1D data.

if min(size(data))>1
    error('operated on 1-D input')
end


ent_type = utils.inputordefault('ent_type','shannon',varargin);
alpha = utils.inputordefault('alpha',5,varargin);


ud = unique(data);
P = 0;
n_samp = numel(data);

if iscell(data)
    datacat = categorical(data, ud);
    data = datacat;
end

switch ent_type
    case 'shannon'
        for ux = 1:numel(ud)
            tmpP = sum(data == ud(ux))/n_samp;
            P = P + tmpP .* log2(tmpP);
        end
        H = -P / log2(numel(ud));
        bits = -P;
    case 'renyi'
        Palpha = 0;
        for ux = 1:numel(ud)
            tmpP = sum(data == ud(ux))/n_samp;
            P = P + tmpP;
            Palpha = Palpha + tmpP.^alpha;
        end
        
        H = 1/(1-alpha) * log2(Palpha/P) / log2(numel(ud));
        bits = 1/(1-alpha) * log2(Palpha/P);
        
otherwise
    error('norm_entropy','do not know how to calculate %s',ent_type)
end


