function [axesHandle, imageHandle] = imageCollage(...
    imgArr,...
    parentPanelH,...
    colorMap,...
    keepAspectRatio,...
    keepTrueSize,...
    useQuiver,...
    forceComplex)

% get size of the image array
[dimY, dimX, noFrames] = size(imgArr);

% delete all uiobjects from parentPanelH
oldHandles = get(parentPanelH,'Children');
if ~isempty(oldHandles)
    delete(oldHandles);
end

% units and window position
origUnits = get(parentPanelH,'Units');
set(parentPanelH,'Units','pixel');
fpos = get(parentPanelH,'position');
fWidth = fpos(3);
fHeight = fpos(4);

% % width and height of every image
% layout_total = noFrames;
% if (layout_total ~= 1) && (mod(layout_total, 2) ~= 0) && (length(factor(layout_total)) == 1)
%     layout_total = layout_total + 1;
% end
% layout_factor = factor(layout_total);
% layout_row_num = prod(layout_factor(1:ceil(length(layout_factor) / 2)));
% layout_column_num = prod(layout_factor(ceil(length(layout_factor) / 2) + 1:end));
% if layout_row_num > layout_column_num
%     temp = layout_row_num;
%     layout_row_num = layout_column_num;
%     layout_column_num = temp;
% end
% nCols = layout_column_num;
% nRows = layout_row_num;
% colHeight = floor(fHeight / nRows);
% colWidth = floor(fWidth / nCols);

layout_total = noFrames;
if (layout_total ~= 1) && (isprime(layout_total))
    % For prime numbers, use single row layout
    layout_row_num = 1;
    layout_column_num = layout_total;
else
    % Original logic for non-prime numbers
    layout_factor = factor(layout_total);
    layout_row_num = prod(layout_factor(1:ceil(length(layout_factor) / 2)));
    layout_column_num = prod(layout_factor(ceil(length(layout_factor) / 2) + 1:end));
    if layout_row_num > layout_column_num
        temp = layout_row_num;
        layout_row_num = layout_column_num;
        layout_column_num = temp;
    end
end

nCols = layout_column_num;
nRows = layout_row_num;
colHeight = floor(fHeight / nRows);
colWidth = floor(fWidth / nCols);

if keepAspectRatio % account for aspect ratio
    imgRatio = dimY / dimX;
    colHeight = colWidth * imgRatio;
    if colHeight > floor(fHeight/nRows)
        colHeight = floor(fHeight/nRows);
        colWidth = colHeight / imgRatio;
    end
    yBorder2 = floor((fHeight - nRows * colHeight)/2);
    xBorder2 = floor((fWidth - nCols * colWidth)/2);
else
    yBorder2 = 0;
    xBorder2 = 0;
end

% display
imageHandle = zeros(noFrames,1);
axesHandle  = zeros(noFrames,1);
for n=1:noFrames
    
    % image position
    x0 = mod((n-1),nCols)  * colWidth + xBorder2;
    y0 = fHeight - colHeight - (floor((n-1)/nCols) * colHeight) - yBorder2;
    
    ah = axes('Parent',parentPanelH,'units','pixel','position',[x0, y0, colWidth, colHeight]);
    
    if keepTrueSize
        pixelPos = get(ah,'position');
        set(ah,'position',[pixelPos(1:2), dimY, dimX]);
    end
    currImg = imgArr(:,:,n);
    
    if useQuiver              
        imageHandle(n) = quiver(real(currImg),imag(currImg),...
            'Parent',ah);
        set(ah,'YDir','reverse');        
        axis(ah,'tight');
        
        % store the original image in the axes handle's userData
        ud.selectedImage = currImg;
        set(ah,'UserData',ud);
    else
    
        if forceComplex || ~isreal(currImg)
            isComplex = true;
            [currImg, CLim] = complex2rgb(currImg, 256, [], colormap(ah, colorMap));
            if any(~isfinite(CLim))
                error([mfilename,':ExpectedFinite'],'CLim has to be finite');
            end
        else                        
            isComplex = false;
            colormap(ah,colorMap);        
        end
        % sssr: matlab 2017b + version does not update colormap without next line 
        set(ah,'NextPlot','replacechildren');
        imageHandle(n) = imagesc(currImg,'Parent',ah);           

        if isComplex
            if (CLim(1) == CLim(2))
                if(CLim(1) == 0)
                    CLim(1) = 1;
                    CLim(2) = 1;
                end
                CLim(1) = CLim(1)/2;
            end
            set(ah,'CLim',CLim);
        end    
    end
    if keepAspectRatio
        set(ah,'DataAspectRatio',[1,1,1]);
    end
    
    axis(ah,'off');    
    axesHandle(n) = ah;
end
set(parentPanelH,'Units',origUnits);
end
