clearvars -except Peaklocs Peakval StTime Ts;
%% Defining animal ID's For Naming Output
[~,name,~]=fileparts(pwd);
MouseIDa=name(1:4);
[~,name,~]=fileparts(pwd);
MouseIDc=name(6:9);
%% Interval of data points
% Interval = input('Bin Size (min):'); % Have MatLab ask for bin size
Interval = 2.5;                        % Set Bin Size (in minutes)
IntName = Interval;
Interval = Interval * 60;
% % Start time carries over from main script window unless redefined below
% StTime = input('Start Time:');        % Have MatLab ask for start 
StTime = 10;           % Sets start of baseline (10s avoids initial spike)     
BaseStart = StTime;    % Defines start of baseline for naming output file
FinTime = Interval + StTime;

% Finds amplitudes and IEI for each bin
AmpTemp = zeros(length(Peaklocs),1);
FreqTemp = zeros(length(Peaklocs),1);
i = 1;
z = 1;
sttime = StTime;
fintime = FinTime;
for k = 1:length(Peaklocs)
    if Peaklocs(k,1) >= StTime
        if Peaklocs(k,1) > FinTime
            AmpTemp(AmpTemp == 0) = [];
            FreqTemp(FreqTemp == 0) = [];
            MeanAmplitudes(z,1) = mean(AmpTemp);
            AmpErrors(z,1) = std(AmpTemp)/sqrt(length(AmpTemp));
            TempIEI = diff(FreqTemp);
            MeanIEI(z,1) = mean(TempIEI);
            IEIerror(z,1) = std(TempIEI)/sqrt(length(TempIEI));
            z = z + 1;
            AmpTemp = zeros(length(Peaklocs),1);
            FreqTemp = zeros(length(Peaklocs),1);
            i = 1;
            StTime = StTime + Interval;
            FinTime = FinTime + Interval;
        end
        AmpTemp(i,:) = Peakval(k,1);
        FreqTemp(i,:) = Peaklocs(k,1);
        i = i + 1;
    end
end

TimeStamp = zeros(length(MeanAmplitudes),1);
i = Interval/2;
for k = 1:length(MeanAmplitudes)
    TimeStamp(k,1) = i;
    i = i + Interval;
end

% Time of Injection
% Injection = input("Time of Injection (Minutes): "); % Asks for time
Injection = 30; % Set injection time (based on experiment)
Injection = (Injection * 60) + sttime;
BsFin = Injection;       % Defines end of baseline for naming output file

figure
subplot(2,1,1);
scatter(TimeStamp,MeanAmplitudes)
hold on;
errorbar(TimeStamp,MeanAmplitudes,AmpErrors,'LineStyle','none');
xline(Injection);
hold off;
title('Mean Amplitudes Over Time');
ylabel('Mean Amplitudes (%)');
xlabel('Time (s)');
xlim([0 Ts(length(Ts))])
subplot(2,1,2);
scatter(TimeStamp,MeanIEI);
hold on;
errorbar(TimeStamp,MeanIEI,IEIerror,'LineStyle','none');
xline(Injection);
hold off;
title('Mean Inter Event Interval Over Time');
ylabel('Mean Inter Event Interval');
xlabel('Time (s)');
xlim([0 Ts(length(Ts))])
%% Amplitude and IEI as % of baseline
% Calculate Baseline means
n = 0;
for k = 1:length(MeanAmplitudes)
    if TimeStamp(k,1) <= Injection
        n = n + 1;
    end
end
AmpBase = mean(MeanAmplitudes(1:n,1));
IEIBase = mean(MeanIEI(1:n,1));
BinFreq = 1./(MeanIEI);
FreqBase = mean(BinFreq(1:n,1));

% Normalize bin values to Baseline
for k = 1:length(MeanAmplitudes)
    AmpPerBin(k,1) = (MeanAmplitudes(k,1)/AmpBase) * 100;
    IEIPerBin(k,1) = (MeanIEI(k,1)/IEIBase) * 100;
    FreqPerBin(k,1) = (BinFreq(k,1)/FreqBase) * 100;
end

figure
subplot(2,1,1);
scatter(TimeStamp,AmpPerBin)
hold on;
xline(Injection);
hold off;
title('Mean Amp Over Time, Normalised to BL');
ylabel('Variation from BL Mean Amp (%)');
xlabel('Time (s)');
xlim([0 Ts(length(Ts))])
subplot(2,1,2);
scatter(TimeStamp,IEIPerBin);
hold on;
xline(Injection);
hold off;
title('Mean Inter Event Interval Over Time, Normalised to Baseline');
ylabel('Variation from Baseline Mean IEI (%)');
xlabel('Time (s)');
xlim([0 Ts(length(Ts))]);
saveas(gcf,[MouseIDc '-Binned_Data_C.png']);
%% Binned data Output 
% % Named based on baseline period bins are normalized too
filename = [MouseIDc '-Base_' num2str(BaseStart,'%04d') '-' num2str(BsFin,'%04d') '-Binned_Data_C-' num2str(IntName) 'min.xlsx'];
header1 = 'Time Stamp';
header2 = 'Mean Amp Normal';
header3 = 'Mean Freq Norm';
% header4 = 'Mean Norm IEI';
writematrix(header1,filename,'Range','A1');
writematrix(header2,filename,'Range','B1');
writematrix(header3,filename,'Range','C1');
% writematrix(header4,filename,'Range','D1');
writematrix(TimeStamp,filename,'Range','A2');
writematrix(AmpPerBin,filename,'Range','B2');
writematrix(FreqPerBin,filename,'Range','C2');
% writematrix(IEIPerBin, filename,'Range','D2');