clear
clc
fid = fopen('DATA.TXT','r');
i=1;
disp('Importing data, please wait...')
while ~feof(fid)
    a=fgets(fid);
    if not(isempty(strfind(a,'Temperature')))
        disp('DATA packet received !')
        offset=strfind(a,'Temperature:');
        temperature(i)=str2num(a(offset+12:offset+16));
        offset=strfind(a,'Humidity:');
        humidity(i)=str2num(a(offset+10:offset+14));
        offset=strfind(a,'Date/Time:');
        Date=a(offset+11:end-2); %end-2 because LF/CR
        try
            dateTimeObj(i) = datetime(Date, 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
        catch
            dateTimeObj(i) = i;
        end
        i=i+1;
    end
end
fclose(fid);
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
