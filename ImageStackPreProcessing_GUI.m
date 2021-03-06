function varargout = ImageStackPreProcessing_GUI(varargin)
% IMAGESTACKPREPROCESSING_GUI MATLAB code for ImageStackPreProcessing_GUI.fig
%      IMAGESTACKPREPROCESSING_GUI, by itself, creates a new IMAGESTACKPREPROCESSING_GUI or raises the existing
%      singleton*.
%
%      H = IMAGESTACKPREPROCESSING_GUI returns the handle to a new IMAGESTACKPREPROCESSING_GUI or the handle to
%      the existing singleton*.
%
%      IMAGESTACKPREPROCESSING_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IMAGESTACKPREPROCESSING_GUI.M with the given input arguments.
%
%      IMAGESTACKPREPROCESSING_GUI('Property','Value',...) creates a new IMAGESTACKPREPROCESSING_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ImageStackPreProcessing_GUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ImageStackPreProcessing_GUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ImageStackPreProcessing_GUI

% Last Modified by GUIDE v2.5 16-Jul-2019 17:31:17

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ImageStackPreProcessing_GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @ImageStackPreProcessing_GUI_OutputFcn, ...
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


% --- Executes just before ImageStackPreProcessing_GUI is made visible.
function ImageStackPreProcessing_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ImageStackPreProcessing_GUI (see VARARGIN)

% Choose default command line output for ImageStackPreProcessing_GUI
handles.output = hObject;

if ~isempty(varargin)
    if isnumeric(varargin{1})
        handles.ImgSeq = varargin{1};
        handles.ImgSeqLoaded = 1;
        
    elseif exist(varargin{1},'dir')
        handles.PathName = varargin{1};
        FilterSpec = {'*.tif; *.raw; *.mat'};
        DialogTitle = 'Select the image sequence';
        [FileName,PathName,FilterIndex] = uigetfile(FilterSpec,DialogTitle,handles.PathName);
        if FilterIndex
            [handles.PathName, handles.FileName, handles.ExtName] = fileparts([PathName,FileName]);
            handles = loadData(handles,eventdata);
            handles.ImgSeqLoaded = 1;
        end
        
    elseif exist(varargin{1},'file')==2
        [handles.PathName, handles.FileName, handles.ExtName] = fileparts(varargin{1});
        handles = loadData(handles,eventdata);
        handles.ImgSeqLoaded = 1;
    end
end
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ImageStackPreProcessing_GUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);

function handles = loadData(handles,eventdata)

FullFileName = fullfile(handles.PathName, [handles.FileName, handles.ExtName]);

if strcmp(handles.ExtName, '.tif') || strcmp(handles.ExtName, '.tiff')
%     nFrames = input('Please insert number of frames for .tif file: ');
    handles.ImgSeq = imreadalltiff(FullFileName);
    handles.ImgSeqLoaded = 1;
elseif strcmp(handles.ExtName, '.raw')
%     nFrames = input('Please insert number of frames for .raw file: ');
    nFrames = inf;
    x = input('Please insert number of pixels in "x" dir: ');
    y = input('Please insert number of pixels in "y" dir: ');
    handles.ImgSeq = imreadallraw(FullFileName,x,y,nFrames,'*float32');
    handles.ImgSeqLoaded = 1;
elseif strcmp(handles.ExtName, '.mat')
    mFile = matfile(FullFileName);
    fn = fieldnames(mFile);
    count_3d = 0;
    for Nfn = 1:length(fn)
        if numel(size(eval(['mFile.',fn{Nfn}])))==3
            count_3d = count_3d+1;
            idx_3d(count_3d) = Nfn;
        end
    end
    if ~isempty(idx_3d)
        eval(['handles.ImgSeq = mFile.',fn{idx_3d(1)},';']);
        handles.ImgSeqLoaded = 1;
    end
    delete(mFile);
else
    disp('Invalid data format. Data format could be ".tif", ".raw", or ".mat".')
end

[dim1,dim2,nFrames] = size(handles.ImgSeq);
handles.dim1 = dim1;
handles.dim2 = dim2;
handles.nFrames = nFrames;

if isfield(handles,'Mask')
    if size(handles.Mask,1) ~= handles.dim1 || size(handles.Mask,2) ~= handles.dim2
        handles.Mask = ones(handles.dim1,handles.dim2);
        disp('The Mask size does not agrees with image sequence.\')
        disp('Mask is set to all ones.\n')
    end
else
    handles.Mask = ones(handles.dim1,handles.dim2);
end
% Get indicies inside the Mask.
[handles.rMask,handles.cMask] = find(handles.Mask > 0);
handles.idxMask = sub2ind(size(handles.Mask),handles.rMask,handles.cMask);

set(handles.FramesSlider,'Max',nFrames);
set(handles.FramesSlider,'Min',1);
minStep = 1/nFrames;
maxStep = 10/nFrames;
set(handles.FramesSlider,'SliderStep',[minStep maxStep]);
set(handles.FramesSlider,'value',1);
metaData.playFlag = 0;
set(handles.Play,'userData',metaData);
set(handles.Stop,'visible','off');
% addlistener(handles.FramesSlider,'ContinuousValueChange',@slider_frames_Callback1);
handles = loadFrame(handles,eventdata,1);

Frate_default = 150;
handles.Frate = Str2NumFromHandle(handles.SampFreq,Frate_default);

guidata(gcbo, handles);
n = 0;

function handles = loadFrame(handles,eventdata,frameNumber)
MaxDispVal_default = 1;
handles.MaxVal = Str2NumFromHandle(handles.MaxDispVal,MaxDispVal_default);
MinDispVal_default = 0;
handles.MinVal = Str2NumFromHandle(handles.MinDispVal,MinDispVal_default);
MinVal = handles.MinVal;
MaxVal = handles.MaxVal;
% imagesc frame and mask
if isfield(handles,'ImgSeq')
    if handles.ImgSeqLoaded
        if frameNumber > 0 && frameNumber <= handles.nFrames
            if get(handles.MaskChk,'value')
                thisframe = double(handles.ImgSeq(:,:,frameNumber)).*double(handles.Mask);
            else
                thisframe = handles.ImgSeq(:,:,frameNumber);
            end
            axes(handles.MainAxes);cla
            imagesc(thisframe,[MinVal,MaxVal]);
            colormap jet;
            hold on;
            set(handles.FrameNumber,'String',sprintf('%d of %d',frameNumber,handles.nFrames));
            set(handles.FramesSlider,'value',frameNumber);
        end
    end
end

% --- Outputs from this function are returned to the command line.
function varargout = ImageStackPreProcessing_GUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in LoadImgSeq.
function LoadImgSeq_Callback(hObject, eventdata, handles)
% hObject    handle to LoadImgSeq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
FilterSpec = {'*.tif; *.raw; *.mat'};
DialogTitle = 'Select the image sequence';
[FileName,PathName,FilterIndex] = uigetfile(FilterSpec,DialogTitle);
if FilterIndex
    [handles.PathName, handles.FileName, handles.ExtName] = fileparts([PathName,FileName]);
    handles = loadData(handles,eventdata);
    handles.ImgSeqLoaded = 1;
end
guidata(hObject, handles);

% --- Executes on button press in LoadMask.
function LoadMask_Callback(hObject, eventdata, handles)
% hObject    handle to LoadMask (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
FilterSpec = {'*.tif; *.raw; *.mat'};
DialogTitle = 'Select the mask image';
[MaskFileName,MaskPathName,FilterIndex] = uigetfile(FilterSpec,DialogTitle);
if FilterIndex
    [handles.MaskPathName, handles.MaskFileName, handles.MaskExtName] = fileparts([MaskPathName,MaskFileName]);
    handles = loadMaskData(handles);
    handles.Mask = handles.Mask > 0; % Make sure the maske is binary
    % Get indicies inside the Mask.
    [handles.rMask,handles.cMask] = find(handles.Mask > 0);
    handles.idxMask = sub2ind(size(handles.Mask),handles.rMask,handles.cMask);
    guidata(hObject, handles);
end
n = 0;

function handles = loadMaskData(handles)
FullMaskFileName = fullfile(handles.MaskPathName, [handles.MaskFileName, handles.MaskExtName]);

if strcmp(handles.MaskExtName, '.tif') || strcmp(handles.MaskExtName, '.tiff')
    handles.Mask = imread(FullMaskFileName);
elseif strcmp(handles.MaskExtName, '.raw')
    x = input('Please insert number of pixels in "x" dir: ');
    y = input('Please insert number of pixels in "y" dir: ');
    handles.Mask = imreadallraw(FullMaskFileName,x,y,1,'*float32');
elseif strcmp(handles.MaskExtName, '.mat')
    mFile = matfile(FullMaskFileName);
    fn = fieldnames(mFile);
    Nfn = 1;
    keepgoing = 1;
    while keepgoing
        a = eval(['mFile.',fn{Nfn}]);
        if isnumeric(a)
            if size(a,3) == 1
                eval(['handles.Mask = mFile.',fn{Nfn},';']);
                handles.ImgSeqLoaded = 1;
                keepgoing = 0;
            end
        end
        Nfn = Nfn+1;
        if Nfn > length(fn)
            keepgoing = 0;
        end
    end
    delete(mFile);
else
    handles.Mask = ones(handles.dim1,handles.dim2);
    disp('Invalid data format. Data format could be ".tif", ".raw", or ".mat".\n')
    disp('Mask is set to all ones.\n')
end
if isfield(handles,'dim1') && isfield(handles,'dim2')
    if size(handles.Mask,1) ~= handles.dim1 || size(handles.Mask,2) ~= handles.dim2
        handles.Mask = ones(handles.dim1,handles.dim2);
        disp('The Mask size does not agrees with image sequence.\')
        disp('Mask is set to all ones.\n')
    end
end
n=0;

% --- Executes on button press in LoadNoStim.
function LoadNoStim_Callback(hObject, eventdata, handles)
% hObject    handle to LoadNoStim (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
FilterSpec = {'*.tif; *.raw; *.mat'};
DialogTitle = 'Select the image sequence';
[FileName,PathName,FilterIndex] = uigetfile(FilterSpec,DialogTitle);
if FilterIndex
    [handles.NoStimPathName, handles.NoStimFileName, handles.NoStimExtName] = fileparts([PathName,FileName]);
    handles = loadNoStim(handles,eventdata);
    handles.NoStimLoaded = 1;
end
guidata(hObject, handles);


function handles = loadNoStim(handles,eventdata)

FullFileName = fullfile(handles.NoStimPathName, [handles.NoStimFileName, handles.NoStimExtName]);

if strcmp(handles.NoStimExtName, '.tif') || strcmp(handles.NoStimExtName, '.tiff')
    handles.NoStim = imreadalltiff(FullFileName);
    handles.NoStimLoaded = 1;
elseif strcmp(handles.NoStimExtName, '.raw')
    nFrames = inf;
    x = input('Please insert number of pixels in "x" dir: ');
    y = input('Please insert number of pixels in "y" dir: ');
    handles.NoStim = imreadallraw(FullFileName,x,y,nFrames,'*float32');
    handles.NoStimLoaded = 1;
elseif strcmp(handles.NoStimExtName, '.mat')
    mFile = matfile(FullFileName);
    fn = fieldnames(mFile);
    count_3d = 0;
    for Nfn = 1:length(fn)
        if numel(size(eval(['mFile.',fn{Nfn}])))==3
            count_3d = count_3d+1;
            idx_3d(count_3d) = Nfn;
        end
    end
    if ~isempty(idx_3d)
        eval(['handles.NoStim = mFile.',fn{idx_3d(1)},';']);
        handles.NoStimLoaded = 1;
    end
    delete(mFile);
else
    disp('Invalid data format. Data format could be ".tif", ".raw", or ".mat".')
end

[dim1,dim2,nFrames] = size(handles.NoStim);
handles.NoStimdim1 = dim1;
handles.NoStimdim2 = dim2;
handles.NoStimnFrames = nFrames;

guidata(gcbo, handles);
n = 0;


% --- Executes on button press in NoStimChb.
function NoStimChb_Callback(hObject, eventdata, handles)
% hObject    handle to NoStimChb (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of NoStimChb
if get(hObject,'Value')
    set(handles.LoadNoStim,'enable','on')
    handles.useNoStim = 1;
else
    set(handles.LoadNoStim,'enable','off')
    handles.useNoStim = 0;
end
guidata(hObject, handles);

function SampFreq_Callback(hObject, eventdata, handles)
% hObject    handle to SampFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SampFreq as text
%        str2double(get(hObject,'String')) returns contents of SampFreq as a double
SampFreq_default = 150;
handles.SampFreq = Str2NumFromHandle(hObject,SampFreq_default);
n = 0;


% --- Executes during object creation, after setting all properties.
function SampFreq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SampFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in SpatialGaussFilter.
function SpatialGaussFilter_Callback(hObject, eventdata, handles)
% hObject    handle to SpatialGaussFilter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
oldStr = get(hObject,'string');
oldStr = 'Spatial Gaussian Filter';
newStr = 'Running...';
set(hObject,'string',newStr)
pause(eps);

SigmaGauss_default = 1;
handles.SigmaGauss = Str2NumFromHandle(handles.sigma,SigmaGauss_default);

param.GaussWindow = 4*handles.SigmaGauss+1;
param.Sigma       = handles.SigmaGauss;
Center  = fix([param.GaussWindow/2,param.GaussWindow/2])+1;
[R,C]   = ndgrid(1:param.GaussWindow, 1:param.GaussWindow);
handles.Gauss2d = gauss2dC(R,C,param.Sigma,Center);


if isfield(handles,'ImgSeqLoaded')
    if handles.ImgSeqLoaded
        for idx = 1:handles.nFrames
            handles.ImgSeq(:,:,idx) = conv2(handles.ImgSeq(:,:,idx),handles.Gauss2d, 'same');
        end
    end
end

handles.useNoStim = get(handles.NoStimChb,'Value');
if handles.useNoStim
    if isfield(handles,'NoStimLoaded')
        if handles.NoStimLoaded
            for idx = 1:handles.NoStimnFrames
                handles.NoStim(:,:,idx) = conv2(handles.NoStim(:,:,idx),handles.Gauss2d, 'same');
            end
        end
    end
end

currentFrame = round(get(handles.FramesSlider,'Value'));
handles = loadFrame(handles,eventdata,currentFrame);

newStr = 'Done!';
set(hObject,'string',newStr)
pause(1);
set(hObject,'string',oldStr)
guidata(gcbo,handles);



function sigma_Callback(hObject, eventdata, handles)
% hObject    handle to sigma (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of sigma as text
%        str2double(get(hObject,'String')) returns contents of sigma as a double
SigmaGauss_default = 1;
handles.SigmaGauss = Str2NumFromHandle(hObject,SigmaGauss_default);
guidata(gcbo,handles);


% --- Executes during object creation, after setting all properties.
function sigma_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sigma (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in PCA.
function PCA_Callback(hObject, eventdata, handles)
% hObject    handle to PCA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
oldStr = get(hObject,'string');
oldStr = 'PCA';
newStr = 'Running...';
set(hObject,'string',newStr)
pause(eps);

if ~isfield(handles,'Mask') && isfield(handles,'ImgSeqLoaded')
    handles.Mask = ones(handles.dim1,handles.dim2);
end
[handles.rMask,handles.cMask] = find(handles.Mask > 0);
handles.idxMask = sub2ind(size(handles.Mask),handles.rMask,handles.cMask);

if get(handles.pcaPCsChb,'Value')
    pcaN_default = 35;
    pcaN_minVal = 1;
    pcaN_maxVal = handles.nFrames;
    handles.pcaN = Str2NumFromHandle(handles.pcaPCs,pcaN_default,pcaN_maxVal,pcaN_minVal);
    M = handles.pcaN;
end

if isfield(handles,'ImgSeqLoaded')
    if handles.ImgSeqLoaded
        X = reshape(handles.ImgSeq, handles.dim1*handles.dim2, handles.nFrames);
        X = X';
        [U, S, V] = svd(X(:,handles.idxMask),'econ');
        eigVals = (diag(S)).^2;
        eigValsCum = cumsum(eigVals);
        eigValsCum = 100*eigValsCum/eigValsCum(end);
        if get(handles.pcaPowerChb,'Value')
            pcaP_default = 100;
            pcaP_maxVal = 100;
            pcaP_minVal = 0;
            handles.pcaP = Str2NumFromHandle(handles.pcaPower,pcaP_default,pcaP_maxVal,pcaP_minVal);
            m = abs(eigValsCum - handles.pcaP);
            M = find(m == min(m));
        end
        
        Vtemp = zeros(handles.dim1*handles.dim2, handles.nFrames);
        Vtemp(handles.idxMask,:) = V;
        V = Vtemp;
        Xrecon = U(:,1:M) * S(1:M,1:M) * V(:,1:M)';
        Xrecon = Xrecon';
        Xrecon = reshape(Xrecon,handles.dim1,handles.dim2, handles.nFrames);
        handles.ImgSeq = Xrecon;
    end
end

handles.useNoStim = get(handles.NoStimChb,'Value');
if handles.useNoStim
    if isfield(handles,'NoStimLoaded')
        if handles.NoStimLoaded
            X = reshape(handles.NoStim, handles.NoStimdim1*handles.NoStimdim2, handles.NoStimnFrames);
            X = X';
            [U, S, V] = svd(X(:,handles.idxMask),'econ');
            eigVals = (diag(S)).^2;
            eigValsCum = cumsum(eigVals);
            eigValsCum = 100*eigValsCum/eigValsCum(end);
            if get(handles.pcaPowerChb,'Value')
                pcaP_default = 100;
                pcaP_maxVal = 100;
                handles.pcaP = Str2NumFromHandle(handles.pcaPower,pcaP_default,pcaP_maxVal);
                m = abs(eigValsCum - handles.pcaP);
                M = find(m == min(m));
            end
            
            Vtemp = zeros(handles.NoStimdim1*handles.NoStimdim2, handles.NoStimnFrames);
            Vtemp(handles.idxMask,:) = V;
            V = Vtemp;
            Xrecon = U(:,1:M) * S(1:M,1:M) * V(:,1:M)';
            Xrecon = Xrecon';
            Xrecon = reshape(Xrecon,handles.NoStimdim1,handles.NoStimdim2, handles.NoStimnFrames);
            handles.NoStim = Xrecon;
        end
    end
end

currentFrame = round(get(handles.FramesSlider,'Value'));
handles = loadFrame(handles,eventdata,currentFrame);

newStr = 'Done!';
set(hObject,'string',newStr)
pause(1);
set(hObject,'string',oldStr)
guidata(gcbo,handles);


% --- Executes on button press in pcaPowerChb.
function pcaPowerChb_Callback(hObject, eventdata, handles)
% hObject    handle to pcaPowerChb (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of pcaPowerChb
if get(hObject,'Value')
    set(handles.pcaPower,'Enable','on')
    set(handles.pcaPCs,'Enable','off')
    set(handles.pcaPCsChb,'Value',0)
else
    set(handles.pcaPower,'Enable','off')
    set(handles.pcaPCs,'Enable','on');
    set(handles.pcaPCsChb,'Value',1)
end
guidata(gcbo,handles);

function pcaPower_Callback(hObject, eventdata, handles)
% hObject    handle to pcaPower (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of pcaPower as text
%        str2double(get(hObject,'String')) returns contents of pcaPower as a double
pcaP_default = 100;
pcaP_maxVal = 100;
pcaP_minVal = 0;
handles.pcaP = Str2NumFromHandle(handles.pcaPower,pcaP_default,pcaP_maxVal,pcaP_minVal);
guidata(gcbo,handles);

% --- Executes during object creation, after setting all properties.
function pcaPower_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pcaPower (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function pcaPCs_Callback(hObject, eventdata, handles)
% hObject    handle to pcaPCs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of pcaPCs as text
%        str2double(get(hObject,'String')) returns contents of pcaPCs as a double
pcaN_default = 35;
handles.pcaN = Str2NumFromHandle(handles.pcaPCs,pcaN_default);
guidata(gcbo,handles);

% --- Executes during object creation, after setting all properties.
function pcaPCs_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pcaPCs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pcaPCsChb.
function pcaPCsChb_Callback(hObject, eventdata, handles)
% hObject    handle to pcaPCsChb (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of pcaPCsChb
if get(hObject,'Value')
    set(handles.pcaPower,'Enable','off')
    set(handles.pcaPCs,'Enable','on')
    set(handles.pcaPowerChb,'Value',0)
else
    set(handles.pcaPower,'Enable','on')
    set(handles.pcaPCs,'Enable','off');
    set(handles.pcaPowerChb,'Value',1)
end

% --- Executes on button press in TempGaussFilter.
function TempGaussFilter_Callback(hObject, eventdata, handles)
% hObject    handle to TempGaussFilter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
oldStr = get(hObject,'string');
oldStr = 'Temporal Gaussian Filter';
newStr = 'Running...';
set(hObject,'string',newStr)
pause(eps);

Frate_default = 150;
handles.Frate = Str2NumFromHandle(handles.SampFreq,Frate_default);

if get(handles.LPF,'Value')
    handles.filtType = 'LPF';
    F1Gauss_default = 0;
    F1Gauss_maxVal = handles.Frate/2-eps;
    handles.F1Gauss = Str2NumFromHandle(handles.Fpass1Gauss,F1Gauss_default,F1Gauss_maxVal);
    handles.G = LPF_Gaussian(handles.F1Gauss,handles.Frate);
elseif get(handles.BPF,'Value')
    handles.filtType = 'BPF';
    F2Gauss_default = handles.Frate/2;
    F2Gauss_maxVal = handles.Frate/2;
    handles.F2Gauss = Str2NumFromHandle(handles.Fpass2Gauss,F2Gauss_default,F2Gauss_maxVal);
    F1Gauss_default = 0;
    F1Gauss_maxVal = handles.F2Gauss;
    handles.F1Gauss = Str2NumFromHandle(handles.Fpass1Gauss,F1Gauss_default,F1Gauss_maxVal);

    if handles.F1Gauss == 0
        handles.F1Gauss = handles.F2Gauss/10;
        set(handles.Fpass1Gauss,'string',num2str(handles.F1Gauss))
    end
    handles.G = BPF_Gaussian(handles.F1Gauss,handles.F2Gauss,handles.Frate);
elseif get(handles.HPF,'Value')
    handles.filtType = 'HPF';
    F2Gauss_default = handles.Frate/2;
    F2Gauss_maxVal = handles.Frate/2;
    handles.F2Gauss = Str2NumFromHandle(handles.Fpass2Gauss,F2Gauss_default,F2Gauss_maxVal);
    handles.G = HPF_Gaussian(handles.F2Gauss,handles.Frate);
end

if isfield(handles,'ImgSeqLoaded')
    if handles.ImgSeqLoaded
        for r = 1:handles.dim1
            for c = 1:handles.dim2
                sig = handles.ImgSeq(r,c,:); sig = double(sig(:));
                sig = filtfilt(handles.G,1,sig); sig = single(sig(:));
                handles.ImgSeq(r,c,:) = sig;
            end
        end
    end
end

handles.useNoStim = get(handles.NoStimChb,'Value');
if handles.useNoStim
    if isfield(handles,'NoStimLoaded')
        if handles.NoStimLoaded
            for r = 1:handles.NoStimdim1
                for c = 1:handles.NoStimdim2
                    sig = handles.NoStim(r,c,:); sig = double(sig(:));
                    sig = filtfilt(handles.G,1,sig); sig = single(sig(:));
                    handles.NoStim(r,c,:) = sig;
                end
            end
        end
    end
end

currentFrame = round(get(handles.FramesSlider,'Value'));
handles = loadFrame(handles,eventdata,currentFrame);

newStr = 'Done!';
set(hObject,'string',newStr)
pause(1);
set(hObject,'string',oldStr)
guidata(gcbo,handles);


function Fpass1Gauss_Callback(hObject, eventdata, handles)
% hObject    handle to Fpass1Gauss (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Fpass1Gauss as text
%        str2double(get(hObject,'String')) returns contents of Fpass1Gauss as a double
Frate_default = 150;
handles.Frate = Str2NumFromHandle(handles.SampFreq,Frate_default);

F1Gauss_default = 0;
if get(handles.BPF,'Value')
    F1Gauss_default = handles.Frate/20;
end
F1Gauss_maxVal = handles.Frate/2 - eps;
handles.F1Gauss = Str2NumFromHandle(hObject,F1Gauss_default,F1Gauss_maxVal);

guidata(gcbo,handles);


% --- Executes during object creation, after setting all properties.
function Fpass1Gauss_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Fpass1Gauss (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function Fpass2Gauss_Callback(hObject, eventdata, handles)
% hObject    handle to Fpass2Gauss (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Fpass2Gauss as text
%        str2double(get(hObject,'String')) returns contents of Fpass2Gauss as a double
Frate_default = 150;
handles.Frate = Str2NumFromHandle(handles.SampFreq,Frate_default);

F2Gauss_default = handles.Frate/2;
F2Gauss_maxVal = handles.Frate/2;
handles.F2Gauss = Str2NumFromHandle(hObject,F2Gauss_default,F2Gauss_maxVal);

guidata(gcbo,handles);

% --- Executes during object creation, after setting all properties.
function Fpass2Gauss_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Fpass2Gauss (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in MedianFilter.
function MedianFilter_Callback(hObject, eventdata, handles)
% hObject    handle to MedianFilter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

oldStr = get(hObject,'string');
oldStr = 'Median Filter';
newStr = 'Running...';
set(hObject,'string',newStr)
pause(eps);

MedWin_default = [3 3];
handles.MedWin = Str2NumFromHandle(handles.WinSizeMedian,MedWin_default);

if isfield(handles,'ImgSeqLoaded')
    if handles.ImgSeqLoaded
        for idx = 1:handles.nFrames
            handles.ImgSeq(:,:,idx) = medfilt2(handles.ImgSeq(:,:,idx), handles.MedWin);
        end
    end
end

handles.useNoStim = get(handles.NoStimChb,'Value');
if handles.useNoStim
    if isfield(handles,'NoStimLoaded')
        if handles.NoStimLoaded
            for idx = 1:handles.NoStimnFrames
                handles.NoStim(:,:,idx) = medfilt2(handles.NoStim(:,:,idx), handles.MedWin);
            end
        end
    end
end

currentFrame = round(get(handles.FramesSlider,'Value'));
handles = loadFrame(handles,eventdata,currentFrame);

newStr = 'Done!';
set(hObject,'string',newStr)
pause(1);
set(hObject,'string',oldStr)
guidata(gcbo,handles);



function WinSizeMedian_Callback(hObject, eventdata, handles)
% hObject    handle to WinSizeMedian (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of WinSizeMedian as text
%        str2double(get(hObject,'String')) returns contents of WinSizeMedian as a double
MedWin_default = [3 3];
handles.MedWin = Str2NumFromHandle(hObject,MedWin_default);
guidata(gcbo,handles);


% --- Executes during object creation, after setting all properties.
function WinSizeMedian_CreateFcn(hObject, eventdata, handles)
% hObject    handle to WinSizeMedian (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in calcDF.
function calcDF_Callback(hObject, eventdata, handles)
% hObject    handle to calcDF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
oldStr = get(hObject,'string');
oldStr = 'calc DF/Fo';
newStr = 'Running...';
set(hObject,'string',newStr)
pause(eps);


if ~isfield(handles,'ImgSeqLoaded')
    return;
elseif ~handles.ImgSeqLoaded
    return;
end

Frate_default = 150;
handles.Frate = Str2NumFromHandle(handles.SampFreq,Frate_default);

Twin_default = 2;
Twin_maxVal = handles.nFrames / handles.Frate;
handles.Twin = Str2NumFromHandle(handles.MovingWinTrend,Twin_default,Twin_maxVal);

Ts_default = 1;
Ts_maxVal = handles.Twin;
handles.Ts = Str2NumFromHandle(handles.StepSizeTrend,Ts_default,Ts_maxVal);

handles.useNoStim = get(handles.NoStimChb,'Value');
    
if handles.useNoStim && handles.NoStimLoaded && ...
        (handles.dim1 == handles.NoStimdim1) && (handles.dim2 == handles.NoStimdim2)...
        && (handles.nFrames == handles.NoStimnFrames)
    
else
    handles.NoStim = handles.ImgSeq;
end

handles.NoStim = single(handles.NoStim);
handles.NoStim(isnan(handles.NoStim)) = 0;
handles.NoStim(isinf(handles.NoStim)) = 0;

n = round(handles.Frate*handles.Twin); n = max(n,1);
if n ~= 1
    for r = 1:handles.dim1
        for c = 1:handles.dim2
            sig = handles.NoStim(r,c,:); sig =sig(:);
            yhat = sig - locdetrend(sig,handles.Frate,[handles.Twin,handles.Ts]);
            handles.NoStim(r,c,:) = yhat;
        end
    end
end

handles.ImgSeq = single(handles.ImgSeq);
handles.ImgSeq = 100*(handles.ImgSeq - handles.NoStim)./handles.NoStim; 
handles.ImgSeq(isnan(handles.ImgSeq)) = 0;
handles.ImgSeq(isinf(handles.ImgSeq)) = 0;

currentFrame = round(get(handles.FramesSlider,'Value'));
handles = loadFrame(handles,eventdata,currentFrame);

newStr = 'Done!';
set(hObject,'string',newStr)
pause(1);
set(hObject,'string',oldStr)
guidata(gcbo,handles);



function MovingWinTrend_Callback(hObject, eventdata, handles)
% hObject    handle to MovingWinTrend (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of MovingWinTrend as text
%        str2double(get(hObject,'String')) returns contents of MovingWinTrend as a double
Twin_default = 2;
handles.Twin = Str2NumFromHandle(hObject,Twin_default);
guidata(gcbo,handles);


% --- Executes during object creation, after setting all properties.
function MovingWinTrend_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MovingWinTrend (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function StepSizeTrend_Callback(hObject, eventdata, handles)
% hObject    handle to StepSizeTrend (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of StepSizeTrend as text
%        str2double(get(hObject,'String')) returns contents of StepSizeTrend as a double
Ts_default = 1;
handles.Ts = Str2NumFromHandle(hObject,Ts_default);
guidata(gcbo,handles);

% --- Executes during object creation, after setting all properties.
function StepSizeTrend_CreateFcn(hObject, eventdata, handles)
% hObject    handle to StepSizeTrend (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function FramesSlider_Callback(hObject, eventdata, handles)
% hObject    handle to FramesSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
frameNumber = round(get(hObject,'Value'));
set(hObject,'Value',frameNumber);
handles = loadFrame(handles,eventdata,frameNumber);
guidata(gcbo,handles);


function slider_frames_Callback1(hObject, eventdata, handles)
handles = guidata(gcbo);
frameNumber = round(get(handles.FramesSlider,'Value'));
set(handles.FramesSlider,'Value',frameNumber);

handles = MinDispVal_Callback(handles.MinDispVal, eventdata, handles);
handles = MaxDispVal_Callback(handles.MaxDispVal, eventdata, handles);
MinVal = handles.MinVal;
MaxVal = handles.MaxVal;

% imagesc frame and mask
if isfield(handles,'ImgSeq')
    if handles.ImgSeqLoaded
        if frameNumber > 0 && frameNumber <= handles.nFrames
            if get(handles.MaskChk,'value')
                thisframe = double(handles.ImgSeq(:,:,frameNumber)).*double(handles.Mask);
            else
                thisframe = handles.ImgSeq(:,:,frameNumber);
            end
            axes(handles.MainAxes);cla
            imagesc(thisframe,[MinVal,MaxVal]);
            colormap jet;
            hold on;
            set(handles.FrameNumber,'String',sprintf('%d of %d',frameNumber,handles.nFrames));
            set(handles.FramesSlider,'value',frameNumber);
%             set(handles.MainAxes,'userdata',frameNumber);
        end
    end
end

% --- Executes during object creation, after setting all properties.
function FramesSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FramesSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in Stop.
function Stop_Callback(hObject, eventdata, handles)
% hObject    handle to Stop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
metaData = get(handles.Play,'userData');
metaData.playFlag = 0;
set(handles.Play,'userData',metaData);
set(hObject,'visible','off');
set(handles.Play,'visible','on');
pause(0.3);

% --- Executes on button press in Play.
function Play_Callback(hObject, eventdata, handles)
% hObject    handle to Play (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(hObject,'visible','off');
set(handles.Stop,'visible','on');
metaData = get(handles.MainAxes,'userData');
metaData.playFlag = 1;
set(hObject,'userData',metaData);
currentFrame = round(get(handles.FramesSlider,'Value'));
maxFrame = get(handles.FramesSlider,'Max');
if currentFrame == maxFrame
    set(handles.FramesSlider,'Value',1);
    currentFrame = 1;
end
while 1
   metaData = get(hObject,'userData');
    if metaData.playFlag == 0
        break;
    end
    if currentFrame <maxFrame
        currentFrame = currentFrame + 1;
        handles = loadFrame(handles,eventdata,currentFrame);
    else
%         pushbutton_stop_Callback(handles.Stop, eventdata, handles)
        Stop_Callback(handles.Stop, eventdata, handles)
        break;
    end
    pause(0.01);
end

% --- Executes on button press in MaskChk.
function MaskChk_Callback(hObject, eventdata, handles)
% hObject    handle to MaskChk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of MaskChk
currentFrame = round(get(handles.FramesSlider,'Value'));
handles = loadFrame(handles,eventdata,currentFrame);
guidata(gcbo,handles);
n=0;


function MinDispVal_Callback(hObject, eventdata, handles)
maxVal = str2num(get(handles.MaxDispVal,'string'));
minVal = -inf;
MinDispVal_default = 0;
handles.MinVal = Str2NumFromHandle(hObject,MinDispVal_default,maxVal,minVal);
% if handles.MaxVal < handles.MinVal
%     handles.MaxVal = handles.MinVal + 1;
%     set(handles.MaxDispVal,'String',handles.MaxVal)
% end
currentFrame = round(get(handles.FramesSlider,'Value'));
handles = loadFrame(handles,eventdata,currentFrame);
guidata(gcbo,handles);

% --- Executes during object creation, after setting all properties.
function MinDispVal_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function MaxDispVal_Callback(hObject, eventdata, handles)
maxVal = inf;
minVal = str2num(get(handles.MinDispVal,'string'));
MaxDispVal_default = 1;
handles.MaxVal = Str2NumFromHandle(hObject,MaxDispVal_default,maxVal,minVal);
% if handles.MaxVal < handles.MinVal
%     handles.MinVal = handles.MaxVal - 1;
%     set(handles.MinDispVal,'String',handles.MinVal)
% end
currentFrame = round(get(handles.FramesSlider,'Value'));
handles = loadFrame(handles,eventdata,currentFrame);
guidata(gcbo,handles);

% --- Executes during object creation, after setting all properties.
function MaxDispVal_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MaxDispVal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function FrameNumber_Callback(hObject, eventdata, handles)
% hObject    handle to FrameNumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of FrameNumber as text
%        str2double(get(hObject,'String')) returns contents of FrameNumber as a double
currentFrame_default = 1;
currentFrame = Str2NumFromHandle(hObject,currentFrame_default);
% currentFrame = round(get(handles.FramesSlider,'Value'));
handles = loadFrame(handles,eventdata,currentFrame);
guidata(gcbo,handles);

% --- Executes during object creation, after setting all properties.
function FrameNumber_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FrameNumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in SelectROI.
function handles = SelectROI_Callback(hObject, eventdata, handles)
% hObject    handle to SelectROI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = SelectROI(hObject, eventdata, handles);
guidata(gcbo,handles);

% --- Executes on button press in SelectPoints.
function SelectPoints_Callback(hObject, eventdata, handles)
% hObject    handle to SelectPoints (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[~, flag] = getimage(handles.MainAxes); % check if there is an image in the main axes
if flag
    [x, y] = ginput;
    x = round(x);
    y = round(y);
    InRange = (x >= 1) & (x <= handles.dim2) & (y >= 1) & (y <= handles.dim1);
    x = x(InRange);
    y = y(InRange);
    handles.ROI.xy = [x';y'];
    handles.ROI.BW = zeros(handles.dim1,handles.dim2)>0;
    for p = 1:length(x)
        handles.ROI.BW(y(p),x(p)) = 1;
    end
    handles.ROI.selected = 1;
    guidata(gcbo,handles);
end


function handles = FstartROI_Callback(hObject, eventdata, handles)
% hObject    handle to FstartROI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of FstartROI as text
%        str2double(get(hObject,'String')) returns contents of FstartROI as a double
FstartROI_default = 1;
FstartROI = Str2NumFromHandle(handles.FstartROI,FstartROI_default);
FstartROI = round(FstartROI);
set(handles.FstartROI,'string',FstartROI);
handles.ROI.Fstart = FstartROI;
guidata(gcbo,handles);

% --- Executes during object creation, after setting all properties.
function FstartROI_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FstartROI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function handles = FendROI_Callback(hObject, eventdata, handles)
% hObject    handle to FendROI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of FendROI as text
%        str2double(get(hObject,'String')) returns contents of FendROI as a double
if isfield(handles,'nFrames')
    FendROI_default = handles.nFrames;
else
    FendROI_default = 1;
end
FendROI = Str2NumFromHandle(handles.FendROI,FendROI_default);
FendROI = round(FendROI);
set(handles.FendROI,'string',FendROI);
handles.ROI.Fend = FendROI;
guidata(gcbo,handles);

% --- Executes during object creation, after setting all properties.
function FendROI_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FendROI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in IntensityTime.
function IntensityTime_Callback(hObject, eventdata, handles)
% hObject    handle to IntensityTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[~, flag] = getimage(handles.MainAxes); % check if there is an image in the main axes
if flag 
    if isfield(handles,'ROI')
        if isfield(handles.ROI,'selected')
            if ~handles.ROI.selected
                handles = SelectROI_Callback(handles.SelectROI, eventdata, handles);
            end
        else
            handles = SelectROI_Callback(handles.SelectROI, eventdata, handles);
        end
    else
        handles = SelectROI_Callback(handles.SelectROI, eventdata, handles);
    end
    
    handles = FstartROI_Callback(handles.FstartROI, eventdata, handles);
    handles = FendROI_Callback(handles.FendROI, eventdata, handles);
    FstartROI = handles.ROI.Fstart;
    FendROI = handles.ROI.Fend;
    handles.IntensitySig = zeros(1,FendROI-FstartROI+1);
    for idx = FstartROI:FendROI
        thisframe = handles.ImgSeq(:,:,idx);
        handles.IntensitySig(idx-FstartROI+1) = mean(thisframe(handles.ROI.BW));
    end
    if isfield(handles,'IntensityFig')
        if ishandle(handles.IntensityFig)
            figure(handles.IntensityFig);
            cla;plot(FstartROI:FendROI, handles.IntensitySig)
            xlabel('frame number')
            ylabel('Mean Intensity')
        else
            posMainFig = get(handles.figure1,'outerposition');
            posIntensityFig = posMainFig/2;
            posIntensityFig(1) = posMainFig(1)-posIntensityFig(3);
            posIntensityFig(2) = posMainFig(2);
            figure('units',get(handles.figure1,'units'),'outerposition',posIntensityFig);
            handles.IntensityFig = gcf;
            set(handles.IntensityFig,'visible','on','numbertitle','off','name','Intensity vs. Time for selected ROI');

            plot(FstartROI:FendROI, handles.IntensitySig)
            xlabel('frame number')
            ylabel('Mean Intensity')
        end
    else
        posMainFig = get(handles.figure1,'outerposition');
        posIntensityFig = posMainFig/2;
        posIntensityFig(1) = posMainFig(1)-posIntensityFig(3);
        posIntensityFig(2) = posMainFig(2);
        figure('units',get(handles.figure1,'units'),'outerposition',posIntensityFig);
        handles.IntensityFig = gcf;
        set(handles.IntensityFig,'visible','on','numbertitle','off','name','Intensity vs. Time for selected ROI');
        
        plot(FstartROI:FendROI,handles.IntensitySig)
        xlabel('frame number')
        ylabel('Mean Intensity')
    end
end
guidata(gcbo,handles);
n=0;


% --- Executes on button press in LPF.
function LPF_Callback(hObject, eventdata, handles)
% hObject    handle to LPF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of LPF
if get(hObject,'Value')
    set(handles.Fpass1Gauss,'Enable','on')
    set(handles.Fpass2Gauss,'Enable','off')
    set(handles.BPF,'Value',0)
    set(handles.HPF,'Value',0)
    
    handles.filtType = 'LPF';
else
    set(handles.Fpass1Gauss,'Enable','on')
    set(handles.Fpass2Gauss,'Enable','on')
    set(handles.BPF,'Value',1)
    set(handles.HPF,'Value',0)
    handles.filtType = 'BPF';
end
guidata(gcbo,handles);

% --- Executes on button press in BPF.
function BPF_Callback(hObject, eventdata, handles)
% hObject    handle to BPF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of BPF
if get(hObject,'Value')
    set(handles.Fpass1Gauss,'Enable','on')
    set(handles.Fpass2Gauss,'Enable','on')
    set(handles.LPF,'Value',0)
    set(handles.HPF,'Value',0)
    
    handles.filtType = 'BPF';
else
    set(handles.Fpass1Gauss,'Enable','off')
    set(handles.Fpass2Gauss,'Enable','on')
    set(handles.LPF,'Value',0)
    set(handles.HPF,'Value',1)
    handles.filtType = 'HPF';
end
guidata(gcbo,handles);

% --- Executes on button press in HPF.
function HPF_Callback(hObject, eventdata, handles)
% hObject    handle to HPF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of HPF
if get(hObject,'Value')
    set(handles.Fpass1Gauss,'Enable','off')
    set(handles.Fpass2Gauss,'Enable','on')
    set(handles.BPF,'Value',0)
    set(handles.LPF,'Value',0)
    
    handles.filtType = 'HPF';
else
    set(handles.Fpass1Gauss,'Enable','on')
    set(handles.Fpass2Gauss,'Enable','off')
    set(handles.LPF,'Value',1)
    set(handles.BPF,'Value',0)
    handles.filtType = 'LPF';
end
guidata(gcbo,handles);

% --- Executes on button press in saveDF.
function saveDF_Callback(hObject, eventdata, handles)
% hObject    handle to saveDF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
oldStr = get(hObject,'string');
oldStr = 'Save Result';
newStr = 'Saving...';
set(hObject,'string',newStr)
pause(eps);


if isfield(handles,'PathName')
    handles.SavePathName = handles.PathName;
else
    handles.SavePathName = pwd; % current folder
end
n = 1;
keepgoing = 1;
while keepgoing
    saveFileName = [handles.SavePathName,'\DF_F0_',num2str(n),'.mat'];
    if exist(saveFileName,'file')
        n = n+1;
    else
        keepgoing = 0;
    end
end
if isfield(handles,'ImgSeq')
    mFileResults = matfile(saveFileName,'Writable',true);
    eval(['mFileResults.DF_F0_', num2str(n),' = handles.ImgSeq;']);
    delete(mFileResults);
end

newStr = 'Done!';
set(hObject,'string',newStr)
pause(1);
set(hObject,'string',oldStr)
guidata(gcbo,handles);


% --- Executes on button press in AboutGUI.
function AboutGUI_Callback(hObject, eventdata, handles)
% hObject    handle to AboutGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if ~isfield(handles,'AboutFig')
    posMonitor = get(0,'MonitorPositions');
    w = posMonitor(3)/6;
    posAboutFig(3) = w;
    posAboutFig(4) = w;%*posMonitor(3)/posMonitor(4);
    posAboutFig(1) = posMonitor(3)/2-posAboutFig(3)/2;
    posAboutFig(2) = posMonitor(4)/2-0*posAboutFig(4)/2;
    figure('MenuBar','none','ToolBar','none','units',get(0,'units'),'position',posAboutFig);
    
    handles.AboutFig = gcf;
    set(handles.AboutFig,'visible','on','numbertitle','off','Resize','off','name','About GUI');
end
AboutGUIWin

function AboutGUIWin
a = 0.2;
x = -3:a:3;
y = -3:a:3;
ax=axes;
set(ax,'position',[0 0 1 1])
axis off
[xx,yy] = meshgrid(x,y);
zz = peaks(xx,yy);
hold on
pcolor(x,y,zz);
axis([-3 3 -3 3]);
colormap((jet+white)/2);
shading interp
[px,py] = gradient(zz,.2,.2);
c = [1 1 1]*0.7;
quiver(x,y,px,py,2,'color',c);

maxX = max(x); minX = min(x); dx = maxX - minX;
maxY = max(y); minY = min(y); dy = maxY - minY;

txtStr = 'OFAMM Preprocessing v.1.0';
xt = minX + dx*0.5;
yt = minY + dy*0.9;
text(xt,yt,txtStr,'fontsize',14,'FontWeight','bold','fontname','times','HorizontalAlignment','center');

txtStr = 'A toolbox to investigate the spatiotemporal';
xt = minX + dx*0.5;
yt = minY + dy*0.8;
text(xt,yt,txtStr,'fontsize',8,'FontWeight','bold','fontname','arial','HorizontalAlignment','center');

txtStr = 'dynamics of mesoscale brain activity.';
xt = minX + dx*0.5;
yt = minY + dy*0.75;
text(xt,yt,txtStr,'fontsize',8,'FontWeight','bold','fontname','arial','HorizontalAlignment','center');

txtStr = 'by:';
xt = minX + dx*0.1;
yt = minY + dy*0.65;
text(xt,yt,txtStr,'fontsize',9,'FontWeight','bold','fontname','times','HorizontalAlignment','left');

a = 0.6; b = 0.08;
txtStr = 'Navvab Afrashteh';
xt = minX + dx*0.5;
yt = minY + dy*(a-0*b);
text(xt,yt,txtStr,'fontsize',9,'FontWeight','bold','fontname','times','HorizontalAlignment','center');

txtStr = 'Samsoon Inayat';
xt = minX + dx*0.5;
yt = minY + dy*(a-1*b);
text(xt,yt,txtStr,'fontsize',9,'FontWeight','bold','fontname','times','HorizontalAlignment','center');

txtStr = 'Mostafa Mohsenvand';
xt = minX + dx*0.5;
yt = minY + dy*(a-2*b);
text(xt,yt,txtStr,'fontsize',9,'FontWeight','bold','fontname','times','HorizontalAlignment','center');

txtStr = 'Majid H. Mohajerani';
xt = minX + dx*0.5;
yt = minY + dy*(a-3*b);
text(xt,yt,txtStr,'fontsize',9,'FontWeight','bold','fontname','times','HorizontalAlignment','center');

txtStr = 'Canadian Centre for Behavioural Neuroscience';
xt = minX + dx*0.5;
yt = minY + dy*(a-4.25*b);
text(xt,yt,txtStr,'fontsize',9,'FontWeight','bold','fontname','times','HorizontalAlignment','center');

txtStr = 'University of Lethbridge';
xt = minX + dx*0.5;
yt = minY + dy*(a-5*b);
text(xt,yt,txtStr,'fontsize',9,'FontWeight','bold','fontname','times','HorizontalAlignment','center');

txtStr = 'For more information visit:';
xt = minX + dx*0.5;
yt = minY + dy*(a-6*b);
text(xt,yt,txtStr,'fontsize',10,'FontWeight','normal','fontname','times','HorizontalAlignment','center');

cbStr = 'web(''http://lethbridgebraindynamics.com/OFAMM/'');';
txtStr = 'Lethbridge Brain Dynamics';
xt = minX + dx*0.5;
yt = minY + dy*(a-6.7*b);
htxt = text(xt,yt,txtStr,'fontsize',10,'FontWeight','normal','fontname','times','HorizontalAlignment','center','color','b');
set(htxt,'ButtonDownFcn',cbStr)
hold off


% --- Executes on button press in Help.
function Help_Callback(hObject, eventdata, handles)
% hObject    handle to Help (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
GUIfilePath = mfilename('fullpath');
slashPos = find(GUIfilePath == '\');
PathName = GUIfilePath(1:slashPos(end));
ReadmePathName = [PathName 'Readme.txt'];
eval(['!notepad ' ReadmePathName])


% --- Executes when figure1 is resized.
function figure1_ResizeFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
