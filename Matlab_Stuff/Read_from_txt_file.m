clear
clc
fid = fopen('DATA.TXT','r');
disp('Importing data, please wait...')

% Preallocate
N = 1e5;
temperature = nan(1,N);
humidity = nan(1,N);
dateStrs = cell(1,N);   % use cell array instead of strings

i = 1;
while ~feof(fid)
    a = fgets(fid);
    if ~isempty(strfind(a,'Temperature'))
        offset = strfind(a,'Temperature:');
        temperature(i) = str2double(a(offset+12:offset+16));

        offset = strfind(a,'Humidity:');
        humidity(i) = str2double(a(offset+10:offset+14));

        offset = strfind(a,'Date/Time:');
        dateStrs{i} = strtrim(a(offset+11:end)); % store as char in cell
        i = i+1;
    end
end
fclose(fid);

% Trim
temperature = temperature(1:i-1);
humidity = humidity(1:i-1);
dateStrs = dateStrs(1:i-1);

% Convert to datetime after loop
try
    dateTimeObj = datetime(dateStrs, 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
catch
    dateTimeObj = 1:(i-1);
end

temperature=movmean(temperature,10);
humidity=movmean(humidity,10);
disp('Generating the plot...')
figure('Position',[100 100 1000 800]);
hold on
try %Matlab
    yyaxis left
    plot (dateTimeObj,temperature,'b.')
    xlabel('Date/Time')
    ylabel('Temperature in °C')
    yyaxis right
    plot (dateTimeObj,humidity,'.r')
    ylabel('Relative humidity in %')
    set(gca,'FontSize',16)
catch %GNU Octave
    subplot(1,2,1);
    plot (dateTimeObj,temperature,'b.')
    xlabel('Sample')
    ylabel('Temperature in °C')
    set(gca,'FontSize',16)
    subplot(1,2,2);
    plot (dateTimeObj,humidity,'.r')
    xlabel('Sample')
    ylabel('Relative humidity in %')
    set(gca,'FontSize',16)
end
hold off
disp('Saving figure...')
saveas(gcf,'Plot.png');
