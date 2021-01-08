function f1 = filterAudioFile(fileName,outputFileName)

    %% 3.1  - read the audiofile
    % audioread: inputs - audio file, outputs: sample frequency and sampled
    % signal

    [readFile, sampleFs] = audioread(fileName);

    %% 3.2 - checking number of audio channels to convert to one
    [numSamples, numChannels] = size(readFile);

    % if statement: will sum columns and convert sampled file to 1D array
    if numChannels == 2

        % add values in both columns
        sampledFile = sum(readFile,2);
    else 
        sampledFile = readFile;
    end

    %% 3.3 Play the sound
%{
    % create an audioplayer object
    sound1 = audioplayer(sampledFile, sampleFs);
    play(sound1);

    %% 3.4 Write a new sound file
    %audiowrite: inputs: filename, sample file, and frequency, output:
    %audiofile
    audiowrite(outputFileName,sampledFile, sampleFs);
    %}

    %% 3.5 Plot audio file sound as a function of sample number
    n = 0:1:numSamples-1;
    figure(1);
    plot(n,sampledFile);
    title('Waveform of Audio File')
    xlabel('Sample Number')

    %% 3.6 Downsample the input signal if required

    % if statement: will check the frequency and resample if necessary to
    % ensure sampling frequency of 16kHz
    if sampleFs > 16000

        % resample with change sampleFs by P/Q factor
        resampledFile = resample(sampledFile,16000,sampleFs);

    elseif sampleFs < 16000
        disp("WARNING: sample frequency is less than 16kHz, consider finding a new file");
    end
    
   
    %% 3.7 generating a cosine signal
    %{
    % the signal needs to oscillate at 1kHz and have the same time duration
    
    % determining the time of the original audio file
    timeDuration = numSamples/sampleFs;

    % forming a time access from 0 - signal duration with time steps
    t = 0:timeDuration/numSamples:timeDuration;

    % definition of the cosine function with period 0.001s
    cosineFunction = cos(2000*pi*t);

    %playing the sound of the function
    sound2 = audioplayer(cosineFunction, sampleFs);
    play(sound2);

    %plot the cosine function, only first two waveforms
    figure(2);
    plot(t, cosineFunction);
    axis([0 0.002 -1 1]);
    title('Waveform of Generated 1kHz Signal')
    xlabel('Time')
    %}

    %% Task 5/6 - filter sound with passband bank and plot output signals of lowest and highest channels
    % define frequency band cut-offs (total 9 for 10 bands based on log scale)
    cutOffs = [100, 154.992256, 240.22046, 372.3145, 577.0454, 894.3551, 1386.1493, 2148.37456, 3329.73752, 5160.71648, 7999];
    fs = 8000;
    numSamples = length(resampledFile);
    filteredSounds(numSamples, 10) = 0.0;
    
    for x = 1:10
        if x == 1
            [b,a] = butter(4, 100/fs, 'low');
        else
            cutOff1 = cutOffs(x)/fs;
            cutOff2 = cutOffs(x+1)/fs;
            [b,a] = butter(4,[cutOff1 cutOff2], 'bandpass');
            
        end
        
        filter = filtfilt(b,a,resampledFile);
        for n = 1:numSamples
            filteredSounds(n,x) = filter(n);
        end
    end
    
    timeDuration = numSamples;
    t = 0:timeDuration/(numSamples-1):numSamples;
    
    lowChannel(numSamples) = 0.0;
    highChannel(numSamples)= 0.0;
    for x = 1:numSamples
        lowChannel(x) = filteredSounds(x,1);
        highChannel(x) = filteredSounds(x,10);
    end
    
    figure(3);
    plot(t, lowChannel);
    title('Filtered Signal of First Channel')
    xlabel('Sample Number')
    
    figure(4);
    plot(t, highChannel);
    title('Filtered Signal of Last Channel')
    xlabel('Sample Number')
    
    %Task 7/8 - Rectify output signals and detect envelopes with a lowpass filter at 400 Hz fc    
    %Plot highest and lowest frequency channel envelopes
    rectifiedSounds=filteredSounds;
    rectifiedSoundsTranspose = transpose(rectifiedSounds);
    signalSize=size(rectifiedSoundsTranspose);
    signalQuantity=signalSize(1);

    signalEnvelopes(10, numSamples) = 0.0;
    
    %Find coefficients of the lowpass filter
    hd = LPF(30);
    
    for i=1:signalQuantity
        signalSquared = 2*rectifiedSoundsTranspose(i,:).*rectifiedSoundsTranspose(i,:);
        signalEnvelope = filtfilt(hd,1,signalSquared);
        
        signalEnvelopes(i,:) = sqrt(signalEnvelope);
        
        if i==1 
            figure(5);
            plot(signalEnvelopes(i,:));
            title('Envelope of Lowest Frequency Channel'); 
            xlabel('Sample Number');
        end
        if i==signalQuantity
            figure(6);
            plot(signalEnvelopes(i,:));
            title('Envelope of Highest Frequency Channel'); 
            xlabel('Sample Number');
        end
    end
    
    %% Phase 3 - 3.7 generating a cosine signal
    
    outputSignal(10, numSamples) = 0.0;
    
    % determining the time of the original audio file
    timeDuration = numSamples/sampleFs;

    % forming a time access from 0 - signal duration with time steps
    t = 0:timeDuration/(numSamples-1):timeDuration;

    % definition of the cosine function with period 0.001s
    for i = 1:10
        %Task 10
        fc = (cutOffs(i)+cutOffs(i+1))/2;

        period = 1/fc;
        k = 2*pi/period;
        cosineFunction = cos(k*t);
        
        %Task 11
        amSignal = (signalEnvelopes(i,:)).*cosineFunction;
        
        %Task 12
        outputSignal(i,:) = amSignal;
        
    end
  
    outputSignal = transpose(outputSignal);
    finalOutputSignal = sum(outputSignal, 2)/10;
    
    %normalize the finalOutputSignal
    maximum = max(abs(finalOutputSignal));
    finalOutputSignal =finalOutputSignal/maximum;
    
    figure(7);
    plot(t,finalOutputSignal);
    
    SNR = snr(finalOutputSignal)
        
    %playing the sound of the function
    outputSound = audioplayer(finalOutputSignal, 16000);
    play(outputSound);
    audiowrite(outputFileName, finalOutputSignal, 16000);


end