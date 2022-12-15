%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GUIImageMaskSample:                                      %
%                                                          %
% Copyright (C) 2013 Masayuki Tanaka. All rights reserved. %
%                    mtanaka@ctrl.titech.ac.jp             %
%                                                          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [] = GUIImageMaskSample()

%%%%% initialization %%%%%
global img;
global msk;
global mskcol;
global wbmFlg;
global point0;
global drawFlg;
global pnSize;
global imSize;
global viewMode;

img = [];
msk = [];
mskcol = [255 0 0];
wbmFlg = 0;
point0 = [];
drawFlg = -1;
imSize = [];
pnSize = 5;
viewMode = 1;

%%%%% GUI components %%%%%%
S.fig = figure('units','pixels',...
               'position',[100, 100, 480+40, 640],...
               'menubar','none',...
               'numbertitle','off',...
               'name','GUIImageMaskSample',...
               'resize','off');
bColor = get(S.fig, 'color');
          
S.img = axes('units','pixels',...
             'position',[20 150 480 480]);
set(S.img,'xtick',[],'ytick',[])  %Set ticks off          

h = ( 480+40 - 80*2 ) / 3;

S.load = uicontrol('style','push',...
                  'units','pixels',...
                  'position',[h 50 80 30],...
                  'fontsize',14,...
                  'string','LOAD');

S.save = uicontrol('style','push',...
                  'units','pixels',...
                  'position',[2*h+80 50 80 30],...
                  'fontsize',14,...
                  'string','SAVE');

S.LabelMskCol = ...
    uicontrol('style','text',...
                  'units','pixels',...
                  'position',[20 100 80 15],...
                  'fontsize',10,...
                  'backgroundcolor',bColor,...
                  'string','Mask Color');

S.EditR = uicontrol('style','edit',...
                 'unit','pix',...
                 'position',[110 100 30 15],...
                 'fontsize',10,...
                 'string',num2str(mskcol(1)));
S.EditG = uicontrol('style','edit',...
                 'unit','pix',...
                 'position',[150 100 30 15],...
                 'fontsize',10,...
                 'string',num2str(mskcol(2)));
S.EditB = uicontrol('style','edit',...
                 'unit','pix',...
                 'position',[190 100 30 15],...
                 'fontsize',10,...
                 'string',num2str(mskcol(3)));

S.LabelR = ...
    uicontrol('style','text',...
                  'units','pixels',...
                  'position',[110 115 30 15],...
                  'fontsize',10,...
                  'backgroundcolor',bColor,...
                  'string','R');
S.LabelG = ...
    uicontrol('style','text',...
                  'units','pixels',...
                  'position',[150 115 30 15],...
                  'fontsize',10,...
                  'backgroundcolor',bColor,...
                  'string','G');
S.LabelB = ...
    uicontrol('style','text',...
                  'units','pixels',...
                  'position',[190 115 30 15],...
                  'fontsize',10,...
                  'backgroundcolor',bColor,...
                  'string','B');

S.LabelPS = ...
    uicontrol('style','text',...
                  'units','pixels',...
                  'position',[230 100 80 15],...
                  'fontsize',10,...
                  'backgroundcolor',bColor,...
                  'string','Pen Size:');

S.EditPS = uicontrol('style','edit',...
                 'unit','pix',...
                 'position',[310 100 30 15],...
                 'fontsize',10,...
                 'string',num2str(pnSize));

S.PopView = uicontrol('style','pop',...
                 'unit','pix',...
                 'position',[380 100 100 15],...
                 'fontsize',10,... 
                 'string',{'Image&Mask';'Mask Only';'Image Only'},'value',viewMode);
S.LabelView = ...
    uicontrol('style','text',...
                  'units','pixels',...
                  'position',[360 115 60 15],...
                  'fontsize',10,...
                  'backgroundcolor',bColor,...
                  'string','View');

S.LabelHelp1 = ...
    uicontrol('style','text',...
                  'units','pixels',...
                  'position',[5 20 480 10],...
                  'fontsize',8,...
                  'backgroundcolor',bColor,...
                  'string','[LOAD]: Load an image from file, [SAVE]: Mask&Image and Mask images are saved in same folder as the image.');
S.LabelHelp2 = ...
    uicontrol('style','text',...
                  'units','pixels',...
                  'position',[5 10 480 10],...
                  'fontsize',8,...
                  'backgroundcolor',bColor,...
                  'string','Left press: draw mask, Right press: erase mask.');
              
%%%%% set callback %%%%%             
set(S.fig,... 
'WindowButtonMotionFcn',{@call_figMouseMove,S},...
'WindowButtonUpFcn',{@call_figMouseUp,S},...
'WindowButtonDownFcn',{@call_figMouseDown,S});
set(S.load,'call',{@call_load,S});
set(S.save,'call',{@call_save,S});
set([S.EditR,S.EditG,S.EditB],'call',{@call_editRGB,S});    
set(S.EditPS,'call',{@call_EditPS,S});
set(S.PopView,'call',{@call_PopView,S});
             
end

function [] = call_load(varargin) % Callback for the load button.
S = varargin{3};  % Get the structure.

global filename;
global dir;
[filename, dir] = uigetfile( '*.*', 'Load Image');

global img;
global msk;
global imSize;

img = imread([dir filename]);
imSize = size(img);
msk = zeros(imSize(1),imSize(2),'uint8');
showImageMask( S.img );

end

function [] = call_save(varargin) % Callback for the save button.
%S = varargin{3};  % Get the structure.

global filename;
global dir;
global img;
global msk;
global mskcol;

[d name ext] = fileparts(filename);

maskimage = genImageMask( single(img), single(msk), single(mskcol) );
imwrite( uint8(maskimage), [dir name '_img.png'] );
imwrite( uint8(msk*255), [dir name '_msk.png'] );

end

function [] = call_figMouseMove(varargin) 
S = varargin{3};  % Get the structure.

global pnSize;
global imSize;
global msk;
global point0;
global drawFlg

global wbmFlg;

if( wbmFlg == 0 && drawFlg >= 0 )    
    wbmFlg = 1;
    
    point1 = getPixelPosition();
    
    if( ~isempty( point0 ) )
        ps = pnSize / 480 * max([imSize(1),imSize(2)]);
        msk = drawLine( msk, point0, point1, ps, drawFlg );
        showImageMask(S.img); 
    end
    
    point0 = point1;
    
    wbmFlg = 0;
end

end

function [] = call_figMouseDown(varargin) 
%S = varargin{3};  % Get the structure.

global drawFlg;
global point0;

mouse = get(gcf,'SelectionType');
if( strcmpi( mouse, 'normal' ) )
    drawFlg = 1;
    point0 = getPixelPosition();

elseif( strcmpi( mouse, 'alt' ) )
    drawFlg = 0;
    point0 = getPixelPosition();

else
    drawFlg = -1;
end

end

function [] = call_figMouseUp(varargin) 
%S = varargin{3};  % Get the structure.

global drawFlg;
drawFlg = -1;
point0 = [];
end

function [] = call_editRGB(varargin) 
[h,S] = varargin{[1,3]};  % Get calling handle and structure.

val = edtitorange(h, [0 255]);

global mskcol;
switch(h)
    case S.EditR
        mskcol(1) = val;
    case S.EditG
        mskcol(2) = val;
    case S.EditB
        mskcol(3) = val;
    otherwise
end

showImageMask( S.img )

end

function [] = call_EditPS(varargin) 
[h,S] = varargin{[1,3]};  % Get calling handle and structure.

global pnSize;
pnSize = round( edtitorange(h, [1 100]) );

end

function [] = call_PopView(varargin) 
[h,S] = varargin{[1,3]};  % Get calling handle and structure.

global viewMode;
viewMode = get(h, 'value');
showImageMask(S.img);

end


function [] = showImageMask(handle)
global img;
global msk;
global mskcol;
global viewMode;

if( ~isempty(img) )
    switch( viewMode )
        case 1
            maskimage = genImageMask( single(img), single(msk), single(mskcol) );
        case 2
            maskimage = reshape( mskcol, [1 1 3] );
            maskimage = single(repmat( maskimage, [size(msk,1), size(msk,2), 1] )) .* single(repmat( msk, [1 1 3] ));            
        case 3
            maskimage = img;
        otherwise
            maskimage = zeros(size(msk));
    end
    axes(handle);
    imshow(uint8(maskimage));
end
end

function point = getPixelPosition()
global imSize;

if( isempty( imSize ) )
    point = [];
else
    cp = get (gca, 'CurrentPoint');
    cp = cp(1,1:2);
    row = int32(round( axes2pix(imSize(1), [1 imSize(1)], cp(2)) ));
    col = int32(round( axes2pix(imSize(2), [1 imSize(2)], cp(1)) ));

    point = [row col];
end
end

function val = edtitorange(h, range)
val = round(str2num(get(h,'string') ));
if( val < range(1) )
    val = range(1);
end
if( val > range(2) )
    val = range(2);
end
set(h, 'string', num2str(val) );
end

