function [r_start, r_end] = batch_indexer(r, n_batches)
    % r - n_rows
    % n_cpu - n_batches
    n_in_batch = floor(r / n_batches);
    r_end = n_in_batch * (1:(n_batches - 1));
    r_start = [1 r_end + 1];
    r_end = [r_end r];
end