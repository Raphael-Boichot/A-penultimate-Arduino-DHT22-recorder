clear
clc
close all
warning 'off'
disp('-----------------------------------------------------------')
disp('|   This code can be used with both Matlab or GNU Octave  |')
disp('-----------------------------------------------------------')

try %GNU Octave
    pkg load instrument-control
end

list = serialportlist;
valid_port=[];
protocol_failure=1;
response=[];
for i =1:1:length(list)
    try
        disp(['Testing port ',char(list(i)),'...'])
        try %GNU Octave
            arduinoObj = serialport(char(list(i)),'baudrate',115200,'TimeOut',1);
        catch %Matlab
            arduinoObj = serialport(char(list(i)),115200,'TimeOut',1);
        end
        pause(1)
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
    try
        arduinoObj = serialport(valid_port,'baudrate',115200,'TimeOut',2);
    catch
        arduinoObj = serialport(valid_port,115200,'TimeOut',2);
    end
    configureTerminator(arduinoObj,"CR/LF");
    %flush(arduinoObj);
    %arduinoObj.UserData = struct("Data",[],"Count",1);
    i=1;
    figure('Position',[100 100 1000 800]);
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
            try %Matlab
                dateTimeObj(i) = datetime(Date, 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
            catch %GNU Octave
                dateTimeObj(i) = i;
            end
            i=i+1;
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
            drawnow
            saveas(gcf,'Plot.png');
        end
    end
else
    disp('No compatible device found !')
end
