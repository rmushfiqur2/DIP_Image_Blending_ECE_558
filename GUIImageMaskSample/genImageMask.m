%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GUIImageMaskSample:                                      %
%                                                          %
% Copyright (C) 2013 Masayuki Tanaka. All rights reserved. %
%                    mtanaka@ctrl.titech.ac.jp             %
%                                                          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ maskimage ] = genImageMask( image, mask, color )
m = ( mask > 0 );
m = repmat( m, [1 1 3]);
colimage = reshape( color, [1 1 3] );
colimage = repmat( colimage, [size(mask,1), size(mask,2)] );
maskimage = ( ( 2-m ) .* image + m .* colimage ) / 2;
end

