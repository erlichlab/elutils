function M_sorted = sort_by_com(M)
    % SORT_BY_COM sorts rows of matrix M based on the center of mass of each row.
    %
    % Input:
    %   M - An N x T matrix
    %
    % Output:
    %   M_sorted - The matrix sorted so that rows with leftmost centers of mass
    %              appear at the top and rightmost at the bottom.

    % Get the number of columns
    T = size(M, 2);

    % Compute the center of mass for each row
    indices = 1:T;  % Column indices
    com = sum(M .* indices, 2) ./ sum(M, 2); % Weighted sum divided by total mass

    % Sort rows based on the center of mass
    [~, sorted_indices] = sort(com, 'ascend'); % Sort in ascending order
    M_sorted = M(sorted_indices, :); % Reorder the matrix
end
