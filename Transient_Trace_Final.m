function [traces,trace_ts,meantrace,MeanAmpClean,BaseSec,TraceSEM,st,fin,outliers] = transient_trace(data,Ts,Peaklocs,st,fin,options)
    arguments
        data (:,1) double
        Ts (:,1) double
        Peaklocs (:,1) double
        st (1,1) {mustBeNumeric}
        fin (1,1) {mustBeNumeric}
        options.before (1,1) {mustBeNumeric} = 1
        options.after (1,1) {mustBeNumeric} = 2
        options.samplerate (1,1) {mustBeNumeric} = 1017
        options.MAD (1,1) {mustBeNumeric} = 3
    end

      
    % Convert time into number of samples
    baselinetime = options.before * options.samplerate;
    followingtime = options.after * options.samplerate;
    BaseSec = options.before;
   
    % Get an evenly spaced set of time stamps from the preliminary point to the
    % end point based upon the values above with 0 being the peak
    trace_ts = linspace(-(options.before),options.after,(baselinetime+followingtime+1));
    % For each detected transient peak
    p = 1;
    for i = 1:length(Peaklocs)
        % Find the timestamp of that event
        timestamp = Peaklocs(i,1);
        % Sort through all of the actual timestamps until reaching that of the
        % event
        if timestamp > fin
            break
        end
        if timestamp >= st
            for k = 1:length(Ts)
                if Ts(k,1) >= timestamp & k > baselinetime
                    % Establish 'a' as the index of the starting point of the trace
                    a = k - baselinetime;
                    % Establish 'b' as halfway between that starting point and the
                    % peak to avoid rise time in baseline calculation
                    b = floor(k - (options.samplerate/2));
                    % Establish 'c' as the index of the ending point of the trace
                    c = k + followingtime;
                    % Determine the baseline as the photobleach corrected dF/F
                    % between indicies a and b
                    baseline = data(a:b,1);
                    % Take the mean of the baseline to use for normalization
                    norm_mean = mean(baseline);
                    norm_std = std(baseline);
                    % Ignore any trace that would run past the end of the recording
                    if c <= length(data)
                        % Take the trace from a to c, taking the z-score
                        % snip(:,p) = (data(a:c,1) - norm_mean)/norm_std;
                        snip(:,p) = data(a:c,1);
                        % Normalize it to the mean of the baseline
                        % snip(:,p) = snip(:,p) ./ norm;
                        p = p + 1;
                    end
                    break
                end
            end
        end
    end
    
    % Get the median value of each trace
    med_snip = median(snip,1);    
    outlier_per = 100;
    threshold = options.MAD;
    while outlier_per > 0.007
        % Detect which medians are outliers with a value of 50 times the MAD
        outliers = isoutlier(med_snip,"median",ThresholdFactor=threshold);
        % Determine the number of outliers detected
        outlier_per = sum(outliers)/length(outliers);
        threshold = threshold + 1;
    end
    disp(threshold)

    % Determine the number of outliers detected
    num_outliers = sum(outliers);
    
    % Removes each outlier from the list of traces
    p = 1;
    for k = 1:length(outliers)
        if outliers(1,k) == 0
            traces(:,p) = snip(:,k);
            p = p + 1;
        end
    end
    
    % Find Peak Amplitude of Each Trace
    trace_amp = max(traces);
    % Find Mean Amplitude from all Traces in Window
    MeanAmpClean = mean(trace_amp);
    
    % Derive the Averaged Trace from all traces 
    meantrace = mean(traces,2);
    TraceSEM = std(traces')/sqrt(size(traces,2));        

    figure
    plot(trace_ts,meantrace)  
end