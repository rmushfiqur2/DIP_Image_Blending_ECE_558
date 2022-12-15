function out_img = restore_from_laplacian(lap_pyr)
    % lap_pyr laplacian pyramid
    % out_img resoterd image

    layers = length(lap_pyr);
    out_img = lap_pyr{1};
    
    k = 1; % upsample factor
    for i=2:layers
        k = k * 2;
        out_img = out_img + my_upsample(lap_pyr{i}, k);
    end
end

