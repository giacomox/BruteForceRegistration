function varargout = SelectFeatures(varargin)
% [tform fix_points moving_points] = SelectFeatures (Img1, Img2)
%
%
%-------------------------------------------
% by Giacomo Benvenuti
% <giacomox@gmail.com>
% Repository
% https://github.com/giacomox/RetinoMapModel
%-------------------------------------------

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SelectFeatures_OpeningFcn, ...
                   'gui_OutputFcn',  @SelectFeatures_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before SelectFeatures is made visible.
function SelectFeatures_OpeningFcn(obj, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SelectFeatures (see VARARGIN)
data = guidata(obj);
if nargin >0 
handles.Img1 = varargin{1};
axes(data.axes1)
imshow(imadjust(handles.Img1))
data.axes1.XTick = [];
data.axes1.XColor = 'r'
data.axes1.YTick = [];
data.axes1.YColor = 'r'
data.axes1.LineWidth = 3;
end
if nargin >1 
handles.Img2 = varargin{2};
axes(data.axes2)
imshow(imadjust(handles.Img2))
data.axes2.XTick = [];
data.axes2.XColor = 'r'
data.axes2.YTick = [];
data.axes2.YColor = 'r'
data.axes2.LineWidth = 3;
end

% Choose default command line output for SelectFeatures
handles.output = obj;

handles.Features_anchors = [];
handles.Hpoints = [];
handles.tform = [] ;
handles.COSFIREout = 0;
handles.Control_segmentation.Visible = 'off';
data.text2.String=['(1) Use the Zoom and Pan tools to visualize similar areas in the two images. ' ... 
    '(2) Set the number of anchors you want to select ' ...
    '(3) Press NEW ANCHOR to start the selection'] ;


% Update handles structure
guidata(obj, handles);

% UIWAIT makes SelectFeatures wait for user response (see UIRESUME)
 uiwait(handles.figure1);



% --- Outputs from this function are returned to the command line.
function varargout = SelectFeatures_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Get default command line output from handles structure
data = guidata(hObject);


varargout{1} =  data.tform ;
movingpoints = squeeze(data.Features_anchors(:,1,:))';
fixpoints = squeeze(data.Features_anchors(:,2,:))';
varargout{2} =  fixpoints ;
varargout{3} =  movingpoints ;

delete(handles.figure1);


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(obj, eventdata, handles)
data = guidata(obj);

N = str2num(data.points_num.String);
col = jet(N);
ct = 0;
for i = 1:N
 ct = ct+1
data.text2.String=[ '(' num2str(i) ' / '  num2str(N) ') Select a feature in Img A... (press enter to esc and RESET to restart)'] ;
axes(data.axes1); axis on

try [x,y] = ginput(1); catch end
F(:,1,i) = [x,y];
hold on 
hp(ct) = scatter(x,y,60,'+','MarkerEdgeColor',col(i,:))

axis off 
data.text2.String='Cool!' ;
pause (.5)

% Select fig B
axes(data.axes2); axis on
data.text2.String=[ '(' num2str(i) ' / ' num2str(N) ') Select coresponding feature in Img B.. (press enter to esc and RESET to restart).'] ;
axes(data.axes2);
try [x,y] = ginput(1); catch end
F(:,2,i) = [x,y];
hold on 
hp(ct) = scatter(x,y,60,'+','MarkerEdgeColor',col(i,:))

axis off
data.text2.String='Cool!' ;
pause (.5)
end
handles.Features_anchors = F;
handles.Hpoints = hp;
Selected_Points = F;

data.text2.String='Click SUBMIT to check the transformation' 

 % Update handles structure
 guidata(obj, handles);

% --- Executes on button press in submit.
function submit_Callback(obj, eventdata, handles)
data = guidata(obj);

axes(data.axes1);imshow(imadjust(handles.Img1));
axes(data.axes2);imshow(imadjust(handles.Img2));
I = imadjust(handles.Img1) ;
J =imadjust( handles.Img2);

Selected_Points = data.Features_anchors ;

movingpoints = squeeze(data.Features_anchors(:,1,:))';
fixpoints = squeeze(data.Features_anchors(:,2,:))';

% Registration algorithm
v = data.methods.Value ;% pop-up selection
switch v
    case 1
        tform= fitgeotrans(movingpoints, fixpoints,'projective');
    case 2
        tform= fitgeotrans(movingpoints, fixpoints,'nonreflectivesimilarity');
    case 3
        tform= fitgeotrans(movingpoints, fixpoints,'affine');
    case 4
          tform= fitgeotrans(movingpoints, fixpoints,'polynomial',2);
    case 5 
            tform= fitgeotrans(movingpoints, fixpoints,'pwl');
end
handles.tform = tform ;
Ir = imwarp(I,tform,'OutputView', imref2d(size(I)));

% Axes 1
axes(data.axes1); cla
imshow(Ir)
xlim([1 size(Ir,1)])
ylim([1 size(Ir,2)])


% Axes 2
axes(data.axes2); cla

imshow(J); hold on
if handles.COSFIREout
 cs = COSFIRESegmentation(imadjust(Ir)); 
handles.cs = cs; 
[c h]= contour(cs.segmented,[10 10]);
h.Color = 'r';
else
[x y] = Segmentation(Ir);
h = scatter(x,y,1,'.');
h.MarkerEdgeColor = 'r' ;
h.MarkerFaceColor = 'none'
h.MarkerEdgeAlpha = .1;
end

data.text2.String = 'If the match is good, close te GUI window to get the GUI function output. To try again push RESET'
handles.TransIMG = Ir; % cropped image
guidata(obj, handles);

% --- Executes on button press in load_imageA.
function load_imageA_Callback(obj, eventdata, handles)
 % Load and dispaly ImgA
 
 % Load objects data
 data = guidata(obj);
 [Fn , pathh] = uigetfile('.bmp', 'Select image A');
 [I map] = imread([pathh Fn]);
 handles.Img1  = ind2gray(I,map);
 axes(data.axes1);
 imshow(imadjust(handles.Img1));
 % Update handles structure
 guidata(obj, handles);


% --- Executes on button press in load_imageB.
function load_imageB_Callback(obj, eventdata, handles)
% Load and dispaly ImgB
 
% Load objects data
data = guidata(obj);
[Fn , pathh] = uigetfile('.bmp', 'Select image B');
[I map] = imread([pathh Fn]);
handles.Img2  = ind2gray(I,map);
axes(data.axes2);
imshow(imadjust(handles.Img2));
% Update handles structure
guidata(obj, handles);


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
if isequal(get(hObject, 'waitstatus'), 'waiting')
% The GUI is still in UIWAIT, us UIRESUME
uiresume(hObject);
else
% The GUI is no longer waiting, just close it
delete(hObject);
end


function [ col row] = Segmentation(varargin)
J = varargin{1} ;

if nargin>1
 n = varargin{2} ;  
else
 n = .12 ;   
end
J = imadjust(J);
Jr = rangefilt(J);
Jr2  = mat2gray(Jr);

f = 1/9*ones(3);
Jr2 = filter2(f,Jr2);

I  = imbinarize(Jr2,n);

se     = strel('cube',3);
I       = imerode(I,se);


[row col] = find(I==1);



function [x y] = Segmentation2(I,Segm_Param,Segm_Smooth,Segm_thr)
Segm_type = 'zerocross';
normImage = mat2gray(I);
BW = edge(normImage, Segm_type , Segm_Param);
f = 1/9*ones(5);
BW2 = filter2(f,BW);
BW3 = im2bw(BW2);
filled = imfill(BW3,'holes');

holes = filled & ~BW3;
bigholes = bwareaopen(holes, Segm_thr);
smallholes = holes & ~bigholes;
BW4 = BW3 | smallholes;

BW5 = abs(BW4-1);
f = 1/9*ones(round(Segm_Smooth));
BW6 = filter2(f,BW5);
BW7 = imbinarize(BW6,0.1);
Mask = BW7;
[contour_mask h] = contour(Mask,[1 1]);
delete(h);
 x = contour_mask(1,:);
 y = contour_mask(2,:);


% --- Executes on slider movement.
function Control_segmentation_Callback(hObject, eventdata, handles)

% Zoom on
data = guidata(hObject);
t =round(get(hObject,'Value')) ; 
t

% Axes 2
axes(data.axes2); cla
imshow(imadjust(handles.Img2)); hold on
if handles.COSFIREout
    
    if isfield(handles,'cs') % depends on at which point you click COSFIRE
        cs = handles.cs;
    else
        cs = COSFIRESegmentation(imadjust(handles.TransIMG));
        handles.cs = cs;
        
    end
 
[c h] = contour(cs.respimage,[t t]);
h.Color = 'r';
else 
[x y] = Segmentation(Ir);
h = scatter(x,y,1,'.');
h.MarkerEdgeColor = 'r' ;
h.MarkerFaceColor = 'none'
h.MarkerEdgeAlpha = .1;
end


% % Axes 2
% axes(data.axes2); cla
% [x y] = Segmentation(Ir,t);
% imshow(J); hold on
% h = scatter(x,y,1,'.')
% h.MarkerEdgeColor = 'r' ;
% h.MarkerFaceColor = 'none'
% h.MarkerEdgeAlpha = .1

guidata(hObject, handles);
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function Control_segmentation_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Control_segmentation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
    set(hObject,'Value',.12);
    set(hObject,'Max',1);
    set(hObject,'Min',0);
end


% --------------------------------------------------------------------
function uitoggletool1_OnCallback(hObject, eventdata, handles)

disp('Zoom ON')
zoom on


% --------------------------------------------------------------------
function uitoggletool2_OnCallback(hObject, eventdata, handles)

disp('Zoom OUT')
zoom out


% --------------------------------------------------------------------
function uitoggletool3_OnCallback(hObject, eventdata, handles)

pan on


% --- Executes on selection change in methods.
function methods_Callback(hObject, eventdata, handles)
% hObject    handle to methods (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns methods contents as cell array
%        contents{get(hObject,'Value')} returns selected item from methods


% --- Executes during object creation, after setting all properties.
function methods_CreateFcn(hObject, eventdata, handles)
% hObject    handle to methods (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function points_num_Callback(hObject, eventdata, handles)

%get(hObject,'String');
N =str2num(get(hObject,'String')) 


% --- Executes during object creation, after setting all properties.
function points_num_CreateFcn(hObject, eventdata, handles)
% hObject    handle to points_num (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
    set(hObject,'String','6');
end


% --- Executes on button press in pushbutton7.
function pushbutton7_Callback(hObject, eventdata, handles)
data = guidata(hObject);
% RESET selections (kee)
handles.Features_anchors = [];
axes(data.axes1);xl = xlim; yl=ylim; imshow(imadjust(handles.Img1)); xlim(xl); ylim(yl);
axes(data.axes2);xl = xlim; yl=ylim;imshow(imadjust(handles.Img2)); xlim(xl); ylim(yl);


% --- Executes on button press in COSFIRE.
function COSFIRE_Callback(hObject, eventdata, handles)
data = guidata(hObject);
handles.COSFIREout =  get(hObject,'Value');
data.text2.String = 'Be sure COSFIRE repository is added to the path. Use the slider on the right to refine the contour';
if handles.COSFIREout 
handles.Control_segmentation.Visible = 'on';
else
handles.Control_segmentation.Visible = 'off';
end
guidata(hObject, handles);
