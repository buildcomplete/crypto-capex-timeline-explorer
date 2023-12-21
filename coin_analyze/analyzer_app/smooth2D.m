% Function to perform smoothing in 2D replicating border to avoid energy loss at at border
% Created using Bing chat
% The following promts was used
% 1) can I use same, and border_replicate (simmilar to IPP, replicate border)
% 2) can you generalize above with a filter size of N, and using "valid" as shape parameter
% 3) please wrap apove in a function taking two size parameters for smoothing in each dimension
% After this i manually added the normalization (division by N1 and N2)

function C = smooth2D(A, N1, N2)
    % Create the filters
    B1 = ones(N1, 1) / N1;  % Column filter
    B2 = ones(1, N2) / N2;  % Row filter

    % Calculate the padding sizes
    padSize1 = floor(N1/2);
    padSize2 = floor(N2/2);

    % Replicate the borders of A
    A_padded = padarray(A, [padSize1 padSize2], "replicate");

    % Apply conv2
    C1 = conv2(A_padded, B1, 'valid');
    C = conv2(C1, B2, 'valid');
end
