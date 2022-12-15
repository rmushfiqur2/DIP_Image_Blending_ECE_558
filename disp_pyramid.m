function disp_pyramid(pyramid, name, data_range)
    if ~exist("data_range", 'var')
        data_range = "uint8";
    end
    layers = length(pyramid);

    % caulculte number of subplots in each row/column
    L = ceil(sqrt(layers));

    H = size(pyramid{1}, 1);
    W = size(pyramid{1}, 2);
    
    figure()
    for i = 1:layers
        subplot(L, L, i)
        img = pyramid{i};
        %img = my_pad(img, H, W, "clip"); % original size
        if data_range=="uint8"
            imshow(uint8(img));
        else
            imshow(img);
        end
    end
    sgtitle(name)
end