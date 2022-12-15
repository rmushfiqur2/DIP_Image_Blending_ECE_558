function D = make_mask_fcn_v2( varargin )
%MAKE_MASK_FCN
%
% Michael Serafino
%
% 2016/02/12 - still v2
%
% Changed default thresholding mask mode to 'replace' instead of 'or'. This
% is stored in the D.d.dat.lastvalidthresholdopt property as a number (1
% for OR, 2 for AND, and 3 for REPLACE).
%
% Updated example syntax.
%
% Enabled running in dummy mode. No input args, draw on a dummy image. In
% order to do this I needed to replace all input args with varargin.
%
% 2016/02/08 - still v2
%
% TODO (not yet implemented).
%
% 1 - add another optional input slot for importing a mask (so we start the
% gui with the desired mask already made).
%
% 2 - change code so that if the 3rd input slot is empty it will not try to
% go into flim gui mode (this will be required when inputting the start
% mask as described in item 1).
%
% 6/30/15 - still v2
%
% Added option to select the mask color. Changed the brush type selection
% to a nested uimenu.
%
% IMPORTANT WORK-AROUND. Found a solution for smoother operation between
% clicking buttons and sending the focus back to the mask overlay.
%
% 6/21/15 - still v2
%
% Main plot of image uses jet colormap.
%
% 6/20/15 - still v2
%
% I have not finished the FLIM GUI updates, but I am adding more general
% purpose functionality:
%
%   - uipanel overlay for choosing the clim.
%
%       The uipanel overlay is launched when the user right clicks the
%       colorbar. The uipanel contains a histogram and boxplot showing the
%       distribution of the intensity values in the image to help the user
%       select a decent clim. The uipanel is closed when the user clicks
%       outside the panel.
%
%       This uipanel functionality will always be present in the gui.
%
%       Added later 6/21/15 - Another textbox to the uipanel that allows
%       for threholding to create a fresh mask. The user will enter a
%       min,max and then the mask will be created and will overwrite the
%       current mask.
%
%
% 6/17/15 - v2
%
% Modified to work with the main FLIM gui. I need to add a few features so
% that this gui can be launched as a sub-gui of the main flim gui and have
% behavior similar to the other sub-guis (alignment gui and viewing gui).
%
% - The main data structure is replaced with the generic handle class. The
% main data structure is then added as an output argument so that the main
% flim gui can access data in this sub-gui as needed.
%
% - A back button is added to the top left of the figure to make bringing
% the main FLIM gui to the top easier.
%
% - A title is added to display which feature is being plotted (absolute
% intensity is default)
%
% - A uicontextmenu is added to this gui's title to enable switching
% between features for plotting.
%
% - One optional input is added, a 4 element cell vector:
%
%   - element 1: GUI_DATA from the main flim gui.
%
%   - element 2: TDF from the main flim gui.
%
%   - element 3: TDFP from the main flim gui.
%
%   - element 4: channel being plotted.
%
%
% 6/15/15 - v1
%
% Added features to 'paint' the mask on the image. Just click on the image
% to begin painting. Left click paints positive, right click is opposite.
% Mouse wheel adjusts the brush size.
%
% Also, updated the display of the mask to update the alpha data too, so
% the mask isn't constantly obstructing the image.
%
% NOTE: currently this function will overwrite some of the parent figure or
% uipanel callbacks. I haven't figured out workarounds for this yet. This
% is mainly a potential issue when I want to imbed this GUI in other GUIs.
% My plan for the future is to have this GUI output handles to its desired
% callbacks. Then the parent GUI will decide when to run this gui's
% callbacks (when this gui is selected).
%
% Erased rezero_() function. Modified the push_() function to do what it
% should have done before (always push to the top of the stack). Previously
% I sort of followed the stack pointer when I pressed undo. So I created
% the rezero_() function to throw everything above away. In that case
% 'push_()' was not really what it should have been.
%
% 6/25/14 - v0
%
% This function uses a GUI to help the user make a mask on top of an image.
% Then the mask can be saved to the workspace via a pushbutton on the GUI.
%
% I'm originally creating this to extract pixels from a capillary tube
% image for FD FLIM.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Known issues
%
% 0 - cannot erase (negate mask) and rotate. Holding shift to toggle
% rotation causes some problem and results in the mask drawing (positive
% mask) instead. 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% EXAMPLE SYNTAX
%
% Example mode, the peaks image is used.
% make_mask_fcn_v2();
%
% * Primary mode, user inputs a 2D array and the GUI is used to draw a
% * binary mask on top of the 2D array.
% make_mask_fcn_v2( img ); %img is a 2D array
%
% Experimental modes - may not be functional
% make_mask_fcn_v2( img, figh ); % figh is the parent object
%
% make_mask_fcn_v2( img, figh, flim_gui_struct ); % used in FLIM proc gui

switch nargin
  case 0
    % dummy mode
    img = peaks(256);
    figh = [];
    FLIM_GUI_MODE = 0;
  case 1
    % only img
    img = double(varargin{1});
    figh = [];
    FLIM_GUI_MODE = 0;
  case 2
    % img and figh
    img = double(varargin{1});
    figh = varargin{2};
    FLIM_GUI_MODE = 0;
  case 3
    % flim gui mode
    img = double(varargin{1});
    figh = varargin{2};
    FLIM_GUI_MODE = 1;
    
    MAIN_GUI_DATA = varargin{3}{1};
    TDF = varargin{3}{2};
    TDFP = varargin{3}{3};
    CH = varargin{3}{4};
  otherwise
    warning('Only 3 valid input args, extra will be ignored');
end

DEBUG_TIC = tic;

% OLD INPUT PARSING CODE. Keeping for now until I test the new code enough to
% make sure it is functional.
%{
%%% dummy case for example purposes
if(nargin == 0)
  img = peaks(256);
  figh = [];
end

%%%
if(nargin > 2)
  % FLIM GUI mode
  FLIM_GUI_MODE = 1;
  MAIN_GUI_DATA = varargin{1}{1};
  TDF = varargin{1}{2};
  TDFP = varargin{1}{3};
  CH = varargin{1}{4};
else
  % normal mode
  FLIM_GUI_MODE = 0;
end
%}

% %%%%%%%% FOR TESTING %%%%%%%%%%% REMOVE LATER %%%%%%%%%%%%
% FLIM_GUI_MODE = 1;
% CH = 1;
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% limit for number of undo/redo operations
%Higher limit will potentially lead to more memory usage if the GUI is used
%for long periods of time and if lots of images are added to the stack.
MASK_STACK_LIMIT = 15;

%%% Default thresholding mask mode. If the user sets this to something
%%% invalid (not 1 - 3) then it will be set to 3 as a fallback mode and a
%%% warning will be printed to the command window.
%
% 1 - OR
%
% 2 - AND
%
% 3 - REPLACE [this is usually the most intuitive]
DEFAULT_THRESHOLDING_MASK_MODE = 3;

%%%
DEFAULT_MASK_COLOR = [0.8 0.8 0.8];
DEFAULT_MASK_OVERLAY_COLOR = [0.4 0.4 0.4];

MASK_ALPHA = 0.7;
MASK_ALPHA_OPTIONS = [MASK_ALPHA 0 0.1 0.2 0.3 0.4 0.5 0.6 0.8 0.9 1];
PMASK_ALPHA = 0.4;
PMASK_ALPHA_OPTIONS = [PMASK_ALPHA 0 0.1 0.2 0.3 0.5 0.6 0.7 0.8 0.9 1];

%%% data storage will be in a structure, d inside the generic handle
%%% object.
D = GENERIC_HANDLE_v0();


if(isempty(figh))
  D.d.fig = figure('units','normalized',...
    'name',['make_mask_fcn_v0 :: ' datestr(clock)]);
else
  D.d.fig = figh;
end

%%% set callbacks for painting.
if(~ishandle(D.d.fig))
  error('D.d.fig is not a valid handle');
end
switch get(D.d.fig,'type')
  case 'figure'
    set(D.d.fig,...
      'WindowButtonUpFcn',@WBUpFcn,...
      'WindowButtonMotionFcn',@WBMFcn,...
      'WindowButtonDownFcn',@WBDownFcn,...
      'WindowScrollWheelFcn',@WSWheelFcn,...
      'WindowKeyPressFcn',@WKPressFcn,...
      'WindowKeyReleaseFcn',@WKReleaseFcn);
    D.d.paint.pf = D.d.fig;
  case 'uipanel'
    % overwrite some callbacks in the parent figure
    D.d.paint.pf = ancestor(D.d.fig,'figure');
    set(D.d.paint.pf,...
      'WindowButtonUpFcn',@WBUpFcn,...
      'WindowButtonMotionFcn',@WBMFcn,...
      'WindowButtonDownFcn',@WBDownFcn,...
      'WindowScrollWheelFcn',@WSWheelFcn);
  otherwise
    error('Invalid D.d.fig type, needs to be panel or figure');
end


%%%
if(FLIM_GUI_MODE)
  img_ax_position = [0.15 1/3 0.825 2/3-0.1];
else
  img_ax_position = [0.05 1/3 0.9 2/3-0.05];
end
assignin('base','img',img)

D.d.comp.ax = axes('parent',D.d.fig,'units','normalized',...
  'position',img_ax_position,'nextplot','add',...
  'ylim',[1 size(img,1)],'xlim',[1 size(img,2)],...
  'ydir','reverse');

%%%
D.d.comp.cbar = colorbar;

%%%
D.d.comp.img = imagesc(img);
colormap(jet);

%%% pmask/mask colors and alphas
D.d.dat.maskcolor = DEFAULT_MASK_COLOR;
D.d.dat.maskalpha = MASK_ALPHA;
D.d.dat.pmaskcolor = DEFAULT_MASK_OVERLAY_COLOR;
D.d.dat.pmaskalpha = PMASK_ALPHA;

%%%
%used to hold the last mask that was created
D.d.dat.mask = false(size(img,1),size(img,2));
%used to hold the masks as a stack to enable undo/redo operations
D.d.dat.mask_stack{1} = D.d.dat.mask;
D.d.dat.mask_stack_index = 1;

%%% painting components (new to v1)
IMG_SIZE = [size(img,1), size(img,2)];

%ff =   mask_gray_to_rgb_mult(...
  %repmat(D.d.dat.mask,[1 1 3]),...
  %D.d.dat.maskcolor);
%assignin('base','ff',ff)
%assignin('base','frrf',D.d.dat)
%assignin('base','acid',D.d.dat.maskalpha*D.d.dat.mask)
%%% mask
%D.d.comp.maskimg = imagesc(ff, 'alphadata',D.d.dat.maskalpha*D.d.dat.mask);
D.d.comp.maskimg = imagesc(...
  mask_gray_to_rgb_mult(...
  repmat(D.d.dat.mask,[1 1 3]),...
  D.d.dat.maskcolor),...
  'alphadata',D.d.dat.maskalpha*D.d.dat.mask);

%%% draw button
D.d.comp.drawbutton = uicontrol('parent',D.d.fig,...
  'units','normalized','position',[0.45 1/3-0.1 0.1 0.05],...
  'string','DRAW','callback',@mainbuttoncallback);

%%% undo button
D.d.comp.undobutton = uicontrol('parent',D.d.fig,...
  'units','normalized','position',[0.3 1/3-0.1 0.1 0.05],...
  'string','<--Undo','callback',@mainbuttoncallback);

%%% redo button
D.d.comp.redobutton = uicontrol('parent',D.d.fig,...
  'units','normalized','position',[0.6 1/3-0.1 0.1 0.05],...
  'string','Redo-->','callback',@mainbuttoncallback);

%%% save to workspace button
D.d.comp.savetoworkspacebutton = uicontrol('parent',D.d.fig,...
  'units','normalized','position',[0.05 0.05 0.3 0.1],...
  'string','Save To Workspace as "mask"',...
  'callback',@savetoworkspacebuttoncallback);

%%% clear mask button
D.d.comp.clearmaskbutton = uicontrol('parent',D.d.fig,...
  'units','normalized','position',[1 - 0.35 0.05 0.3 0.1],...
  'string','Clear Mask',...
  'callback',@clearmaskbuttoncallback);

%%% invert mask button
D.d.comp.invertmaskbutton = uicontrol('parent',D.d.fig,...
  'units','normalized','position',[0.45 1/3-0.2 0.1 0.05],...
  'string','Invert','callback',@mainbuttoncallback);

%%% erode mask button
D.d.comp.morph.erodemaskbutton = uicontrol('parent',D.d.fig,...
  'units','normalized','position',[0.85 0.25 0.15 0.05],...
  'string','-> <- Erode',...
  'callback',@morphmaskcallback);

%%% dilate mask button
D.d.comp.morph.dilatemaskbutton = uicontrol('parent',D.d.fig,...
  'units','normalized','position',[0.85 0.2 0.15 0.05],...
  'string','<- -> Dilate',...
  'callback',@morphmaskcallback);

%%% text object with simple instructions
D.d.comp.maininstructionsbox = uicontrol('style','text',...
  'units','normalized','position',[0.35 0 0.3 0.1],...
  'string',...
  {'L-click = +mask, R-click = -mask',...
  'wheel = grow/shrink-mask',...
  'shift+wheel = rotate mask'});

%%% text object for displaying the current brush size and angle (updated by
%%% the update_brush_stats_textbox() function in the update_preview_mask
%%% function.
D.d.paint.brushstatsbox = uicontrol('style','text',...
  'units','normalized','position',[0.7 0 0.3 0.05],...
  'string','');

% morphological options
D.d.dat.morph.disksize = 3;
D.d.dat.morph.currentStrel = ...
  strel('disk',D.d.dat.morph.disksize);

% preview painting mask
D.d.paint.pmask = false(IMG_SIZE);
D.d.paint.pmaskh = ...
  imagesc(...
  mask_gray_to_rgb_mult(...
  repmat(D.d.paint.pmask,[1 1 3]),...
  D.d.dat.pmaskcolor),...
  'alphadata',D.d.paint.pmask*D.d.dat.pmaskalpha);
% painting state
%
%   idle - nothing happenning.
%
%   painting - user clicked and is dragging (button down but no button up).
%
%   drawing - user is drawing with the 'draw' button. In this case we will
%   do nothing. If I do not add another state here then the user will end
%   up drawing an outline in addition to what is drawn with imfreehand.
%
%   ending - user released, painting finished (button up).
D.d.paint.DS = 'idle';
% selection type (directly from the matlab 'SelectionType' property) to
% determine if left/right mouse button was clicked.
D.d.paint.selection_type = 'normal';
% current key (non-modifier), used for determining brush angle step size
D.d.paint.currentKey = '';
% brush size
D.d.paint.brushsize = [1 1];
% time that must elapse before the stack is pushed when drawing.
PAINT_STACK_TIMEOUT = 2.5;
% paint timer. Used to decide when to push or swap the mask stack.
D.d.paint.timer = tic;
% index arrays for non-square brushes
%
%   original inds (will not changed, but will be used to generate the inds
%   at different angles).
D.d.paint.oinds{1} = repmat([1:IMG_SIZE(1)]',[1 IMG_SIZE(2)]);
D.d.paint.oinds{2} = repmat([1:IMG_SIZE(2)],[IMG_SIZE(1) 1]);
%
D.d.paint.inds{1} = repmat([1:IMG_SIZE(1)]',[1 IMG_SIZE(2)]);
D.d.paint.inds{2} = repmat([1:IMG_SIZE(2)],[IMG_SIZE(1) 1]);
% brush types
%
%       NOTE: all brush types use the same brushsize property to store the
%       size.
%
%   square1 - first brush type implemented. Square with origin at top left.
%
%   square2 - second brush type. Square with origin in middle.
%
%   ellipse1 - first circle type, origin in middle.
%
%   rod1 - rod shape. Size only adjustable in 1 dimension. Origin in
%   middle. Angle adjustable by holding shift and mouse wheel.
D.d.paint.brushtype = 'ellipse1';
D.d.paint.brushaspectratio = 1; % not implemented yet.
D.d.paint.brushangle = 0;
D.d.paint.brushanglecount = 0;
D.d.paint.brushangle_coarsestep = 128;
D.d.paint.brushangle_finestep = 50; % not used anymore, just coarsestep
D.d.paint.brushangle_step = D.d.paint.brushangle_coarsestep;
D.d.paint.brushangleadjustkeys = {'a','s','z','slash','quote','semicolon'};
D.d.paint.brushangleadjustkeymask = false(size(D.d.paint.brushangleadjustkeys));
D.d.paint.brushangleadjustenable = false;

% text object with context menu to choose brush type.
D.d.comp.mainoptionuimenu = uicontextmenu('parent',D.d.fig,...
  'position',[0 0]);

% Mask options
D.d.comp.maskoptionstopuimenu = uimenu(D.d.comp.mainoptionuimenu,...
  'label','Mask opts');
D.d.comp.maskoptionsuimenu(1) = uimenu(D.d.comp.maskoptionstopuimenu,...
  'label','Mask color',...
  'tag','Mask color',...
  'callback',@maskoptionsuimenucallback);
D.d.comp.maskoptionsuimenu(2) = uimenu(D.d.comp.maskoptionstopuimenu,...
  'label','Mask opacity [alpha]',...
  'tag','Mask opacity [alpha]');
for n = 1 : numel(MASK_ALPHA_OPTIONS)
  D.d.comp.maskalphauimenu{n} = uimenu(D.d.comp.maskoptionsuimenu(2),...
    'label',num2str(MASK_ALPHA_OPTIONS(n)),...
    'callback',@maskoptionsuimenucallback);
  if(n==1)
    set(D.d.comp.maskalphauimenu{n},...
      'Checked','On');
  end
end

D.d.comp.maskoptionsuimenu(3) = uimenu(D.d.comp.maskoptionstopuimenu,...
  'label','Overlay color',...
  'tag','Overlay color',...
  'callback',@maskoptionsuimenucallback);
D.d.comp.maskoptionsuimenu(4) = uimenu(D.d.comp.maskoptionstopuimenu,...
  'label','Overlay opacity [alpha]',...
  'tag','Overlay opacity [alpha]');
for n = 1 : numel(PMASK_ALPHA_OPTIONS)
  D.d.comp.pmaskalphauimenu{n} = uimenu(D.d.comp.maskoptionsuimenu(4),...
    'label',num2str(PMASK_ALPHA_OPTIONS(n)),...
    'callback',@maskoptionsuimenucallback);
  if(n==1)
    set(D.d.comp.pmaskalphauimenu{n},...
      'Checked','On');
  end
end

D.d.comp.maskoptionsuimenu(5) = uimenu(D.d.comp.maskoptionstopuimenu,...
  'label','Reset to defaults',...
  'callback',@maskoptionsuimenucallback);

% Brush options
D.d.paint.brushtypetextboxuicontextmenu = uimenu(D.d.comp.mainoptionuimenu,...
  'label','Brush opts');
D.d.paint.brushtypetextboxuimenu(1) = uimenu(...
  D.d.paint.brushtypetextboxuicontextmenu,...
  'label','ellipse1',...
  'callback',@brushtypetextboxuimenucallback,...
  'Checked','on');
D.d.paint.brushtypetextboxuimenu(2) = uimenu(...
  D.d.paint.brushtypetextboxuicontextmenu,...
  'label','square',...
  'callback',@brushtypetextboxuimenucallback);
D.d.paint.brushtypetextboxuimenu(3) = uimenu(...
  D.d.paint.brushtypetextboxuicontextmenu,...
  'label','rod1',...
  'callback',@brushtypetextboxuimenucallback);
D.d.paint.brushtypetextboxuimenu(4) = uimenu(...
  D.d.paint.brushtypetextboxuicontextmenu,...
  'label','outline_square2',...
  'callback',@brushtypetextboxuimenucallback);
D.d.paint.brushtypetextboxuimenu(5) = uimenu(...
  D.d.paint.brushtypetextboxuicontextmenu,...
  'label','outline_ellipse1',...
  'callback',@brushtypetextboxuimenucallback);
D.d.paint.brushtypetextboxuimenu(6) = uimenu(...
  D.d.paint.brushtypetextboxuicontextmenu,...
  'label','tidalwave1',...
  'callback',@brushtypetextboxuimenucallback);
D.d.paint.brushtypetextboxuimenu(7) = uimenu(...
  D.d.paint.brushtypetextboxuicontextmenu,...
  'label','aperature1',...
  'callback',@brushtypetextboxuimenucallback);

D.d.paint.brushtypetextbox = uicontrol('parent',D.d.fig,...
  'units','normalized','position',[0.05 0.2 0.2 0.05],...
  'style','text',...
  'string','Options [right click]',...
  'uicontextmenu',D.d.comp.mainoptionuimenu,...
  'HorizontalAlignment','center',...
  'backgroundcolor',[0.8 0.7 0.7],...
  'tooltip','shortcut=letter ''o''');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% main FLIM GUI MODE additions
%
% These components are independent of the original make mask fcn gui
% components and are only for interacting with the main flim gui.
if(FLIM_GUI_MODE)
  %%% current feature being plotted
  D.d.dat.FLIMGUI.currentfeature = 'I';
  %%% ID for main flim gui
  D.d.ID = 'MASK_MAKING_GUI';
  %%% back button
  D.d.comp.FLIMGUI.backbutton = uicontrol(...
    'style','pushbutton',...
    'units','normalized',...
    'position',[0 0.90 0.125 0.1],...
    'string','<-',...
    'fontsize',16,...
    'callback',@FLIMGUI_backbuttoncallback);
  %%% title for displaying currently plotted feature
  D.d.comp.FLIMGUI.title = title(D.d.comp.ax,...
    sprintf('Feature :: %s%g',...
    D.d.dat.FLIMGUI.currentfeature,...
    CH));
  %%% save to main gui button
  D.d.comp.FLIMGUI.savetomainguibutton = uicontrol('style','pushbutton',...
    'units','normalized','position',[0 0 0.3 0.05],...
    'string','Save mask to FLIM GUI',...
    'callback',@FLIMGUI_savemasktoflimguicallback,...
    'backgroundcolor',[0.8 0.7 0.7]);
  %%% load mask from flim gui
  if(~isempty(TDF.deconv_mask) && (size(TDF.deconv_mask,3) >= CH))
    % the condition for this if() might break if a 1D image is
    % processed (I'm checking dim3).
    D.d.dat.mask = TDF.deconv_mask(:,:,CH);
    set(D.d.comp.maskimg,...
      'CData',mask_gray_to_rgb_mult(repmat(D.d.dat.mask,[1 1 3]),D.d.dat.maskcolor),...
      'alphadata',D.d.dat.maskalpha*D.d.dat.mask);
    push_();
  end
  
  %%% uicontext menu's for switching between plotting different features.
  %
  % Since I don't have any properties that denote which features are
  % 'plottable', I will hardwire a list here. Ideally, I would have some
  % way of getting a list of all plottable features. But right now all
  % features are just thrown in the TDF.
  D.d.dat.FLIMGUI.possiblefeatures = {...
    'I','In','lifetime','tau','dlifetime','dtau'};
  D.d.comp.FLIMGUI.featureuicontextmenu = ...
    uicontextmenu('parent',D.d.fig,...
    'position',[0 0]);
  for n_0 = 1 : numel(D.d.dat.FLIMGUI.possiblefeatures)
    D.d.comp.FLIMGUI.featureuimenu(n_0) = ...
      uimenu(D.d.comp.FLIMGUI.featureuicontextmenu,...
      'label',D.d.dat.FLIMGUI.possiblefeatures{n_0},...
      'callback',@FLIMGUI_featureuimenucallback);
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% clim adjustment and threshold-mask creation

%%% clim adjustment uipanel
D.d.comp.climadjustpanel = uipanel('parent',D.d.fig,...
  'units','normalized',...
  'position',[0 0 1 0.4],...
  'visible','off',...
  'title','CLIM ADJUST / THRESHOLD-MASK [click outside to close]',...
  'fontsize',14);

%%% clim adjustment panel axes
D.d.comp.climadjustax = axes('parent',D.d.comp.climadjustpanel,...
  'units','normalized','position',[0.1 0.6 0.8 0.3]);

%%% clim adjustment edit box panel
D.d.comp.climadjusteditboxpanel = uipanel('parent',D.d.comp.climadjustpanel,...
  'units','normalized','position',[0 0 0.5 0.3],...
  'title','CLIM [min,max]','fontsize',10);

%%% clim adjustment edit box
D.d.comp.climadjustbox = uicontrol('parent',D.d.comp.climadjusteditboxpanel,...
  'units','normalized','position',[0 0 1 1],...
  'style','edit','string','','fontsize',12,...
  'callback',@climadjustboxcallback);

%%% threshold mask edit box panel
D.d.comp.thresholdmaskeditboxpanel = uipanel('parent',D.d.comp.climadjustpanel,...
  'units','normalized','position',[0.5 0 0.5 0.3],...
  'title','MASK THRESHOLD [min,max]','fontsize',10);

%%% threshold mask edit box

% context menu for setting mask merge option
D.d.comp.thresholdmaskboxuicontextmenu = uicontextmenu(...
  'parent',D.d.fig,'position',[0 0]);
% uimenu items (options)
D.d.comp.thresholdmaskboxuimenu(1) = uimenu(D.d.comp.thresholdmaskboxuicontextmenu,...
  'label','OR',...
  'callback',@thresholdmaskboxuimenucallback);
D.d.comp.thresholdmaskboxuimenu(2) = uimenu(D.d.comp.thresholdmaskboxuicontextmenu,...
  'label','AND',...
  'callback',@thresholdmaskboxuimenucallback);
D.d.comp.thresholdmaskboxuimenu(3) = uimenu(D.d.comp.thresholdmaskboxuicontextmenu,...
  'label','REPLACE',...
  'callback',@thresholdmaskboxuimenucallback);
% edit box
D.d.comp.thresholdmaskbox = uicontrol('parent',D.d.comp.thresholdmaskeditboxpanel,...
  'units','normalized','position',[0 0 1 1],...
  'style','edit','string','-inf, inf','fontsize',12,...
  'callback',@thresholdmaskboxcallback,...
  'uicontextmenu',D.d.comp.thresholdmaskboxuicontextmenu);

%%% clim adjustment panel children objects. Used to check to see if we need
%%% to close the panel in the button down callback.
D.d.dat.climadjustmentpanelchildren = ...
  [D.d.comp.climadjustax;...
  D.d.comp.climadjusteditboxpanel;...
  D.d.comp.climadjustbox;...
  D.d.comp.thresholdmaskeditboxpanel;...
  D.d.comp.thresholdmaskbox];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Initialization actions
% make current object the mask image so that the preview mask overlay
% starts displaying immediately.
set(D.d.paint.pf,'CurrentObject',D.d.paint.pmaskh);
% get the current clim (set automatically when first plotting the image).
D.d.dat.lastvalidclim = get(D.d.comp.ax,'clim');
set(D.d.comp.climadjustbox,'string',num2str(D.d.dat.lastvalidclim));
% initialize last valid threshold as nothing [-inf inf]
D.d.dat.lastvalidthreshold = [-inf inf];
try
  if(~sum(DEFAULT_THRESHOLDING_MASK_MODE == [1 2 3]))
    % if it's not 1 2 or 3 then set to 3
    D.d.dat.lastvalidthresholdopt = 3;
    warning('DEFAULT_THRESHOLDING_MASK_MODE invalid, setting to 3');
  else
    % good, keep it
    D.d.dat.lastvalidthresholdopt = DEFAULT_THRESHOLDING_MASK_MODE;
  end
catch
  % problem (maybe the user inputted a vector for the default option, set
  % to 3
  D.d.dat.lastvalidthresholdopt = 3;
  warning('DEFAULT_THRESHOLDING_MASK_MODE invalid, setting to 3');
end
set(D.d.comp.thresholdmaskboxuimenu(D.d.dat.lastvalidthresholdopt),...
  'checked','on');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% callbacks
  function mainbuttoncallback(h,ev)
    %this function handles the buttons.
    switch h
      case D.d.comp.drawbutton
        try
          %avoid error when user presses escape after clicking
          %draw. imroi complains about something involving
          %ancestor with not enough input args.
          D.d.paint.DS = 'drawing';
          imfh = imfreehand(D.d.comp.ax,'Closed',1);
          D.d.dat.mask = imfh.createMask(D.d.comp.img);
          imfh.delete();
          D.d.dat.mask = D.d.dat.mask | ...
            D.d.dat.mask_stack{D.d.dat.mask_stack_index};
          push_();
          assignin('base','mask',D.d.dat.mask_stack{D.d.dat.mask_stack_index}); % added by mushfiq
          updateimage();
        catch err0
          try
            imfh.delete();
          catch err1
              % 
          end
        end
        
      case D.d.comp.undobutton
        D.d.dat.mask_stack_index = D.d.dat.mask_stack_index - 1;
        if(D.d.dat.mask_stack_index <= 1)
          D.d.dat.mask_stack_index = 1;
        end
        D.d.dat.mask = D.d.dat.mask_stack{D.d.dat.mask_stack_index};
        updateimage();
        % annoying. After clicking undo the focus goes to the undo
        % button. Set it back to the mask so that the preview pixel
        % gets updated without having to click back on the mask to
        % make the mask the current object.
        return_focus_from_button_to_overlay(h);
        
      case D.d.comp.redobutton
        D.d.dat.mask_stack_index = D.d.dat.mask_stack_index + 1;
        if(D.d.dat.mask_stack_index >= length(D.d.dat.mask_stack))
          D.d.dat.mask_stack_index = length(D.d.dat.mask_stack);
        end
        updateimage();
        return_focus_from_button_to_overlay(h);
        
      case D.d.comp.invertmaskbutton
        D.d.dat.mask = ~D.d.dat.mask_stack{D.d.dat.mask_stack_index};
        push_();
        updateimage();
        return_focus_from_button_to_overlay(h);
      otherwise
    end
  end

  function savetoworkspacebuttoncallback(h,ev)
    assignin('base','mask',D.d.dat.mask_stack{D.d.dat.mask_stack_index});
    return_focus_from_button_to_overlay(h);
  end

  function clearmaskbuttoncallback(h,ev)
    D.d.dat.mask = false(size(img));
    push_();
    updateimage();
    return_focus_from_button_to_overlay(h);
  end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% painting callback controls

%%% window button down function
  function WBDownFcn(h,ev)
    %%% If we are on the axis, start the painting state (even if we are
    %%% already in the painting state, in case it did not exit
    %%% prematurely).
    switch gco
      case D.d.comp.cbar
        switch get(h,'SelectionType')
          case 'normal'
            % toggle the clim panel
            if(strcmp(get(D.d.comp.climadjustpanel,'visible'),'on'))
              close_clim_adjust();
            else
              open_clim_adjust();
            end
          otherwise
        end
      case {D.d.comp.maskimg,D.d.paint.pmaskh}
        % close the clim adjust (in case it was opened).
        close_clim_adjust();
        switch D.d.paint.DS
          case 'drawing'
            % do nothing (user is drawing with the 'draw'
            % button (imfreehand).
          otherwise
            D.d.paint.DS = 'painting';
            cp = get(D.d.comp.ax,'CurrentPoint');
            D.d.paint.selection_type = get(h,'SelectionType');
            paint_pixel(cp);
        end
      otherwise
        if(sum(...
            gco == [D.d.dat.climadjustmentpanelchildren(:); ...
            D.d.comp.climadjustpanel]))
          % don't close the clim panel
        else
          %close the clim adjustment panel (for now I am not checking
          %if it is opened first).
          close_clim_adjust();
        end
    end
  end

%%% window button motion function
  function WBMFcn(h,ev)
    if(~isempty(gco))
      switch gco
        case {D.d.comp.maskimg,D.d.paint.pmaskh}
          cp = get(D.d.comp.ax,'CurrentPoint');
          switch D.d.paint.DS
            case 'painting'
              paint_pixel(cp);
              preview_pixel(cp);
            case {'idle','ending'}
              preview_pixel(cp);
            otherwise
          end
        otherwise
          %nothing
      end
    end
  end

%%% window button up function
  function WBUpFcn(h,ev)
    D.d.paint.DS = 'idle';
  end

%%% scroll wheel (brush size adjustment)
  function WSWheelFcn(h,ev)
    if(~isempty(gco))
      switch gco
        case {D.d.comp.maskimg,D.d.paint.pmaskh}
          % rotate coordinates if the selection type is extend
          % (holding shift).
          if(D.d.paint.brushangleadjustenable)
            D.d.paint.brushanglecount = ...
              D.d.paint.brushanglecount+ev.VerticalScrollCount;
            D.d.paint.brushanglecount = ...
              rem(D.d.paint.brushanglecount,...
              D.d.paint.brushangle_step);
            
            D.d.paint.brushangle = ...
              2*pi * ...
              D.d.paint.brushanglecount/D.d.paint.brushangle_step;
          else
            % update brush size
            tmp_brush_size = D.d.paint.brushsize;
            tmp_brush_size = tmp_brush_size + ...
              -ev.VerticalScrollCount;
            D.d.paint.brushsize = fix_brush_size(tmp_brush_size);
          end
          % draw/preview if needed
          cp = get(D.d.comp.ax,'CurrentPoint');
          switch D.d.paint.DS
            case 'painting'
              paint_pixel(cp);
              preview_pixel(cp);
            case {'idle','ending'}
              preview_pixel(cp);
            otherwise
          end
        otherwise
          %nothing
      end
    end
  end

%%% key press callbacks
  function WKPressFcn(h,ev)
    if(~isempty(ev.Modifier))
      if(sum(strcmp(ev.Modifier,'shift')))
        D.d.paint.brushangleadjustenable = true;
      end
    end
  end

  function WKReleaseFcn(h,ev)
    if(~isempty(ev.Modifier))
      if(sum(strcmp(ev.Modifier,'shift')))
      end
    else
      % when shift is released the modifier is empty but the key is
      % shift.
      if(strcmp(ev.Key,'shift'))
        D.d.paint.brushangleadjustenable = false;
        D.d.paint.brushangleadjustkeymask = ...
          false(size(D.d.paint.brushangleadjustkeys));
      end
    end
  end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% painting pixel manipulation

  function paint_pixel(location_)
    [brush_mask] = ...
      get_brush_mask(location_,D.d.paint.brushsize);
    D.d.dat.mask = D.d.dat.mask_stack{D.d.dat.mask_stack_index};
    switch D.d.paint.selection_type
      case 'alt'
        %erase
        D.d.dat.mask(brush_mask) = false;
      otherwise
        %normal (or extend, can't figure out a solution where I can
        %adjust the brush angle with the scroll wheel and maintain
        %independent detection of left/right mouse clicks).
        D.d.dat.mask(brush_mask) = true;
    end
    
    elapsed_time = toc(D.d.paint.timer);
    if(elapsed_time > PAINT_STACK_TIMEOUT)
      push_();
      D.d.paint.timer = tic;
    else
      swap_();
    end
    updateimage();
  end

  function preview_pixel(location_)
    [brush_mask] = ...
      get_brush_mask(location_,D.d.paint.brushsize);
    D.d.paint.pmask(:,:) = false;
    D.d.paint.pmask(brush_mask) = true;
    update_preview_mask();
  end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% painting utilities

  function location_ = fix_location(location_)
    % This function ensures that the location is integer and within the
    % bounds of the image.
    
    % crop and swap x/y
    location_ = location_(1,[2 1]);
    % round
    location_ = round(location_);
    % in bounds
    location_(location_ < 1) = 1;
    if(location_(1) > IMG_SIZE(1))
      location_(1) = IMG_SIZE(1);
    end
    if(location_(2) > IMG_SIZE(2))
      location_(2) = IMG_SIZE(2);
    end
  end

  function brush_size = fix_brush_size(brush_size)
    for n = 1 : 2
      if(brush_size(n) < 1)
        % can't be less than 1 pixel.
        brush_size(n) = 1;
      elseif(brush_size(n) > IMG_SIZE(n))
        % don't let it be bigger than the image.
        brush_size(n) = IMG_SIZE(n);
      else
        % it's good.
      end
    end
  end

  function [brush_mask] = ...
      get_brush_mask(location_,brush_size)
    % This function generates a brush mask that has 1's where the mask
    % is (same size as image). This is more convienent when applying
    % the mask to the image than computing and manipulating the
    % indicies.
    brush_size = fix_brush_size(brush_size);
    
    switch D.d.paint.brushtype
      case 'ellipse1'
        location_ = fix_location(location_);
        rotate_inds(0);
        brush_mask = ...
          (D.d.paint.inds{1} - location_(1)).^2./brush_size(1).^2 + ...
          (D.d.paint.inds{2} - location_(2)).^2./brush_size(2).^2 ...
          < 1;
      case 'square'
        location_ = rotate_location(fix_location(location_));
        rotate_inds(D.d.paint.brushangle);
        brush_mask = ...
          abs(D.d.paint.inds{1} - location_(1))./brush_size(1) + ...
          abs(D.d.paint.inds{2} - location_(2))./brush_size(2) ...
          < 1;
      case 'rod1'
        location_ = rotate_location(fix_location(location_));
        rotate_inds(D.d.paint.brushangle);
        
        brush_mask = abs(D.d.paint.inds{1}-location_(1)) <= ...
          brush_size(1)-0.5;
        
      case 'outline_square2'
        % problem with rotated coordinates, just use original
        location_ = fix_location(location_);
        rotate_inds(0);
        brush_mask = ...
          (abs(D.d.paint.oinds{1} - location_(1)) == brush_size(1)) ...
          & ...
          D.d.paint.oinds{2} > location_(2) - brush_size(2) ...
          & ...
          D.d.paint.oinds{2} < location_(2) + brush_size(2)...
          ...
          | ...
          ...
          (abs(D.d.paint.oinds{2} - location_(2)) == brush_size(2)) ...
          & ...
          D.d.paint.oinds{1} > location_(1) - brush_size(1) ...
          & ...
          D.d.paint.oinds{1} < location_(1) + brush_size(1) ...
          ...
          | ...
          ...
          ((abs(D.d.paint.oinds{1} - location_(1)) == brush_size(1)) ...
          & ...
          (abs(D.d.paint.oinds{2} - location_(2)) == brush_size(2)));
      case 'outline_ellipse1'
        location_ = fix_location(location_);
        rotate_inds(0);
        dists = ...
          (D.d.paint.inds{1} - location_(1)).^2./brush_size(1).^2 + ...
          (D.d.paint.inds{2} - location_(2)).^2./brush_size(2).^2;
        % tolerance factor that keeps the outline close to 1-pixel
        % wide (1 divided by the average of the ellipse radii).
        tol = 1/(0.5*(brush_size(1)+brush_size(2)));
        brush_mask = ...
          dists > 1-tol & dists < 1+tol;
      case 'tidalwave1'
        location_ = rotate_location(fix_location(location_));
        rotate_inds(D.d.paint.brushangle);
        brush_mask = ...
          (D.d.paint.inds{1} - location_(1))./brush_size(1) + ...
          (D.d.paint.inds{2} - location_(2))./brush_size(2) ...
          < 1;
      case 'aperature1'
        location_ = rotate_location(fix_location(location_));
        rotate_inds(D.d.paint.brushangle);
        diffs = abs(D.d.paint.inds{1} - location_(1));
        brush_mask = ...
          ~(diffs <= brush_size(1)-1) & ...
          ~(diffs >= brush_size(1)+1);
      otherwise
        error('Invalid brush type?');
    end
    
    
  end

  function update_preview_mask
    set(D.d.paint.pmaskh,'CData',...
      mask_gray_to_rgb_mult(...
      repmat(D.d.paint.pmask,[1 1 3]),...
      D.d.dat.pmaskcolor),...
      'alphadata',D.d.paint.pmask*D.d.dat.pmaskalpha);
    update_brush_stats_textbox();
  end

  function brushtypetextboxuimenucallback(h,ev)
    % This function controls the brush type selection.
    set(h,'Checked','on');
    for n = 1 : numel(D.d.paint.brushtypetextboxuimenu)
      if(h ~= D.d.paint.brushtypetextboxuimenu(n))
        set(D.d.paint.brushtypetextboxuimenu(n),...
          'Checked','off');
      end
    end
    D.d.paint.brushtype = get(h,'label');
    return_focus_from_button_to_overlay(h);
  end

  function rotate_inds(rot_amount)
    D.d.paint.inds{1} = ...
      D.d.paint.oinds{1}*cos(rot_amount) - ...
      D.d.paint.oinds{2}*sin(rot_amount);
    D.d.paint.inds{2} = ...
      D.d.paint.oinds{1}*sin(rot_amount) + ...
      D.d.paint.oinds{2}*cos(rot_amount);
    
    %         %%% mask corrections
    %         switch D.d.paint.brushtype
    %             case {'square2','outline_square2'}
    %                 correction_enable = ...
    %                     abs(D.d.paint.brushangle - ...
    %                     [0,pi/2,pi,3*pi/2,2*pi]) < 1.1*2*pi/D.d.paint.brushangle_step;
    %                 if(sum(correction_enable))
    %                     if(sum(correction_enable([1 3 5])))
    %                         % ASSUMES BRUSH SYMMETRY
    %                         D.d.paint.inds{1} = D.d.paint.oinds{1};
    %                         D.d.paint.inds{2} = D.d.paint.oinds{2};
    %                     elseif(any(correction_enable([2 4])))
    %                         D.d.paint.inds{1} = D.d.paint.oinds{2};
    %                         D.d.paint.inds{2} = D.d.paint.oinds{1};
    %                     end
    %                 else
    % %                     % helps clean up glitchy edges close to vertical and horizontal
    % %                     % angles. Without this some edges will sometimes disappear due to
    % %                     % precision issues.
    % %                     D.d.paint.inds{1} = D.d.paint.inds{1} - ...
    % %                         rem(D.d.paint.inds{1},2*pi/D.d.paint.brushangle_step);
    % %                     % helps clean up glitchy edges close to vertical and horizontal
    % %                     % angles. Without this some edges will sometimes disappear due to
    % %                     % precision issues.
    % %                     D.d.paint.inds{2} = D.d.paint.inds{2} - ...
    % %                         rem(D.d.paint.inds{2},2*pi/D.d.paint.brushangle_step);
    %                 end
    %             otherwise
    %         end
  end

  function location_ = rotate_location(location_)
    location_ = location_(:);
    %         %%% mask corrections
    %         switch D.d.paint.brushtype
    %             case {'square2','outline_square2'}
    %                 correction_enable = ...
    %                     abs(D.d.paint.brushangle - ...
    %                     [0,pi/2,pi,3*pi/2,2*pi]) < 1.1*2*pi/D.d.paint.brushangle_step;
    %                 if(sum(correction_enable))
    %                     if(sum(correction_enable([1 3 5])))
    %                         % ASSUMES BRUSH SYMMETRY
    %                     elseif(any(correction_enable([2 4])))
    %                         location_ = location_([2 1]);
    %                     end
    %                 else
    %                     rot_matrix = [...
    %                         cos(D.d.paint.brushangle),-sin(D.d.paint.brushangle);...
    %                         sin(D.d.paint.brushangle),cos(D.d.paint.brushangle)];
    %                     location_ = rot_matrix*location_;
    %                 end
    %             otherwise
    rot_matrix = [...
      cos(D.d.paint.brushangle),-sin(D.d.paint.brushangle);...
      sin(D.d.paint.brushangle),cos(D.d.paint.brushangle)];
    location_ = rot_matrix*location_;
    %         end
    
    
  end

  function update_brush_stats_textbox
    % This function prints the current brushsize and angle in a textbox
    % in the figure.
    set(D.d.paint.brushstatsbox,'string',...
      sprintf('Size: [%g,%g], angle: %g',...
      D.d.paint.brushsize(1),...
      D.d.paint.brushsize(2),...
      D.d.paint.brushangle));
  end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Mask options
  function maskoptionsuimenucallback(h,ev)
    switch h
      case D.d.comp.maskoptionsuimenu(1)
        tmpcolor = uisetcolor(D.d.dat.maskcolor);
        if(numel(tmpcolor) == 3)
          D.d.dat.maskcolor = tmpcolor;
          updateimage();
          set(h,'label',...
            [get(h,'tag') ' :: ' num2str(tmpcolor)]);
        end
      case D.d.comp.maskalphauimenu
        for n_tmp = 1 : numel(D.d.comp.maskalphauimenu)
          if(h == D.d.comp.maskalphauimenu{n_tmp})
            % hit
            set(h,'Checked','On');
            D.d.dat.maskalpha = str2num(get(h,'label'));
          else
            set(D.d.comp.maskalphauimenu{n_tmp},'Checked','Off');
          end
        end
        updateimage();
      case D.d.comp.maskoptionsuimenu(3)
        tmpcolor = uisetcolor(D.d.dat.pmaskcolor);
        if(numel(tmpcolor) == 3)
          D.d.dat.pmaskcolor = tmpcolor;
          update_preview_mask();
          set(h,'label',...
            [get(h,'tag') ' :: ' num2str(tmpcolor)]);
        end
      case D.d.comp.pmaskalphauimenu
        for n_tmp = 1 : numel(D.d.comp.pmaskalphauimenu)
          if(h == D.d.comp.pmaskalphauimenu{n_tmp})
            % hit
            set(h,'Checked','On');
            D.d.dat.pmaskalpha = str2num(get(h,'label'));
          else
            set(D.d.comp.pmaskalphauimenu{n_tmp},'Checked','Off');
          end
        end
        update_preview_mask();
      case D.d.comp.maskoptionsuimenu(end)
        % last one is the reset option (reset all colors and alphas
        % to defaults)
        D.d.dat.maskcolor = DEFAULT_MASK_COLOR;
        D.d.dat.maskalpha = MASK_ALPHA;
        D.d.dat.pmaskcolor = DEFAULT_MASK_OVERLAY_COLOR;
        D.d.dat.pmaskalpha = PMASK_ALPHA;
        % ensure that the correct alpha options are checked
        % (easiest way is to just call the callbacks with the first
        % entries).
        maskoptionsuimenucallback(D.d.comp.maskalphauimenu{1},ev);
        maskoptionsuimenucallback(D.d.comp.pmaskalphauimenu{1},ev);
        % recall, updateimage() also updates the preview mask, so
        % we just need to call the update image function
        updateimage();
      otherwise
    end
    return_focus_from_button_to_overlay(h);
  end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% morphological operations
  function morphmaskcallback(h,ev)
    switch h
      case D.d.comp.morph.erodemaskbutton
        D.d.dat.mask = imerode(D.d.dat.mask,D.d.dat.morph.currentStrel);
        push_();
        updateimage();
        return_focus_from_button_to_overlay(h);
      case D.d.comp.morph.dilatemaskbutton
        D.d.dat.mask = imdilate(D.d.dat.mask,D.d.dat.morph.currentStrel);
        push_();
        updateimage();
        return_focus_from_button_to_overlay(h);
      otherwise
    end
  end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% clim adjustment panel
  function open_clim_adjust()
    % This function 'opens' the clim adjustment uipanel overlay in the
    % figure.
    set(D.d.comp.climadjustpanel,'visible','on');
    % plot boxplot of image values. Getting the CData each time makes
    % coding easier for both the FLIM GUI mode and normal mode.
    tmpd = get(D.d.comp.img,'CData');
    boxplot(tmpd(:),'orientation','horizontal',...
      'parent',D.d.comp.climadjustax);
    % set focus to edit box
    uicontrol(D.d.comp.climadjustbox);
  end

  function close_clim_adjust()
    % This function 'closes' the clim adjustment uipanel overlay in the
    % figure.
    set(D.d.comp.climadjustpanel,'visible','off');
    % set current object to mask so preview overlay starts
    return_focus_from_button_to_overlay([]);
  end

%%% clim adjustment box
  function climadjustboxcallback(h,ev)
    clim = str2num(get(h,'string'));
    clim = fixclim(clim);
    set(D.d.comp.ax,'clim',clim);
    set(h,'string',num2str(clim));
  end

  function clim = fixclim(clim)
    % This function checks the clim and outputs a clim in the correct
    % format. The correct format is [min,max]. If the user tries to
    % specify a min value that is greater than the max value, this
    % function will switch the values. Similarly, if the user enters a
    % vector that has more than 2 elements, this function returns the
    % min and max of the vector to use as the clim. Furthermore, if the
    % values are invalid (not numeric). this function return the last
    % valid clim (stored in the D.d.dat.lastvalidclim property).
    if(isempty(clim) || ~isnumeric(clim) || isscalar(clim))
      clim = D.d.dat.lastvalidclim;
      %assignin('base','clim', D.d.dat);
    else
      clim = [min(clim) max(clim)];
      D.d.dat.lastvalidclim = clim;
    end
  end

%%% threshold mask
  function thresholdmaskboxuimenucallback(h,ev)
    %%% Recall: HARDWIRED OPTION/OBJECT correspondance:
    %
    % 1 - OR
    %
    % 2 - AND
    %
    % 3 - REPLACE
    %
    % This function makes the uimenu act like a set of 'radio' buttons,
    % only 1 is checked at one time. This function also fills the
    % D.d.dat.lastvalidthresholdopt property with the above option
    % according to the state of the threshold option.
    set(h,'Checked','on');
    for n = 1 : 3
      if(h ~= D.d.comp.thresholdmaskboxuimenu(n))
        set(D.d.comp.thresholdmaskboxuimenu(n),...
          'Checked','off');
      else
        optionhit = n;
      end
    end
    D.d.dat.lastvalidthresholdopt = optionhit;
  end

  function thresholdmaskboxcallback(h,ev)
    thresholds_ = str2num(get(h,'string'));
    thresholds_ = fixthreshold(thresholds_);
    set(h,'string',num2str(thresholds_));
    current_img = get(D.d.comp.img,'CData');
    switch D.d.dat.lastvalidthresholdopt
      case 1
        D.d.dat.mask = (current_img >= thresholds_(1) & ...
          current_img <= thresholds_(2)) | D.d.dat.mask;
      case 2
        D.d.dat.mask = (current_img >= thresholds_(1) & ...
          current_img <= thresholds_(2)) & D.d.dat.mask;
      case 3
        D.d.dat.mask = current_img >= thresholds_(1) & ...
          current_img <= thresholds_(2);
      otherwise
        error('Invalid threshold option?');
    end
    push_();
    updateimage();
    return_focus_from_button_to_overlay(h);
  end

  function thresholds_ = fixthreshold(thresholds_)
    if(isempty(thresholds_) || ~isnumeric(thresholds_) || isscalar(thresholds_))
      thresholds_ = D.d.dat.lastvalidthreshold;
    else
      thresholds_ = [min(thresholds_) max(thresholds_)];
      D.d.dat.lastvalidthreshold = thresholds_;
    end
  end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% main FLIM GUI related callbacks
  function FLIMGUI_backbuttoncallback(h,ev)
    figure(MAIN_GUI_DATA.d.fig);
  end

  function FLIMGUI_featureuimenucallback(h,ev)
    % Determine which uicontext menu was selected, then use it's index
    % number in the array to get the corresponding index in the
    % possible feature array. Then use the feature string to extract
    % the feature from the TDF object and update the plot.
    
  end

  function FLIMGUI_savemasktoflimguicallback(h,ev)
    % This function saves the current mask to the main gui (plots the
    % mask, and puts the mask into the TDF).
    
    % put into TDF
    TDF.deconv_mask(:,:,CH) = D.d.dat.mask;
    
    % This function is essentially a direct copy of the plotmask()
    % function from the main FLIM gui. In the future I might make the
    % plotmask() function external to the main FLIM gui so that both
    % the mask making gui and the FLIM gui can call the same code.
    
    %%%%%%%%%%
    %I am assuming that there will only be (at most) two images in
    %each axes, and that the lower-most image is the intensity map,
    %and that the uppermost image is the previous mask (if there
    %are two). If there is only one, then I assume that it is the
    %intensity map.
    tmpchildren = get(MAIN_GUI_DATA.d.stage1.components.raw_maps_axh{1,CH},'children');
    if(length(tmpchildren) == 2)
      %mask has already been plotted, just set the cdata.
      delete(tmpchildren(1));
      set(MAIN_GUI_DATA.d.stage1.components.raw_maps_axh{1,CH},'children',tmpchildren(2));
    end
    
    %also set nextplot to add (it may already be add, but I won't
    %check).
    set(MAIN_GUI_DATA.d.stage1.components.raw_maps_axh{1,CH},...
      'nextplot','add');
    tmph = imagesc(repmat(TDF.deconv_mask(:,:,CH),[1 1 3]),...
      'parent',MAIN_GUI_DATA.d.stage1.components.raw_maps_axh{1,CH},...
      'alphadata',TDF.deconv_mask(:,:,CH)*D.d.dat.maskalpha);
    
    %register uicontext menu with mask
    set(get(MAIN_GUI_DATA.d.stage1.components.raw_maps_axh{CH},'children'),...
      'UIContextMenu',...
      MAIN_GUI_DATA.d.stage1.components.raw_maps_axh_uicontextmenus(CH));
    %%%%%%%%%%
    
    % set current object back to the mask image
    return_focus_from_button_to_overlay(h);
  end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% other nested functions

  function updateimage
    %This function updates the main plot with the mask that is in the
    %mask stack at the current mask stack index.
    set(D.d.comp.maskimg,'CData',...
      mask_gray_to_rgb_mult(...
      repmat(D.d.dat.mask_stack{D.d.dat.mask_stack_index},[1 1 3]),...
      D.d.dat.maskcolor),...
      'alphadata',...
      D.d.dat.maskalpha*(D.d.dat.mask_stack{D.d.dat.mask_stack_index}));
    update_preview_mask();
  end

%%% mask stack control

  function push_
    %This function puts another mask into the mask stack and increments
    %the mask stack index
    
    D.d.dat.mask_stack_index = numel(D.d.dat.mask_stack)+1;
    mask_stack_size_control();
    D.d.dat.mask_stack{D.d.dat.mask_stack_index} = D.d.dat.mask;
  end

  function swap_
    % This function replaces the current mask on the top of the stack
    % (does not increment the mask stack index). This is used in the
    % painting mode to avoid rapidly filling the stack with each paint
    % stroke. Instead, a watching timer is implemented so that the
    % stack index is only incremented after a certain amount of time
    % has past if painting.
    D.d.dat.mask_stack{D.d.dat.mask_stack_index} = D.d.dat.mask;
  end

  function mask_stack_size_control
    %this function ensures that the mask stack stays below a certain
    %size, this limits the depth of the undo/redo operations.
    %
    %This should be called each time push_ is called, that way I can
    %assume that the most I will need to delete is 1 image from the
    %stack.
    if(D.d.dat.mask_stack_index > MASK_STACK_LIMIT)
      overdraft = D.d.dat.mask_stack_index - MASK_STACK_LIMIT;
      D.d.dat.mask_stack(1:overdraft) = [];
      D.d.dat.mask_stack_index = D.d.dat.mask_stack_index - overdraft;
    end
  end

%%% mask grayscale to rgb conversion
  function mask = mask_gray_to_rgb_mult(mask,rgb)
    %   This function makes the code more concise for changing the mask
    %   color. Using a for loop instead of repmat is more memory
    %   efficient (maybe it is faster because it avoids memory
    %   allocation?
    %
    %   mask - 3D grayscale image (2D array with repeated elements to
    %   make it 3D).
    %
    %   rgb - triplet vector of colors.
    mask = double(mask); %for color! Otherwise logical will threshold it.
    for n = 1 : 3
      mask(:,:,n) = mask(:,:,n) * rgb(n);
    end
  end

%%% Return focus from button to overlay
  function return_focus_from_button_to_overlay(h)
    % This function solves a problem that I had:
    %
    %   1) User clicks a button.
    %
    %   2) User moves mouse back over overlay.
    %
    %       Desired behavior here is that the overlay automatically
    %       starts updating itself without the user having to click
    %       anything.
    %
    %       However, the actual behavior if nothing is done is that the
    %       current object of the figure remains as the button that was
    %       just pressed (and since I rely on the current object
    %       property to start rendering the overlay) and the overlay
    %       does not update.
    %
    %       My first workaround was to set the CurrentObject property
    %       of the figure back to the mask image. This seemed to work.
    %       But later I found that if I click on a button, move the
    %       mouse over the overlay (works), then press shift... the
    %       overlay does not update. This is because pressing shift (or
    %       any other modifier probably) somehow sent the focus back
    %       to the button (or I never really fully removed focus from
    %       the button in the first place).
    %
    %       This function seems to sucessfully take focus away from the
    %       button by disabling the button, setting the current object
    %       to the overlay, calling drawnow, and then reenabling the
    %       button.
    if(~isempty(h))
      set(h,'Enable','off');
    end
    set(D.d.paint.pf,'CurrentObject',D.d.paint.pmaskh);
    if(~isempty(h))
      drawnow;
      set(h,'Enable','On');
    end
  end
end









