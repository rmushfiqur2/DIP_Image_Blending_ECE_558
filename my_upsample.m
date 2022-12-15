function out_img = my_upsample(img, k)

    % img RGB or gray image
    % k integer upsample factor

    im_h = size(img,1);
    im_w = size(img,2);

    layers = 1;
    if length(size(img))>2
        layers = size(img,3); % i.e. RGB image
    end

    out_img = zeros(im_h*k, im_w*k, layers);

    for layer = 1: layers
        out_img(:,:,layer) = kron(img(:,:,layer),ones(k));
    end
end

