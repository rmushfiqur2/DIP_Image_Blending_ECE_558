clc;
clear;
close all;
addpath("make_mask_fcn_v2_file_exchange/")
addpath("GUIImageMaskSample/")
%% 
im = imread('my_photo.png');

% [pyr_gaussian, pyr_laplacian] = compute_pyr(im, 3);
% disp_pyramid(pyr_gaussian, 'Gaussian Pyramid')
% disp_pyramid(pyr_laplacian, 'Laplacian Pyramid')
% 
% figure()
% img = uint8(restore_from_laplacian(pyr_laplacian));
% 
% d = imagesc(img);
% axis image
im_con = imread('monalisa.png');
D = make_mask_fcn_v2(double(im_con)/255);
uiwait(D.d.fig)
con_mask = mask;

im_tar = imread('my_photo.png');
D = make_mask_fcn_v2(double(im_tar)/255);
uiwait(D.d.fig)
tar_mask = mask;
%GUIImageMaskSample()
% im_con = imread('mona.png');
% con_mask = imread('mona_msk.png')>0;
% im_tar = imread('mushi.png');
% tar_mask = imread('mushi_msk.png')>0;
% im_con = imread('mona.png');

% im_con = imread('monalisa.png');
% con_mask = imread('monalisa_msk.png')>0;
% im_tar = imread('my_photo.png');
% tar_mask = imread('my_photo_msk.png')>0;
tic
my_image_blending(im_con, im_tar, con_mask, tar_mask, 15, false);
toc