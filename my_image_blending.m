function blended_img = my_image_blending(img_bg,...
    img_fg, mask_bg, mask_fg, layers, intermidiate_res)
    % img_bg background iamge
    % img_fg source/ foreground image (small, such as face)
    % mask_bg mask selected upon background image (i.e. face mask)
    % mask_fg mask selected on the foreground image (i.e. face mask)
    % intermidiate_res if True shows intermidiate result

    % automatic alignment of source image to match with background
    [y1, y2, x1, x2] = get_bouding_box(mask_bg);
    [y1_t, y2_t, x1_t, x2_t] = get_bouding_box(mask_fg);
    scale_y = (y2-y1)/(y2_t-y1_t);
    scale_x = (x2-x1)/(x2_t-x1_t);
    % scale the foreground to match size of region of interest (i.e., face
    % size of the two image should be similar)
    [scaled_fg, y1_t, y2_t, x1_t, x2_t] = scale_fg(img_fg,...
        y1_t, y2_t, x1_t, x2_t, scale_y, scale_x);

    bg_h = size(img_bg,1);
    bg_w = size(img_bg,2);
    fg_h = size(scaled_fg,1);
    fg_w = size(scaled_fg,2);

    aligned_fg = zeros(size(img_bg));

    left_align_con = max(x1-x1_t+1, 1);
    left_align_fg = max(x1_t-x1+1, 1);
    top_align_con = max(y1-y1_t+1, 1);
    top_align_fg = max(y1_t-y1+1, 1);
    align_width = min(bg_w-left_align_con+1, fg_w-left_align_fg+1);
    align_height = min(bg_h-top_align_con+1, fg_h-top_align_fg+1);

    aligned_fg(top_align_con:top_align_con+align_height-1,...
        left_align_con:left_align_con+align_width-1,:) = ...
        scaled_fg(top_align_fg:top_align_fg+align_height-1,...
        left_align_fg:left_align_fg+align_width-1,:);
    disp('inter result')

    if intermidiate_res
        figure()
        subplot(2,2,1)
        imagesc(img_bg);
        title("Background")
        subplot(2,2,2)
        imagesc(img_fg);
        title("Foreground")
        subplot(2,2,3)
        imagesc(scaled_fg);
        title("scaled foreground")
        subplot(2,2,4)
        h_con = imagesc(img_bg);
        hold on
        h_fg = imagesc(uint8(aligned_fg));
        alpha(h_con, 0.5)
        alpha(h_fg, 0.5)
        title("aligned 2 iamges")

    end

    figure
    subplot(1,2,1)
    imagesc(img_bg);
    title("Background/ target image")
    axis image
    subplot(1,2,2)
    imagesc(uint8(aligned_fg));
    title("Foreground/ source image")
    axis image

    [pyr_gaussian, pyr_laplacian_con] = compute_pyr(img_bg, layers);
    if intermidiate_res
        disp_pyramid(pyr_gaussian, 'Gaussian Pyramid')
        disp_pyramid(pyr_laplacian_con, 'Laplacian Pyramid')
    end

    [pyr_gaussian, pyr_laplacian_fg] = compute_pyr(aligned_fg, layers);
    if intermidiate_res
        disp_pyramid(pyr_gaussian, 'Gaussian Pyramid')
        disp_pyramid(pyr_laplacian_fg, 'Laplacian Pyramid')
    end
    
    [pyr_gaussian_msk, ~] = compute_pyr(mask_bg, layers);
    if intermidiate_res
        disp_pyramid(pyr_gaussian_msk, 'Gaussian Pyramid of mask',"double")
    end

    layers = length(pyr_gaussian_msk);
    blended_laplacian = {1,layers};

    for i = 1:layers
        blended_laplacian{i} = pyr_laplacian_con{i}.*(1-pyr_gaussian_msk{i})...
            + pyr_laplacian_fg{i}.*pyr_gaussian_msk{i};
    end
    %disp_pyramid(blended_laplacian, 'Laplacian Pyramid')

    blended_img = restore_from_laplacian(blended_laplacian);
    figure()
    imagesc(uint8(blended_img))
    axis image

end

function [topmost_indx,bottommost_indx,leftmost_indx,...
    rightmost_indx] = get_bouding_box(mask)
    im_h = size(mask,1);

    true_index = find(mask);
    true_row_index = mod(true_index, im_h);
    true_col_index = ceil(true_index/im_h);

    leftmost_indx = min(true_col_index);
    rightmost_indx = max(true_col_index);
    topmost_indx = min(true_row_index);
    bottommost_indx = max(true_row_index);
end

function [scaled_fg, y1_t, y2_t, x1_t, x2_t] = scale_fg...
    (fg, y1_t, y2_t, x1_t, x2_t, scale_y, scale_x)
    im_h = size(fg,1);
    im_w = size(fg,2);
    scaled_hw = [floor(im_h*scale_y), floor(im_w*scale_x)];
    scaled_fg = imresize(fg, scaled_hw);
    y1_t = floor(y1_t * scale_y);
    y2_t = floor(y2_t * scale_y);
    x1_t = floor(x1_t * scale_x);
    x2_t = floor(x2_t * scale_x);
end
