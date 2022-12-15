function [padded_f, res] = my_conv2(f, w, pad, shape)
    im_h = size(f,1); % image height
    im_w = size(f,2); % image width
    ker_h = size(w,1); % kernel height
    ker_w = size(w,2); % kernel width

    if shape=="same"
        % combination of ceil and floor ensures the below:
        % padding_left + padding_right = ker_w-1
        padding_left = ceil((ker_w-1)/2);
        padding_right = floor((ker_w-1)/2);
        padding_top = ceil((ker_h-1)/2);
        padding_bottom = floor((ker_h-1)/2);
    elseif shape=="full"
        padding_left = ker_w-1;
        padding_right = ker_w-1;
        padding_top = ker_h-1;
        padding_bottom = ker_h-1;
    elseif shape=="valid"
        padding_left = 0;
        padding_right = 0;
        padding_top = 0;
        padding_bottom = 0;
    else
        error("Invalid padding type provided")
    end

    % number of channels in input image
    layers = 1;
    if length(size(f))>2
        layers = size(f,3);
    end
    padded_f =  zeros(im_h + padding_top + padding_bottom,...
                im_w + padding_left + padding_right, layers);
    res = zeros(size(padded_f,1)-ker_h+1,size(padded_f,2)-ker_w+1,layers);

    for layer=1:layers
        fc = f(:,:,layer); % single channel image

        % placing the center image without padding
        padded_f(padding_top+1:padding_top+im_h, ...
                padding_left+1:padding_left+im_w, layer) = fc;
        if pad == "clip" % clip/zero padding
            % we are good
        elseif pad == "wrap-around"
            % left right top and bottom padding
            padded_f(padding_top+1:padding_top+im_h,1:padding_left,layer) = fc(1:im_h,end-padding_left+1:end);
            padded_f(padding_top+1:padding_top+im_h,end-padding_right+1:end,layer) = fc(1:im_h,1:padding_right);
            padded_f(1:padding_top,padding_left+1:padding_left+im_w,layer) = fc(end-padding_top+1:end,1:im_w);
            padded_f(end-padding_bottom+1:end,padding_left+1:padding_left+im_w,layer) = fc(1:padding_bottom,1:im_w);
            % four corners (left top, left bottom, right top, right bottom)
            padded_f(1:padding_top,1:padding_left,layer) = fc(end-padding_top+1:end,end-padding_left+1:end);
            padded_f(end-padding_bottom+1:end,1:padding_left,layer) = fc(1:padding_bottom,end-padding_left+1:end);
            padded_f(1:padding_top,end-padding_right+1:end,layer) = fc(end-padding_top+1:end,1:padding_right);
            padded_f(end-padding_bottom+1:end,end-padding_right+1:end,layer) = fc(1:padding_bottom,1:padding_right);
        elseif pad == "copy-edge"
            % left right top and bottom padding
            padded_f(padding_top+1:padding_top+im_h,1:padding_left,layer) = repmat(fc(1:im_h,1),1,padding_left);
            padded_f(padding_top+1:padding_top+im_h,end-padding_right+1:end,layer) = repmat(fc(1:im_h,end),1,padding_right);
            padded_f(1:padding_top,padding_left+1:padding_left+im_w,layer) = repmat(fc(1,1:im_w),padding_top,1);
            padded_f(end-padding_bottom+1:end,padding_left+1:padding_left+im_w,layer) = repmat(fc(end,1:im_w),padding_bottom,1);
            % four corners (left top, left bottom, right top, right bottom)
            padded_f(1:padding_top,1:padding_left,layer) = fc(1,1);
            padded_f(end-padding_bottom+1:end,1:padding_left,layer) = fc(end,1);
            padded_f(1:padding_top,end-padding_right+1:end,layer) = fc(1,end);
            padded_f(end-padding_bottom+1:end,end-padding_right+1:end,layer) = fc(end, end);
        elseif pad == "reflect-edge"
            % left right top and bottom padding
            padded_f(padding_top+1:padding_top+im_h,1:padding_left,layer) = fliplr(fc(1:im_h,1:padding_left));
            padded_f(padding_top+1:padding_top+im_h,end-padding_right+1:end,layer) = fliplr(fc(1:im_h,end-padding_right+1:end));
            padded_f(1:padding_top,padding_left+1:padding_left+im_w,layer) = flip(fc(1:padding_top,1:im_w));
            padded_f(end-padding_bottom+1:end,padding_left+1:padding_left+im_w,layer) = flip(fc(end-padding_bottom+1:end,1:im_w));
            % four corners (left top, left bottom, right top, right bottom)
            padded_f(1:padding_top,1:padding_left,layer) = fliplr(flip(fc(1:padding_top,1:padding_left)));
            padded_f(end-padding_bottom+1:end,1:padding_left,layer) = fliplr(flip(fc(end-padding_bottom+1:end,1:padding_left)));
            padded_f(1:padding_top,end-padding_right+1:end,layer) = fliplr(flip(fc(1:padding_top,end-padding_right+1:end)));
            padded_f(end-padding_bottom+1:end,end-padding_right+1:end,layer) = fliplr(flip(fc(end-padding_bottom+1:end,end-padding_right+1:end)));
        else
            error("unsupported padding")
        end
    
        % convolution
        for i = 1:size(res,1) % output height
            for j = 1: size(res,2) % output length
                res(i,j,layer) = sum(w.*padded_f(i:i+ker_h-1,j:j+ker_w-1,layer),'all');
            end
        end
    end
end