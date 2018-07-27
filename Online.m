%% instantiate the library
disp('Loading the library...');
lib = lsl_loadlib();

% resolve a stream...
disp('Resolving an EEG stream...');
result = {};
while isempty(result)
    result = lsl_resolve_byprop(lib,'name','openvibeSignal'); end

result2 = {};
% while isempty(result2)
%     result2 = lsl_resolve_byprop(lib,'name','openvibeMarkers'); end

% create a new inlet
disp('Opening an inlet...');
inlet = lsl_inlet(result{1});

%inlet2 = lsl_inlet(result2{1});

Fs=250;
trials=0;
disp('Now receiving data...');
counter=0;
EEG = [];
mEEG = [];
markers = [];
clear sEEG;
try
    msg = '';
    while ( strcmpi(msg,'finishplot') == 0)
        counter=counter+1;
        % get data from the inlet
        [vec,ts] = inlet.pull_sample(0.8);
        % and display it
        %fprintf('%.2f\t',vec);
        %fprintf('%.5f\n',ts);

        EEG = [EEG; [ts vec]];
        mEEG = [mEEG; [ts vec]];
        
   
        k = find(EEG(:,12)==32774);
        if (size(k,1)>0)

            [MSSG,sourcehost,sourceport] = judp('RECEIVE', 7788, 10024, 100000);
            msg = char(MSSG');    
            disp(msg);
            
            trials=trials+1;
            sEEG{trials} = EEG;
            
            
            ProcessTrial
            EEG = [];
            
            row = num2str(r);
            col = num2str(c);
            
            %row = num2str(randi(6)-1)
            %col = num2str(randi(6)-1)
            judp('SEND',sourceport, sourcehost, int8([row,col]));   
            
        end
        
        
        

    end
catch ME
    ME
    
end

% while counter<10000
%     % get data from the inlet
%     [mrks,ts] = inlet2.pull_sample(0.8);
%     % and display it
%     fprintf('got %d at time %.5f\n',mrks,ts);
%     markers = [markers; [ts mrks]];
% end

Fs = 250;
%signal = EEG(:,2:9);
bandpass = true;
channelRange=1:8;

if (bandpass)
    signal = bandpasseeg(samples, channelRange,Fs,3);
end
    