clear
clc
fid = fopen('DATA.TXT','r');
i=1;

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
    dateTimeObj(i) = datetime(Date, 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
    i=i+1;
    end
end
fclose(fid);  
figure('Position',[200 200 800 600]);
hold on
yyaxis left
plot (dateTimeObj,temperature,'b.')
xlabel('Date/Time')
ylabel('Temperature in °C')
yyaxis right
plot (dateTimeObj,humidity,'.r')
ylabel('Relative humidity')
set(gca,'FontSize',16)
hold off
saveas(gcf,'Plot.png');


