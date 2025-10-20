function p_threshold = fdr_threshold(p_values, alpha)
    % fdr_threshold - Calculates the Benjamini-Hochberg p-value threshold
    %
    % Inputs:
    %   p_values - A column vector, matrix, or 3D array of p-values
    %   alpha - Desired FDR level (e.g., 0.05)
    %
    % Output:
    %   p_threshold - The p-value threshold for significance
    %                 (scalar for vector input, vector for matrix input, or
    %                 1 x size(p_values, 3) vector for 3D input)

    if ndims(p_values) == 3
        % Handle 3D input
        n_slices = size(p_values, 3); % Number of independent datasets in the 3rd dimension
        p_threshold = arrayfun(@(slice) ...
            stats.fdr_threshold(reshape(p_values(:, :, slice), [], 1), alpha), 1:n_slices);
    elseif size(p_values, 2) > 1
        % Handle 2D matrix input
        n_datasets = size(p_values, 2);
        p_threshold = arrayfun(@(col) stats.fdr_threshold(p_values(:, col), alpha), 1:n_datasets);
    else
        % Handle vector input
        % Remove NaN values
        valid_p_values = p_values(~isnan(p_values));

        if isempty(valid_p_values)
            % If no valid p-values, return NaN
            p_threshold = NaN;
            return;
        end

        % Sort p-values in ascending order
        sorted_p = sort(valid_p_values(:)); % Ensure it's a column vector
        n = length(sorted_p); % Total number of tests

        % Calculate the FDR thresholds
        thresholds = (1:n)' / n * alpha;

        % Find the largest p-value that satisfies p <= threshold
        significant_idx = find(sorted_p <= thresholds, 1, 'last');

        if isempty(significant_idx)
            % No p-value passes the FDR threshold
            p_threshold = NaN;
        else
            % p-value threshold is the p-value at the last significant index
            p_threshold = sorted_p(significant_idx);
        end
    end
end