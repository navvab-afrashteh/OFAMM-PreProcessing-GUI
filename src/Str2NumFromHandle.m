function Num = Str2NumFromHandle(h,DefaultNum,varargin)

maxVal = inf;
if nargin > 2
    maxVal = varargin{1};
end
minVal = -inf;
if nargin > 3
    minVal = varargin{2};
end

str = get(h,'string');

if strcmp(get(h,'Tag'),'WinSizeMedian')
    spacePos = find(str == ' ' | str == ',');
    if isempty(spacePos)
        [Num, status] = str2num(str);
        if ~status || Num <= 0
            Num = DefaultNum;
        end
        Num = [Num, Num];
    else
        dspacePos = diff(spacePos);
        if length(spacePos)>1
            idx = find(dspacePos~=1);
            if ~isempty(idx)
                str = str(1:spacePos(idx+1));
            end
        end
        str1 = str(1:spacePos(1)-1);
        if strcmp(str1(1),'[')
            str1 = [str1 ']'];
        end
        [Num(1), status] = str2num(str1);
        if ~status || Num(1) <= 0
            Num(1) = DefaultNum(1);
        end
        str2 = str(spacePos(1)+1:end);
        if strcmp(str2(end),']')
            str2 = ['[' str2];
        end
        [Num(2), status] = str2num(str2);
        if ~status || Num(2) <= 0
            Num(2) = DefaultNum(2);
        end
    end
elseif ~strcmp(get(h,'Tag'),'MinDispVal') && ~strcmp(get(h,'Tag'),'MaxDispVal')
    str = str(str~=' ');
    [Num, status] = str2num(str);
    if ~status || Num <= 0
        Num = DefaultNum;
    end
end
if strcmp(get(h,'Tag'),'MinDispVal') || strcmp(get(h,'Tag'),'MaxDispVal')
    str = str(str~=' ');
    [Num, status] = str2num(str);
    if Num >= maxVal
        Num = sign(maxVal)*abs(maxVal)/2;
    end
    if Num <= minVal
        Num = sign(minVal)*abs(minVal)*2;
    end
else
    Num = min(Num,maxVal);
    Num = max(Num,minVal);
end

if length(Num) == 1
    set(h,'string',num2str(Num));
elseif length(Num) > 1
    set(h,'string',['[', num2str(Num), ']']);
end