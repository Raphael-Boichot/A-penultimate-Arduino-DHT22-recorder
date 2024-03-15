clear
clc
close all
disp('-----------------------------------------------------------')
disp('|Beware, this code is for Matlab ONLY !!!                 |')
disp('-----------------------------------------------------------')
arduinoObj = serialport("COM6",115200,'TimeOut',3600); %set the Arduino com port here
configureTerminator(arduinoObj,"CR/LF");
flush(arduinoObj);
arduinoObj.UserData = struct("Data",[],"Count",1);
i=1;
figure('Position',[200 200 800 600]);
while true
    data = readline(arduinoObj);
    disp(data)

    if not(isempty(strfind(data,'Temperature:')));
        a=char(data);
        disp('DATA packet received !')
        offset=strfind(a,'Temperature:');
        temperature(i)=str2num(a(offset+12:offset+16));
        offset=strfind(a,'Humidity:');
        humidity(i)=str2num(a(offset+10:offset+14));
        offset=strfind(a,'Date/Time:');
        Date=a(offset+11:end); %end-2 because LF/CR
        dateTimeObj(i) = datetime(Date, 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
        i=i+1;
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
        drawnow
        saveas(gcf,'Plot.png');
    end

end