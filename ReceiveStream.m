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

disp('Now receiving data...');
counter=0;
EEG = [];
markers = [];
try
    while true
        counter=counter+1;
        % get data from the inlet
        [vec,ts] = inlet.pull_sample(0.8);
        % and display it
        %fprintf('%.2f\t',vec);
        %fprintf('%.5f\n',ts);

        EEG = [EEG; [ts vec]];

    end
catch
    
end

% while counter<10000
%     % get data from the inlet
%     [mrks,ts] = inlet2.pull_sample(0.8);
%     % and display it
%     fprintf('got %d at time %.5f\n',mrks,ts);
%     markers = [markers; [ts mrks]];
% end


    
    