clear
clc
data=load('DATA_example.TXT')
temperature=data(:,1);
humidity=data(:,2);

subplot(1,2,1)
plot(temperature,'k.')
title('Température')
subplot(1,2,2)
plot(humidity,'k.')
title('Humidity')
drawnow
        


