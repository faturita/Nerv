EEG = sEEG{trials};
stims = EEG(:,[11,12]);
stims(find(stims(:,2)==0),:) = [];
samples = EEG(:,3:10);
sampleTime= EEG(:,2);
e=find(stims(:,2)==hex2dec('0000800C')); % Visual Stimulus Stop 32780
f=find(stims(:,2)==hex2dec('0000800B')); % Visual Stimulus Start 32779
c=find(stims(:,2)==hex2dec('00008004')); % Segment Stop 32772
x=find(stims(:,2)==hex2dec('00008001')); % Experiment Start 32769
s=find(stims(:,2)==hex2dec('00008006')); % Trial Stop 32774
r=find(stims(:,2)==hex2dec('0000800a')); % Rest Stop 32778

a=find(stims(:,2)==hex2dec('00008205')); % 33285 Hit
b=find(stims(:,2)==hex2dec('00008206')); % 32286 Nohit

% Find all the stimulus assosiated with row/col flashing.
stimuls = [];
for i=1:12
    stimuls = [stimuls; find(stims(:,2)==33025-1+i)];
end

% hold on
% plot([e; s],'r.')
% plot(sort(stimuls),'b-')
% hold off
% 
[sort(stimuls), stims(sort(stimuls),2)]

%%
% Los stimulos pueden venir despues de muchas cosas.
% Filtrar solo aquellos estimulos que estan asociados a targets.
counterhits=0;
counternohits=0;
validstimuls=[];
for i=1:size(stimuls,1)
    vl=stims(stimuls(i)-1,1:2);
    pvl=stims(stimuls(i)+1,1:2);
    % Ver que es lo que esta antes del estimulo
    if (vl(2) == 33285) % Hit
        counterhits = counterhits + 1;
        validstimuls(end+1) = stimuls(i);
    elseif (vl(2) == 33286) % Nohit
        counternohits = counternohits + 1;
        validstimuls(end+1) = stimuls(i);
    elseif (pvl(2) == 32779)
        counternohits = counternohits + 1;
        validstimuls(end+1) = stimuls(i);        
    end
    assert ( vl(2)==33285 || vl(2)==33286 || vl(2)==32777 || vl(2) == 897 || vl(2)>=33025 || vl(2)<=33036);
end




% Sort validstimuls based on time.
sls = sort(validstimuls);

% Pick the stimuls sorted.
stimulations = [ stims(sls,1:2) ];

% Map stimulus to 1-12 values.
stimulations(:,2) = stimulations(:,2) - 33025 + 1;
stimulations( stimulations(:,2) < 0) = 0; 

%%
ab = [a; b];

% a hits, b nohits, c and d contain where trial end and stop (five of each
% per letter).

ab = sort(ab);

% Cut the stimulus from stims, getting only the time and duration of each.
targets = [ stims(ab,1:2)];

% Remap targets, assigning 1 for NoHit and 2 for Hit.
targets(targets(:,2)==33285,2) = 2;
targets(targets(:,2)==33286,2) = 1;
targets(targets(:,2)==32773,2) = 0;
targets(targets(:,2)==32774,2) = 0;
targets(targets(:,2)==32780,2) = 0;

%% Data Structure
data = cell(0);

data.X = samples;
data.y = zeros(size(samples,1),1);
data.y_stim = zeros(size(samples,1),1);
data.trial=zeros(5,1);

data.flash = [];
durs=[];

if (size(find(diff(f)==0),2)~=0) warning('Coincidental Event-Starting found.');end
if (size(find(diff(e)==0),2)~=0) warning('Coincidental Event-Starting found.');end

durs = [];

r=-1;
c=-1;

for i=1:size(targets,1)
    
    if (i==48)
        disp('ddd')
    end
    % Obtengo la localizacion donde esta el marcador de fin del estimulo
    % (e) y del principio (f)
    duration = stims(e(i),1)-stims(f(i),1);
    
    lag = 0;
    if (duration == 0)
        duration = 1/Fs;
        lag = -2;
    end
    
    assert( duration > 0, 'Flash duration cannot be zero.');
    
    durs(end+1) = ceil(Fs*duration);
    % Marco donde inicia el flash y la duracion en sample points.
    
    assert( ceil(Fs*duration) > 0, 'Flash duration cannot be zero.');
    
    
    idxset=find(sampleTime>=stims(f(i),1));
    idxset = sort(idxset);
    idx=idxset(1);
    
    data.flash(end+1,1) = idx ;
    data.flash(end,2) = ceil(Fs*duration);
    
    %fakeEEG=fakeeegoutput(4,targets(i,2),channelRange,25,100,4);
    
    % Marco todos los estimulos y targets donde el flash estuvo presente.
    for j=1:ceil(Fs*duration)
       data.y(idx+j-1) = targets(i,2); 
       data.y_stim(idx+j-1) = stimulations(i,2);
    end
    
    data.y(idx) = targets(i,2);
    data.y_stim(idx) = stimulations(i,2);
    
    
    data.flash(end,3) = stimulations(i,2);
    data.flash(end,4) = targets(i,2);
    
    if (targets(i,2)==2)
        %data.X(idx+1-1-100:idx+1-1-100+ceil(Fs*1)+100,:) = zeros(ceil(Fs*1)+100+1,size(data.X,2));
        if (stimulations(i,2)>6)
            c = stimulations(i,2)-6-1;
        else
            r = stimulations(i,2)-1;
        end
    end    
    
end
[r,c]