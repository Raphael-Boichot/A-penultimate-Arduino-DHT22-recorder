clear
clc
disp('-----------------------------------------------------------')
disp('|Beware, this code is for Matlab ONLY !!!                 |')
disp('-----------------------------------------------------------')
arduinoObj = serialport("COM6",115200,'TimeOut',3600); %set the Arduino com port here
configureTerminator(arduinoObj,"CR/LF");
flush(arduinoObj);
arduinoObj.UserData = struct("Data",[],"Count",1);
temperature=[];
humidity=[];

while true
    data = readline(arduinoObj);
    disp(data)
    
    if not(isempty(strfind(data,'Temperature:')));
        data=char(data);
        temperature=[temperature;str2num(data(13:end))];
        data = readline(arduinoObj);
        data=char(data);
        disp(data);
        humidity=[humidity;str2num(data(10:end))];
    end
        subplot(1,2,1)
        plot(temperature,'k.')
        title('Température')
        subplot(1,2,2)
        plot(humidity,'k.')
        title('Humidity')
        drawnow
    end           


