clear
clc
close all
warning 'off'
disp('-----------------------------------------------------------')
disp('|Beware, this code is for Matlab ONLY !!!                 |')
disp('-----------------------------------------------------------')

list = serialportlist;
valid_port=[];
protocol_failure=1;
for i =1:1:length(list)
    try
        disp(['Testing port ',char(list(i)),'...'])
        arduinoObj = serialport(char(list(i)),115200,'TimeOut',2);
        response=readline(arduinoObj);
        if ~isempty(response)
            if not(isempty(strfind(response,'BOICHOT')))
                disp(['Arduino detected on port ',char(list(i))])
                valid_port=char(list(i));
                beep ()
                protocol_failure=0;
            end
        end
        clear arduinoObj
    catch
        disp('Error connecting this port')
    end
end

if protocol_failure==0
    arduinoObj = serialport(valid_port,115200,'TimeOut',3600); %set the Arduino com port here
    configureTerminator(arduinoObj,"CR/LF");
    flush(arduinoObj);
    arduinoObj.UserData = struct("Data",[],"Count",1);
    i=1;
    figure('Position',[200 200 800 600]);
    while true
        data = readline(arduinoObj);
        disp(data)
        if not(isempty(strfind(data,'Temperature:')))
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
            ylabel('Relative humidity in %')
            set(gca,'FontSize',16)
            hold off
            drawnow
            saveas(gcf,'Plot.png');
        end
    end
else
    disp('No compatible device found !')
end