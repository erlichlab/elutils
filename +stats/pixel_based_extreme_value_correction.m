function p_mat = pixel_based_extreme_value_correction(these_ori,these_shuff)
% pixel_based_extreme_value_correction - Performs pixel-wise FWER correction
%   using the maximum-statistic (extreme value) permutation test.
%
% Syntax:
%   p_mat = pixel_based_extreme_value_correction(these_ori, these_shuff)
%
% Inputs:
%   these_ori   - [nX x nY x nPerm] matrix of observed (or per-pixel) test
%                 statistics across permutations for each pixel.
%   these_shuff - [nX x nY x nPerm] matrix of shuffle-based null statistics.
%
% Output:
%   p_mat       - [nX x nY] matrix of familywise-error-corrected p-values.
%
% Method:
%   For each permutation, the maximum statistic across all pixels is used to
%   build a null distribution of extreme values. Each pixel’s observed
%   statistic is then compared against this distribution, yielding
%   strong control of the familywise error rate (FWER) across all pixels.
%
% References:
%   - Nichols & Holmes (2002), Human Brain Mapping, 15(1), 1–25.
%   - Blair & Karniski (1993), Psychophysiology, 30(5), 518–524.
%   - Maris & Oostenveld (2007), J. Neurosci. Methods, 164(1), 177–190.
%
% Example:
%   p_map = pixel_based_extreme_value_correction(obs_stat, shuff_stat);
%
% See also: stats.get_p, fdr_threshold

n_timebin = size(these_ori,1);
p_mat = nan(n_timebin,n_timebin);
   
max_shuffle = max(...
    reshape(these_shuff,[size(these_shuff,1)*size(these_shuff,2),size(these_shuff,3)]) ...
    ,[],1);
for xi = 1:n_timebin
    for yi = 1:n_timebin
        p_mat(xi,yi) = stats.get_p(squeeze(these_ori(xi,yi,:)),max_shuffle,1,1);
    end
end
end
