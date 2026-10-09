%Extract data
clear all; close all; %Clear all variables and close all figures
addpath('C:\OneDrive - USC School of Medicine\MATLAB\TDTbin2mat'); % Point to TDT conversion files
addpath(cd);
BlockDir=uigetdir('Select TDT Photometry Block'); % Get folder name
cd(BlockDir); % Change directory to photometry folder
[Tank,Block,~]=fileparts(cd); % List full directory for Tank and Block
data=TDTbin2mat(BlockDir); % Use TDT2Mat to extract data.
%% SYNAPSE- Extract Sensor A Data from Data file
Ch465A=data.streams.x465A.data; % Experimental Stream
Ch405A=data.streams.x405A.data; % Isosbestic Control Stream
Ts = ((1:numel(data.streams.x465A.data(1,:))) / data.streams.x465A.fs)'; % Get Ts for samples based on Fs
StartTime=10000; % Set the starting sample (avoids initial spike).
%StartTime = 1000 + UserStart;
EndTime=length(Ch465A)-1000; %Set the ending sample (again, eliminate some).
%EndTime = 1000 + UserEnd;
Fs=data.streams.x465A.fs; %Variable for Fs
Ts=Ts(StartTime:EndTime); % eliminate timestamps before starting sample and after ending.
Ch465A=Ch465A(StartTime:EndTime);
Ch405A=Ch405A(StartTime:EndTime);
[~,name,~]=fileparts(pwd); % Reads the name of the current working directory folder
MouseIDa=name(1:4); % Defines mouse A's ID from the 1st 4 characters of directory name
%% SYNAPSE- Extract Sensor C Data from Data file
Ch465C=data.streams.x465C.data; % Experimental Stream
Ch405C=data.streams.x405C.data; % Isosbestic Control Stream
Ts = ((1:numel(data.streams.x465C.data(1,:))) / data.streams.x465C.fs)'; % Get Ts for samples based on Fs
StartTime=10000; %Set the starting sample(recommend eliminating a few seconds for photoreceiver/LED rise time).
%StartTime = 1000 + UserStart;
EndTime=length(Ch465C)-1000; %Set the ending sample (again, eliminate some).
%EndTime = 1000 + UserEnd;
Fs=data.streams.x465C.fs; %Variable for Fs
Ts=Ts(StartTime:EndTime); % eliminate timestamps before starting sample and after ending.
Ch465C=Ch465C(StartTime:EndTime);
Ch405C=Ch405C(StartTime:EndTime);
[~,name,~]=fileparts(pwd); % Reads the name of the current working directory folder
MouseIDc=name(6:9); % Defines mouse C's ID from characters 6-9 of directory name
%% Low-pass filter A channels (<2)Hz
% Convert Signals to Doubles
Ch465A = Ch465A';
Ch405A = Ch405A';
Ch465A = double(Ch465A);
Ch405A = double(Ch405A);

% % Change length of signal or time if mismatched (Rare)
% size(Ts) % Displays length of Time (s) stream
% Ts = Ts(1:14685480);  % Defines new time length
% Ch465A = Ch465A(1:14685480);
% Ch405A = Ch405A(1:14685480);

fc = 2; % set to the cutoff of the lowpass filter (default = 10Hz)
[b,a] = butter(2, fc/(Fs/2), 'low');
lp465A = filtfilt(b, a, Ch465A);
lp405A = filtfilt(b, a, Ch405A);

% figname = [num2str(SampRate,'%.0f') 'HzSR_' num2str(fc,'%.0f') 'HzFilt_A.fig'];
% filename = [num2str(SampRate,'%.0f') 'HzSR_' num2str(fc,'%.0f') 'HzFilt_A.png'];

% Used to change size of array when length is mismatched (Rare)
% size(Ts) % Displays length of Time (s) stream
% Ts = Ts(1:14699913);  % Defines new time length
% size(lp465A)  % Displays length of low-passed stream
% lp465A = lp465A(1:14699913); % Defines length (change end as needed)
% lp405A = lp405A(1:14699913); % Defines length (change end as needed)

figure
plot(Ts,lp465A,'b');
hold on;
plot(Ts,lp405A,'m');
title('Signals passed through low-pass filter');
ylabel('mV');
xlabel('Time (s)');
saveas(gcf,[MouseIDa, '-Lowpassed_Signal_A.png']);
% savefig('Lowpass_A.fig');

% save([MouseIDa,'_A_lowpassed_465.mat'],'Ts','lp465A');
% save([MouseIDa,'_A_lowpassed_405.mat'],'Ts','lp405A');
%% Low-pass filter C channels (<2)Hz
% % Convert Signals to Doubles
Ch465C = Ch465C';
Ch405C = Ch405C';
Ch465C = double(Ch465C);
Ch405C = double(Ch405C);

% % Change length of signal or time if mismatched (Rare)
% size(Ts) % Displays length of Time (s) stream
% Ts = Ts(1:14685480);  % Defines new time length
% Ch465C = Ch465C(1:14685480);
% Ch405C = Ch405C(1:14685480);

fc = 2; % set to the cutoff of the lowpass filter (default = 10Hz)st:fn,1
[b,a] = butter(2, fc/(Fs/2), 'low');
lp465C = filtfilt(b, a, Ch465C);
lp405C = filtfilt(b, a, Ch405C);

% figname = [num2str(SampRate,'%.0f') 'HzSR_' num2str(fc,'%.0f') 'HzFilt_C.fig'];
% filename = [num2str(SampRate,'%.0f') 'HzSR_' num2str(fc,'%.0f') 'HzFilt_C.png'];

% Used to change size of array when length is mismatched (Rare)
% size(Ts) % Displays length of time (s)
% size(lp465C) % Displays length of low-passed stream
% lp465C = lp465C(1:14699913); % Defines length (change end as needed)
% lp405C = lp405C(1:14699913); % Defines length (change end as needed)


figure
plot(Ts,lp465C,'b');
hold on;
plot(Ts,lp405C,'m');
title('Signals passed through low-pass filter');
ylabel('mV');
xlabel('Time (s)');
saveas(gcf,[MouseIDc, '-Lowpassed_Signal_C.png']);
% savefig('Lowpass_C.fig');

% save([MouseIDc,'_C_lowpassed_465.mat'],'Ts','lp465C');
% save([MouseIDc,'_C_lowpassed_405.mat'],'Ts','lp405C');
%% 5s median filter to both 465nm and 405nm channels on window preceding injection (WinFin)
% For Spont w/ DETQ, Start 1200, Fin 1800
% For AHL, Start 3600, Fin 5400
WinStartSec = 1200;
WinStart = WinStartSec * 1017;
WinFin = 1800;
i = 1;
for k = 1:length(Ts)
    if Ts(k,1) >= WinStartSec & Ts(k,1) < WinFin
        st = round(k - (1017 * 2.5));
        fn = round(k + (1017 * 2.5));
        filtered465A(i,1) = median(lp465A(st:fn,1), 'omitnan');
        filtered405A(i,1) = median(lp405A(st:fn,1), 'omitnan');
        filtered465C(i,1) = median(lp465C(st:fn,1), 'omitnan');
        filtered405C(i,1) = median(lp405C(st:fn,1), 'omitnan');
        i = i + 1;
    end
    if Ts(k,1) >= WinFin
        End = k;
        break
    end
end

fitA = polyfit(filtered405A,filtered465A,1);
isofitA = fitA(1).*lp405A+fitA(2);
fitC = polyfit(filtered405C,filtered465C,1);
isofitC = fitC(1).*lp405C+fitC(2);
% save([MouseIDa,'-linearfit.mat']); % Optional save to .mat file

% Calculate ΔF/F
dFFA = (lp465A-isofitA)./isofitA;
dFFC = (lp465C-isofitC)./isofitC;

% Figures to visualize dFF data after polyfit PB correction
figure
plot(Ts,dFFA,'k');
title('Photobleach-Corrected A');
ylabel('dF/F');
xlabel('Time (s)');
xline(WinFin);
saveas(gcf,[MouseIDa,'-PBC_A.png']);
% xline(WinStartSec);

figure
plot(Ts,dFFC,'k');
title('Photobleach-Corrected C');
ylabel('dF/F');
xlabel('Time (s)');
xline(WinFin);
saveas(gcf,[MouseIDc,'-PBC_C.png']);
% xline(WinStartSec);

% Calculates data Z-score shift from baseline window defined above
zscoredA = (dFFA - mean(dFFA(WinStart:End,1)))/std(dFFA(WinStart:End,1));
zscoredC = (dFFC - mean(dFFC(WinStart:End,1)))/std(dFFC(WinStart:End,1));

% Downsampling dF/F and Z-Scored data
samplerate = 1017;
numseconds = 60;
binsize = samplerate*numseconds;
DS_dFFA = median(buffer(dFFA.',binsize));
DS_dFFC = median(buffer(dFFC.',binsize));
DS_zscoredA = median(buffer(zscoredA.',binsize));
DS_zscoredC = median(buffer(zscoredC.',binsize));
DS_Ts = median(buffer(Ts.',binsize));

% Re-centers baseline to zero after downsampling
baseline_bins = DS_Ts >= WinStartSec & DS_Ts < WinFin;
DS_zscoredA = DS_zscoredA - mean(DS_zscoredA(baseline_bins));
DS_zscoredC = DS_zscoredC - mean(DS_zscoredC(baseline_bins));

% Write DSed Z-Score to Excel A
header1 = 'Time Stamp (s)';
header2 = 'DS Z-Score A';
writematrix(header1,[MouseIDa,'-DownSamp_ZScore_A.xlsx'],'Range','A1');
writematrix(header2,[MouseIDa,'-DownSamp_ZScore_A.xlsx'],'Range','B1');
writematrix(DS_Ts.',[MouseIDa,'-DownSamp_ZScore_A.xlsx'],'Range','A2');
writematrix(DS_zscoredA.',[MouseIDa,'-DownSamp_ZScore_A.xlsx'],'Range','B2');

% % Write DSed dF/F to Excel A
% header1 = 'Time Stamp (s)';
% header2 = 'DS dFF A';
% writematrix(header1,[MouseIDa,'-DownSamp_dFF_A.xlsx'],'Range','A1');
% writematrix(header2,[MouseIDa,'-DownSamp_dFF_A.xlsx'],'Range','B1');
% writematrix(DS_Ts.',[MouseIDa,'-DownSamp_dFF_A.xlsx'],'Range','A2');
% writematrix(DS_dFFA.',[MouseIDa,'-DownSamp_dFF_A.xlsx'],'Range','B2');


% % Write DSed Z-Score to Excel C
header1 = 'Time Stamp (s)';
header2 = 'DS Z-Score C';
writematrix(header1,[MouseIDc,'-DownSamp_ZScore_C.xlsx'],'Range','A1');
writematrix(header2,[MouseIDc,'-DownSamp_ZScore_C.xlsx'],'Range','B1');
writematrix(DS_Ts.',[MouseIDc,'-DownSamp_ZScore_C.xlsx'],'Range','A2');
writematrix(DS_zscoredC.',[MouseIDc,'-DownSamp_ZScore_C.xlsx'],'Range','B2');

% % Write DSed dF/F to Excel C
% header1 = 'Time Stamp (s)';
% header2 = 'DS dFF C';
% writematrix(header1,[MouseIDc,'-DownSamp_dFF_C.xlsx'],'Range','A1');
% writematrix(header2,[MouseIDc,'-DownSamp_dFF_C.xlsx'],'Range','B1');
% writematrix(DS_Ts.',[MouseIDc,'-DownSamp_dFF_C.xlsx'],'Range','A2');
% writematrix(DS_dFFC.',[MouseIDc,'-DownSamp_dFF_C.xlsx'],'Range','B2');

% Determine maxima points
MaximaA = islocalmax(DS_zscoredA,'MinProminence',1);
MaximaC = islocalmax(DS_zscoredC,'MinProminence',1);

figure
plot(Ts,zscoredA,'c');
hold on;
plot(DS_Ts(1:end-1),DS_zscoredA(1:end-1),'k',DS_Ts(MaximaA),DS_zscoredA(MaximaA),'k*');
title('Stream A After 5s Median Photobleach Adjustment');
ylabel('Z-Score');
xlabel('Time (s)');
% saveas(gcf,[MouseIDa,'-Zscore_A.fig']); % Save .fig figure file
xline(WinFin);
yline(0);
saveas(gcf,[MouseIDa,'-Zscore_A.png']);
%save([MouseIDa,'-dFF_Z-Score_A.mat'],'Ts','dFFA','zscored'); % Save .mat

figure
plot(Ts,zscoredC,'c');
hold on;
plot(DS_Ts(1:end-1),DS_zscoredC(1:end-1),'k',DS_Ts(MaximaC),DS_zscoredC(MaximaC),'k*');
title('Stream C After 5s Median Photobleach Adjustment');
ylabel('Z-Score');
xlabel('Time (s)');
% saveas(gcf,[MouseIDc,'-Zscore_C.fig']); % Save .fig figure file
xline(WinFin);
yline(0);
saveas(gcf,[MouseIDc,'-Zscore_C.png']);
% save([MouseIDc,'-dFF_Z-Score_C.mat'],'Ts','dFFC','zscoredC'); % Save .mat