
function S = rm_nans(S)
% This is useful since NaNs can't be sent to the DB.
   fnames = fieldnames(S);
   for fx = 1:numel(fnames)
      try
        
        if isnan(S.(fnames{fx}))
          S = rmfield(S,fnames{fx});
        end
      catch me
        % Skip for fields that can't be tested for nan.        
      end
   end
end