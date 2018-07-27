%Parameters
Fs=250;
Trials=6;

stims = EEG(:,[11,12]);
stims(find(stims(:,2)==0),:) = [];
samples = EEG(:,3:10);
sampleTime= EEG(:,2);

% NN.NNNNN
% data.X(sample, channel)
% data.y(sample)  --> 0: no, 1:nohit, 2:hit
% data.y_stim(sample) --> 1-12, 1-6 cols, 7-12 rows

channels={ 'Fz'  ,  'Cz',    'P3' ,   'Pz'  ,  'P4'  , 'PO7'   , 'PO8',  'Oz'};
channelRange=1:8;


%%
fprintf('%04x\n',stims(:,2))

% First, get the stimulus to different events
c=find(stims(:,2)==hex2dec('00008005')); % 32773 Trial Start
d=find(stims(:,2)==hex2dec('00008006')); % 32774 Trial Stop
a=find(stims(:,2)==hex2dec('00008205')); % 33285 Hit
b=find(stims(:,2)==hex2dec('00008206')); % 32286 Nohit
e=find(stims(:,2)==hex2dec('0000800C')); % Visual Stimulus Stop 32780
f=find(stims(:,2)==hex2dec('0000800B')); % Visual Stimulus Start 32779
l=find(stims(:,2)==hex2dec('00008004')); % Segment Stop 32772
x=find(stims(:,2)==hex2dec('00008001')); % Experiment Start 32769

% Find all the stimulus assosiated with row/col flashing.
stimuls = [];
for i=1:12
    stimuls = [stimuls; find(stims(:,2)==33025-1+i)];
end

%%
% Chequear si la cantidad de estimulos encontradas coincide.
% 33025 es el label 1.
total=0;
for i=1:12
    [i size(find(stims(:,2)==33025-1+i),1)]
    total=total+size(find(stims(:,2)==33025-1+i),1);
end

assert ((size(stimuls,1) == total), 'Stimulus found do not match.');

%%
% Los stimulos pueden venir despues de muchas cosas.
% Filtrar solo aquellos estimulos que estan asociados a targets.
counterhits=0;
counternohits=0;
validstimuls=[];
tgts=[];
spurioustgts=[];
for i=1:size(stimuls,1)
    vl=stims(stimuls(i)-1,1:2);
    pvl=stims(stimuls(i)+1,1:2);
    % Ver que es lo que esta antes del estimulo
    if (vl(2) == 33285) % Hit
        counterhits = counterhits + 1;
        validstimuls(end+1) = stimuls(i);
        tgts = [tgts; vl];
    elseif (vl(2) == 33286) % Nohit
        counternohits = counternohits + 1;
        validstimuls(end+1) = stimuls(i);
        tgts = [tgts; vl];
    else
        spurioustgts(end+1) = i;
    end
    assert ( vl(2)==33285 || vl(2)==33286 || vl(2)==32777 || vl(2) == 897 || vl(2)>=33025 || vl(2)<=33036);
end

% Los que valen son los que estan precedidos por una marca de target o no
% target
% Chequear si los targets estan bien asignados a los mismos estimulos
% dentro del mismo trial.
%%
assert ( size(a,1) >= 20*Trials,  'Hit number of stimulations do not match 20 x 35');
assert ( size(b,1) >= 100*Trials, 'Nohit number of stimulations do not match 100 x 35');

for trial=1:Trials
    h=[];
    for i=1:20  % Hay 20 hits en cada trial, 20*35 = 700 que es el tama�o de a
        vl=stims(a((trial-1)*20+i)+1,1:2);
        %[(trial-1)*Trials+i vl(2)]
        h=[h vl(2)];
    end
    h = unique(h);
    [trial h]
    % Verificar que para cada trial, solo haya dos tipos de estimulos
    % asociados a hit (el correspondiente a las filas y el de las columnas)
    assert( size(h,2) == 2);
end

%%
ab = [a; b];

% a hits, b nohits, c and d contain where trial end and stop (five of each
% per letter).

ab = sort(ab);

% Cut the stimulus from stims, getting only the time and duration of each.
targets = [ stims(ab,1:2)];

targets = tgts;

% Remap targets, assigning 1 for NoHit and 2 for Hit.
targets(targets(:,2)==33285,2) = 2;
targets(targets(:,2)==33286,2) = 1;
targets(targets(:,2)==32773,2) = 0;
targets(targets(:,2)==32774,2) = 0;
targets(targets(:,2)==32780,2) = 0;



% Sort validstimuls based on time.
sls = sort(validstimuls);

% Pick the stimuls sorted.
stimulations = [ stims(sls,1:2) ];

% Map stimulus to 1-12 values.
stimulations(:,2) = stimulations(:,2) - 33025 + 1;
stimulations( stimulations(:,2) < 0) = 0; 

% trials
z = stims(c,1);

% Stop time is where the first invalid trial starts.
if (size(c,1)>Trials)
    
    stoptime=stims(c(Trials+1),1);

    stopsample=find(sampleTime>stims(c(Trials+1),1));


    sampleTime(stopsample(1):end,:) = [];
    samples(stopsample(1):end,:) = [];

    z(Trials+1) = [];

    targets(Trials*12*10+1:end,:) = [];
    stimulations(Trials*12*10+1:end,:) = [];
end
    
    
%% Check target consistency

%% Data Structure
data = cell(0);

data.X = samples;
data.y = zeros(size(samples,1),1);
data.y_stim = zeros(size(samples,1),1);
data.trial=zeros(Trials,1);

data.flash = [];
durs=[];
% for i=1:size(targets,1)
%     
%     if (i==3856)
%         disp('ddd')
%     end
%     % Obtengo la localizacion donde esta el marcador de fin del estimulo
%     % (e) y del principio (f)
%     startset = find(stims(f,1)<=targets(i,1));
%     startset = sort(startset);
%     
%     endset = find(stims(e,1)>=targets(i,1));
%     endset = sort(endset);
%     endd = endset(1); % Location on e.
%     
%     if (size(startset,1)==0)
%         % En algunos casos la primera estimulacion cae despues del primer
%         % target.
%         start = endd;
%     else
%         start = startset(end);
%     end
%     
%     duration = stims(e(endd),1)-stims(f(endd),1);
%     
%     
%     if (duration == 0)
%         duration = 1/Fs;
%     end
%     
%     assert( duration > 0, 'Flash duration cannot be zero.');
%     
%     
%     durs(end+1) = ceil(Fs*duration);
%     % Marco donde inicia el flash y la duracion en sample points.
%     
%     assert( ceil(Fs*duration) > 0, 'Flash duration cannot be zero.');
%     
%     
%     idxset=find(sampleTime>=stims(f(start),1));
%     idxset = sort(idxset);
%     idx=idxset(1);
%     
%     data.flash(end+1,1) = idx 
%     data.flash(end,2) = ceil(Fs*duration);
%     
%     %fakeEEG=fakeeegoutput(4,targets(i,2),channelRange,25,100,4);
%     
%     % Marco todos los estimulos y targets donde el flash estuvo presente.
%     %for j=1:ceil(Fs*duration)
%     %    data.y(idx+j-1) = targets(i,2); 
%     %    data.y_stim(idx+j-1) = stimulations(i,2);
%     %end
%     
%     data.y(idx) = targets(i,2);
%     data.y_stim(idx) = stimulations(i,2);
%     
%     
%     data.flash(end,3) = stimulations(i,2);
%     data.flash(end,4) = targets(i,2);
%     
%     if (targets(i,2)==2)
%         %data.X(idx+1-1-100:idx+1-1-100+ceil(Fs*1)+100,:) = zeros(ceil(Fs*1)+100+1,size(data.X,2));
%     end    
%     
% end

if (size(find(diff(f)==0),2)~=0) warning('Coincidental Event-Starting found.');end
if (size(find(diff(e)==0),2)~=0) warning('Coincidental Event-Starting found.');end


%%
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
    
    if (data.y(idx+lag)==0)
        idx = idx + lag;
    end
    
    % Si asi y todo no tengo lugar, lo muevo para adelante 2.
    if (data.y(idx)~=0)
        idx = idx+(2);
    end
    
    
    data.flash(end+1,1) = idx 
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
    end    
    
end

% Marco los inicios de los trials.
for i=1:size(z)
    n=find(sampleTime>z(i));
    data.trial(i)=n(1);
end

data.trial = data.trial';


%%
% Antes de cada uno de los inicios de los flash, los estimulos tienen que
% estar marcados con zero.
for i=1:Trials*12*10
    ss=data.y_stim(data.flash(i)-5:data.flash(i)+40)'
    
    assert ( ss(5) == 0, 'Not zero');
end
%% 
% Chequear que efectivamente los eventos marcados en targets y stimulations
% estan todos asignados a diferentes sample indexes (aun en los casos en
% que openvibe me inform� que los eventos fueron coincidentes, donde yo le
% agrego un lag adicional).  A efectos del analisis de los datos
[C, IM, IC] = unique(data.flash(:,1));
diffs=setdiff(1:size(data.flash(:,1),1),IM);

assert ( size(diffs,2)==0, 'Some coincidential stimulation events were not fixed.');
assert( size(unique(data.flash(:,1)),2) == size(data.flash(:,1),2), 'Some coincidential stimulation events were not fixed.');

%%

%save(sprintf('./signals/p300-subject-%02d.mat',subject));

% LISTOOOOOO

fprintf('File saved.  DONE!');

%%

%run('ProcessP300.m');
%run('GeneralClassifyP300.m');



%%
%%

