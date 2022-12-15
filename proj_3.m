clc;
clear;
close all;
addpath("make_mask_fcn_v2_file_exchange/") % option 1
addpath("GUIImageMaskSample/") % option 2

%% 
im = imread('ex1/my_photo.png');

[pyr_gaussian, pyr_laplacian] = compute_pyr(im, 3);
disp_pyramid(pyr_gaussian, 'Gaussian Pyramid')
disp_pyramid(pyr_laplacian, 'Laplacian Pyramid')

img = uint8(restore_from_laplacian(pyr_laplacian));
imshow(img)
%% 

% for large size images (1000 x 1500), the mask generation function
% make_mask_fcn_v2 sometimes haults in my machine. If this occurs, please
% use the alternative mask generation function (marked as option 2: alternative)

% optipon 1 (more freedon, many freestyle drawing, but uses more memory)
im_con = imread('ex1/monalisa.png');
D = make_mask_fcn_v2(double(im_con)/255);
uiwait(D.d.fig)
con_mask = mask;
close(D.d.fig)

im_tar = imread('ex1/my_photo.png');
D = make_mask_fcn_v2(double(im_tar)/255);
uiwait(D.d.fig)
tar_mask = mask;
close(D.d.fig)

optipon 2 (alternative) use this if option 1 seems to be slow
GUIImageMaskSample() % and then browse image -> draw mask and hit save
im_con = imread('ex1/monalisa.png');
con_mask = imread('ex1/monalisa_msk.png')>0;
im_tar = imread('ex1/my_photo.png');
tar_mask = imread('ex1/my_photo_msk.png')>0;
im_con = imread('mona.png');

tic
my_image_blending(im_con, im_tar, con_mask, tar_mask, 15, true);
toc

%% 
im_con = imread('ex2/messi.jpeg');
D = make_mask_fcn_v2(double(im_con)/255);
uiwait(D.d.fig)
con_mask = mask;

im_tar = imread('ex2/ronaldo.jpeg');
D = make_mask_fcn_v2(double(im_tar)/255);
uiwait(D.d.fig)
tar_mask = mask;

tic
my_image_blending(im_con, im_tar, con_mask, tar_mask, 15, false);
toc


%% 
im_con = imread('ex3/kohli.png');
D = make_mask_fcn_v2(double(im_con)/255);
uiwait(D.d.fig)
con_mask = mask;

im_tar = imread('ex3/rugbi.png');
D = make_mask_fcn_v2(double(im_tar)/255);
uiwait(D.d.fig)
tar_mask = mask;

tic
my_image_blending(im_con, im_tar, con_mask, tar_mask, 15, tr);
toc