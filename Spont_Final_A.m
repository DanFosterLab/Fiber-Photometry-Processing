%Extract data
clear all; close all; %Clear all variables and close all figures
addpath('C:\OneDrive - USC School of Medicine\MATLAB\TDTbin2mat');
addpath(cd);
BlockDir=uigetdir('Select TDT Photometry Block'); %Get folder name
cd(BlockDir); %Change durectory to photometry folder
[Tank,Block,~]=fileparts(cd); %List full directory for Tank and Block
data=TDTbin2mat(BlockDir); %Use TDT2Mat to extract data.
%% SYNAPSE- Extract Relevant Data from Data file
%Create Variables for each Photometry Channel and timestamps
%UserStart = input('Start Time(s):')*1000;
%UserEnd = input('End Time(s):')*1000;
Ch465=data.streams.x465A.data; %dLight
Ch405=data.streams.x405A.data; %Isosbestic Control
Ts = ((1:numel(data.streams.x465A.data(1,:))) / data.streams.x465A.fs)'; % Get Ts for samples based on Fs
StartTime=1000; %Set the starting sample(recommend eliminating a few seconds for photoreceiver/LED rise time).
%StartTime = 1000 + UserStart;
EndTime=length(Ch465)-1000; %Set the ending sample (again, eliminate some).
%EndTime = 1000 + UserEnd;
Fs=data.streams.x465A.fs; %Variable for Fs
Ts=Ts(StartTime:EndTime); % eliminate timestamps before starting sample and after ending.
Tm = Ts / 60;
Ch465=Ch465(StartTime:EndTime);
Ch405=Ch405(StartTime:EndTime); 
[~,name,~]=fileparts(pwd);  % Retrives working directory name
MouseIDa=name(1:4);  % Gets MouseID A from 1st 4 characters of folder name
[~,name,~]=fileparts(pwd);  % Retrives working directory name
MouseIDc=name(6:9);  % Gets MouseID C from 6th-9th characters of folder name
MouseID=MouseIDa;    % Sets MouseID A as MouseID for this script
%% Low-pass filter each channel (<2)Hz
% % Removes high-frequency noise
% Convert Signals to Doubles
Ch465 = Ch465';
Ch405 = Ch405';
Ch465 = double(Ch465);
Ch405 = double(Ch405);

fc = 2; % set to the cutoff of the lowpass filter (default = 10Hz)
[b,a] = butter(2, fc/(Fs/2), 'low');
lp465 = filtfilt(b, a, Ch465);
lp405 = filtfilt(b, a, Ch405);

figure
% set(gcf,'visible','off')
hold on;
plot(Ts,lp465,'b');
plot(Ts,lp405,'m');
title('Signals passed through low-pass filter');
ylabel('mV');
xlabel('Time (s)');
saveas(gcf,[MouseID,'-Lowpassed_Signal_A.png']);
%% linear least=squares fit 405nm to 465nm
fit = polyfit(lp405,lp465,1);
motionfit = fit(1).*lp405 + fit(2);
coeff465 = polyfit(Ts,motionfit,1);
fit465 = polyval(coeff465,Ts);
%% ΔF/F calculated
dFF = ((lp465-fit465) ./ fit465) .* 100;

% % Optional figure plotting ΔF/F
% figure
% plot(Ts,dFF,'k');
% title('\Delta F/F from 405 signal fit to 465 signal');
% ylabel('\Delta F/F (%)');
% xlabel('Time (s)');
%% Photobleaching Correction
%20 second iterated windows
Win20 = buffer(dFF,20000);
per8 = prctile(Win20,8);
per8ext = zeros(length(dFF),1);
i = 1;
p = 1;
for k = 1:length(dFF)
    if i > length(per8)
        break
    end
    per8ext(k,:) = per8 (:,i);
    p = p + 1;
    if p == 20000
        i = i + 1;
        p = 1;
    end
end
pbdFF = dFF - per8ext;

figure
% set(gcf,'visible','off')
plot(Ts,pbdFF,'k');
title('Photobleach Corrected \Delta F/F (%)');
ylabel('\Delta F/F (%)');
xlabel('Time (s)');
q.AutoScale = 'off';
ylim([-5 30]);
saveas(gcf,[MouseID,'-PhoBleach_Crctd_A.png']);
%% Identify Spontaneous Transient Events
% Lefevre et al method to detect substantial spontaneous release events
% Calculates median absolute deviation over rolling 20 sec window
Win20 = buffer(pbdFF,20000);
MAD20 = mad(Win20,1);
%multiply MAD by 2.91
MAD291 = MAD20 .* 2.91;
%remove data below 2.91MAD
dFFtransients = zeros(length(pbdFF),1);
MADpTime = zeros(length(pbdFF),1);
i = 1;
p = 1;
for k = 1:length(pbdFF)
    if i > length(MAD291)
        break
    end
    if pbdFF(k,1) > MAD291(1,i)
        dFFtransients(k,:) = pbdFF(k,:);
    end
    MADpTime(k,:) = MAD291(1,i);
    p = p + 1;
    if p == 20000
        i = i + 1;
        p = 1;
    end
end

% Removes overlapping events
Cleaner = buffer(dFFtransients,100);
CleanerMode = mode(Cleaner);
i = 1;
p = 1;
dFFclean = pbdFF;
for k = 1:length(pbdFF)
    if CleanerMode(1,i) == 0
        dFFclean(k,:) = 0;
    end
    p = p + 1;
    if p == 101
        i = i + 1;
        p = 1;
    end
end

% Creates a list of timestamps and dFF values for events
i = 1;
c = 1;
Peakval = zeros(length(dFFclean),1); %Value of event peak amplitude
Peaklocs = zeros(length(dFFclean),1); %Location/timestamp for events
for k = 1:length(dFFclean)
    if dFFclean(k,1) > Peakval(i,1)
        Peakval (i,:) = dFFclean(k,:);
        Peaklocs(i,:) = Ts(k,:);
    end
    if dFFclean(k,1) == 0
        c = c + 1;
        if c == 250
            c = 1;
            i = i + 1;
        end
    end
end
Peakval(Peakval == 0) = [];
Peaklocs(Peaklocs == 0) = [];

% % Write a list of ALL events to Excel
% header1 = 'Time Stamp (s)';
% header2 = 'Amplitude (%)';
% filename = [MouseID,'-Spont_Events_All_A.xlsx'];
% writematrix(header1,filename,'Range','A1');
% writematrix(header2,filename,'Range','B1');
% writematrix(Peaklocs,filename,'Range','A2');
% writematrix(Peakval,filename,'Range','B2');
%% Mean Amplitude and Frequency Analyzed for a Defined Window
% StTime = input('Start Time:'); % Have MatLab ask for start time
StTime = 10;                     % Set start time (10 sec avoids spike)
FinTime = 600;                   % Set end time
% FinTime = input('End Time:');  % Have MatLab ask for end time

AmpTemp = zeros(length(Peaklocs),1);
FreqTemp = zeros(length(Peaklocs),1);
i = 1;
for k = 1:length(Peaklocs)
    if Peaklocs(k,1) >= StTime & Peaklocs(k,1) <= FinTime
        AmpTemp(i,:) = Peakval(k,1);
        FreqTemp(i,:) = Peaklocs(k,1);
        i = i + 1;
    end
end
AmpTemp(AmpTemp == 0) = [];
FreqTemp(FreqTemp == 0) = [];

MeanAmplitude = mean(AmpTemp);
AmpError = std(AmpTemp)/sqrt(length(AmpTemp));
EventPeriod = diff(FreqTemp);
MeanPeriod = mean(EventPeriod);
PeriodError = std(EventPeriod)/sqrt(length(EventPeriod));
MeanFrequency = 1./MeanPeriod;
FrequencyError = (1 / MeanPeriod)^4 * PeriodError;
Eventnum = length(AmpTemp);

formatSpec = 'Mean Amplitude: %5.4f \x00B1 %5.4f percent. Mean Frequency: %5.4f \x00B1 %5.4f Hz. Number of events: %3.0f \n';
fprintf(formatSpec,MeanAmplitude,AmpError,MeanFrequency,FrequencyError,Eventnum);

% % Write Stats to table COMBINED
filename = [MouseIDa '_' MouseIDc '-' num2str(StTime,'%04d') '-' num2str(FinTime,'%04d') '-Stats.xlsx'];
Variable = ["Mean Amp"; "Amp Error"; "Mean Freq"; "Freq Error"];
Value_A = [MeanAmplitude; AmpError; MeanFrequency; FrequencyError];
var = [array2table(Variable)];
val = [array2table(Value_A)];
writetable(var,filename,'Range','A1');
writetable(val,filename,'Range','B1');

% % Write list of Baseline Period Events to Excel
PeaklocsBase = FreqTemp;
PeakvalBase = AmpTemp;

header1 = 'Time Stamp (s)';
header2 = 'Amplitude (%)';
filename = [MouseID '-Spont_Events_Base-' num2str(StTime,'%04d') '-' num2str(FinTime,'%04d') '.xlsx'];
writematrix(header1,filename,'Range','A1');
writematrix(header2,filename,'Range','B1');
writematrix(PeaklocsBase,filename,'Range','A2');
writematrix(PeakvalBase,filename,'Range','B2');

% % Downsampling Data FIRST Window
% % Create data stream with less data points, easier to work with in other programs
% % Synapse sample rate is 1017/s 
% % DS to 1 point per this number of points
binsize = 102;

% For DS'ing standard Spontaneous data
binnedpbdFF = buffer(pbdFF,binsize);
binnedTs = buffer(Ts,binsize);
pbdFF_reduced = mean(binnedpbdFF,1);
Ts_reduced = binnedTs(1,:);

% ---------------------------
% % Comment above section & use this section to DS DETQ data
% % Avoids pb correction that would flatten DETQ effects
% binnedlp465 = buffer(lp465,binsize);
% binnedTs = buffer(Ts,binsize);
% lp465_reduced = mean(binnedlp465,1);
% Ts_reduced = binnedTs(1,:);
% ---------------------------

for k = 1:length(Ts_reduced)
    if Ts_reduced(1,k) < StTime
        index_1 = k + 1;
    end
    if Ts_reduced(1,k) < FinTime
        index_2 = k;
    end
end

pbdFF_reduced_clip = (pbdFF_reduced(1,index_1:index_2))'; % Standard data
% lp465_reduced_clip = (lp465_reduced(1,index_1:index_2))'; % For DETQ
Ts_reduced_clip = (Ts_reduced(1,index_1:index_2))';
Tminred = Ts_reduced_clip / 60;

% % Downsampled Data Output
% % Creates Excel File of DS data named by animal, time window, & samplerate.
samprate = 1017 / binsize;
filename = [MouseID '-' num2str(samprate,'%.0f') 'Hz_Data-' num2str(StTime,'%04d') '-' num2str(FinTime,'%04d') '_.xlsx'];
header1 = 'Time Stamp (s)';
header2 = 'Time (min)';
header3 = 'Photobleach corrected data (dF/F)';
writematrix(header1,filename,'Range','A1');
writematrix(header2,filename,'Range','B1');
writematrix(header3,filename,'Range','C1');
writematrix(Ts_reduced_clip,filename,'Range','A2');
writematrix(Tminred,filename,'Range','B2');
writematrix(pbdFF_reduced_clip,filename,'Range','C2'); % For standard Spont
% writematrix(lp465_reduced_clip,filename,'Range','C2'); % For DETQ data
%% Mean Amplitude and Frequency Analyzed for a SECOND Defined Window
% % Spont peak time is 2100-2700 (25-35 minutes post-inj)
% % DETQ window: 2640 - 3540
% % StTime2 = input('Start Time:'); % Have MatLab ask for start time
StTime2 = 1800;                     % Set start time
FinTime2 = 2400;                    % Set end time
% FinTime2 = input('End Time:');    % Have MatLab ask for end time

AmpTemp = zeros(length(Peaklocs),1);
FreqTemp = zeros(length(Peaklocs),1);
i = 1;
for k = 1:length(Peaklocs)
    if Peaklocs(k,1) >= StTime2 & Peaklocs(k,1) <= FinTime2
        AmpTemp(i,:) = Peakval(k,1);
        FreqTemp(i,:) = Peaklocs(k,1);
        i = i + 1;
    end
end
AmpTemp(AmpTemp == 0) = [];
FreqTemp(FreqTemp == 0) = [];

MeanAmplitude = mean(AmpTemp);
AmpError = std(AmpTemp)/sqrt(length(AmpTemp));
EventPeriod = diff(FreqTemp);
MeanPeriod = mean(EventPeriod);
PeriodError = std(EventPeriod)/sqrt(length(EventPeriod));
MeanFrequency = 1./MeanPeriod;
FrequencyError = (1 / MeanPeriod)^4 * PeriodError;
Eventnum = length(AmpTemp);

% % Write Stats to table SECOND window
filename = [MouseIDa '_' MouseIDc '-' num2str(StTime2,'%04d') '-' num2str(FinTime2,'%04d') '-Stats.xlsx'];
Variable = ["Mean Amp"; "Amp Error"; "Mean Freq"; "Freq Error"];
Value_A = [MeanAmplitude; AmpError; MeanFrequency; FrequencyError];
var = [array2table(Variable)];
val = [array2table(Value_A)];
writetable(var,filename,'Range','A1');
writetable(val,filename,'Range','B1');

% % Write to Excel a list of events during later/Peak Period
PeaklocsPeak = FreqTemp;
PeakvalPeak = AmpTemp;

header1 = 'Time Stamp (s)';
header2 = 'Amplitude (%)';
filename = [MouseID '-Spont_Events_Peak-' num2str(StTime2,'%04d') '-' num2str(FinTime2,'%04d') '.xlsx'];
writematrix(header1,filename,'Range','A1');
writematrix(header2,filename,'Range','B1');
writematrix(PeaklocsPeak,filename,'Range','A2');
writematrix(PeakvalPeak,filename,'Range','B2');

% %% Downsampling Data SECOND Window
% % Create data stream with less data points, easier to work with in other programs
% % Synapse sample rate is 1017/s 
% % DS to 1 point per this number of points
binsize = 102;

% For DS'ing standard Spontaneous data
binnedpbdFF = buffer(pbdFF,binsize);
binnedTs = buffer(Ts,binsize);
pbdFF_reduced = mean(binnedpbdFF,1);
Ts_reduced = binnedTs(1,:);

% ---------------------------
% % Comment out the above section & use this section to DS DETQ data
% % Avoids pb correction that would flatten DETQ effects
% binnedlp465 = buffer(lp465,binsize);
% binnedTs = buffer(Ts,binsize);
% lp465_reduced = mean(binnedlp465,1);
% Ts_reduced = binnedTs(1,:);
% ---------------------------

for k = 1:length(Ts_reduced)
    if Ts_reduced(1,k) < StTime2
        index_1 = k + 1;
    end
    if Ts_reduced(1,k) < FinTime2
        index_2 = k;
    end
end

pbdFF_reduced_clip = (pbdFF_reduced(1,index_1:index_2))'; % Standard data
% lp465_reduced_clip = (lp465_reduced(1,index_1:index_2))'; % For DETQ
Ts_reduced_clip = (Ts_reduced(1,index_1:index_2))';
Tminred = Ts_reduced_clip / 60;

% % Downsampled Data Output
% % Creates Excel File of DS data named by animal, time window, & samplerate.
samprate = 1017 / binsize;
% Names file based on Mouse ID, approx. sample rate, & window used. 
filename = [MouseID '-' num2str(samprate,'%.0f') 'Hz_Data-' num2str(StTime2,'%04d') '-' num2str(FinTime2,'%04d') '.xlsx'];
header1 = 'Time Stamp (s)';
header2 = 'Time (min)';
header3 = 'Photobleach corrected data (dF/F)';
writematrix(header1,filename,'Range','A1');
writematrix(header2,filename,'Range','B1');
writematrix(header3,filename,'Range','C1');
writematrix(Ts_reduced_clip,filename,'Range','A2');
writematrix(Tminred,filename,'Range','B2');
writematrix(pbdFF_reduced_clip,filename,'Range','C2');   % For standard Spont
% writematrix(lp465_reduced_clip,filename,'Range','C2'); % For DETQ data
%% Triggers Transient_Trace.m function to calculate Mean and SEM of traces at BASELINE
% % Specify start and stop time (s) after Peaklocs in line below
[traces,trace_ts,meantrace,MeanAmpClean,BaseSec,TraceSEM,st,fin] = transient_trace(pbdFF,Ts,Peaklocs,10,600,'before',2);

filename = [MouseID '-Baseline_Traces_' num2str(st) '-' num2str(fin) '_BaseSec_' num2str(BaseSec) '.xlsx'];
header1 = 'Time Stamp (s)';
header2 = 'Mean Trace';
header3 = 'Mean Amp Clean';
header4 = 'SEM';
writematrix(header1,filename,'Range','A1');
writematrix(header2,filename,'Range','B1');
writematrix(trace_ts',filename,'Range','A2');
writematrix(meantrace,filename,'Range','B2');
writematrix(header3,filename,'Range','C1');
writematrix(MeanAmpClean,filename,'Range','C2');
writematrix(header4,filename,'Range','D1');
writematrix(TraceSEM',filename,'Range','D2');

% % WHEN NEEDED - Prints out all individual traces
% header4 = 'Traces';
% writematrix(header3,filename,'Range','E1');
% writematrix(traces,filename,'Range','E2');
%% Triggers Transient_Trace.m function to calculate Mean and SEM of traces at Drug PEAK Period
% % Specify start and stop time (s) after Peaklocs in line below
[traces,trace_ts,meantrace,MeanAmpClean,BaseSec,TraceSEM,st,fin] = transient_trace(pbdFF,Ts,Peaklocs,1800,2400,'before',2);

filename = [MouseID '-Peak_Level_Traces_' num2str(st) '-' num2str(fin) '_BaseSec_' num2str(BaseSec) '.xlsx'];
header1 = 'Time Stamp (s)';
header2 = 'Mean Trace';
header3 = 'Mean Amp Clean';
header4 = 'SEM';
writematrix(header1,filename,'Range','A1');
writematrix(header2,filename,'Range','B1');
writematrix(trace_ts',filename,'Range','A2');
writematrix(meantrace,filename,'Range','B2');
writematrix(header3,filename,'Range','C1');
writematrix(MeanAmpClean,filename,'Range','C2');
writematrix(header4,filename,'Range','D1');
writematrix(TraceSEM',filename,'Range','D2');

% % WHEN NEEDED - Prints out all individual PEAK traces
% header4 = 'Traces';
% writematrix(header3,filename,'Range','D1');
% writematrix(traces,filename,'Range','D2');