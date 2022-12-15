function padded_img = my_pad(img, new_height, new_width, pad)
    
    im_h = size(img,1);
    im_w = size(img,2);

    layers = 1;
    if length(size(img))>2
        layers = size(img,3); % i.e. RGB image
    end

    assert(new_height >= im_h);
    assert(new_width >= im_w);

    padding_top = floor((new_height - im_h)/2);
    padding_left = floor((new_width - im_w)/2);
    padding_bottom = new_height - im_h - padding_top;
    padding_right = new_width - im_w - padding_left;

    padded_img = zeros(new_height, new_width, layers);
    for layer=1:layers
        fc = img(:,:,layer); % single channel image
        padded_img(padding_top+1:padding_top+im_h, ...
                padding_left+1:padding_left+im_w, layer) = fc;
        if pad == "clip" % clip/zero padding
            % we are good
        elseif pad == "copy-edge"
            % left right top and bottom padding
            padded_img(padding_top+1:padding_top+im_h,1:padding_left,layer) = repmat(fc(1:im_h,1),1,padding_left);
            padded_img(padding_top+1:padding_top+im_h,end-padding_right+1:end,layer) = repmat(fc(1:im_h,end),1,padding_right);
            padded_img(1:padding_top,padding_left+1:padding_left+im_w,layer) = repmat(fc(1,1:im_w),padding_top,1);
            padded_img(end-padding_bottom+1:end,padding_left+1:padding_left+im_w,layer) = repmat(fc(end,1:im_w),padding_bottom,1);
            % four corners (left top, left bottom, right top, right bottom)
            padded_img(1:padding_top,1:padding_left,layer) = fc(1,1);
            padded_img(end-padding_bottom+1:end,1:padding_left,layer) = fc(end,1);
            padded_img(1:padding_top,end-padding_right+1:end,layer) = fc(1,end);
            padded_img(end-padding_bottom+1:end,end-padding_right+1:end,layer) = fc(end, end);
        end
    end      
end