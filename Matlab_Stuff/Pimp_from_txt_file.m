close all; clearvars; clc

T_min = -15;
T_max = 50;
w_max = 0.05;
Taille = [1000,1000];

% Taille_A4 = [210,297]*3;
% Taille_Letter = [8.5,11]*88;

fid = fopen('DATA.TXT','r');
i=1;

disp('Importing data, please wait...')
while ~feof(fid)
    a=fgets(fid);
    if not(~contains(a,'Temperature'))
    %disp('DATA packet received !')
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
temperature=movmean(temperature,10);
humidity=movmean(humidity,10);
Saturation_water_pressure=101325*exp(13.7-5120./(temperature+273));%Rankine formula
Water_pressure=Saturation_water_pressure.*humidity/100;
Absolute_humidity=0.622*Water_pressure./(101325-Water_pressure);

disp('Generating the plot...')
tracer_abaque(T_min,T_max,w_max,Taille, temperature,Absolute_humidity);
disp('Saving figure...')
saveas(gcf,'Pimp.png');

%% Tracer l'abaque

function fig = tracer_abaque(T_min,T_max,w_max,Taille, temperature,Absolute_humidity)


% Établir les intervalles
T = T_min:T_max;
E = 0:0.1:1;
w = zeros(size(length(T),length(E)));

if ~exist('w_max','var'), w_max = w_de_P_vs(T_max); end

% Calculer et tracer les courbes de l'humidité relative
fig = figure;
X1 = axes(fig);
for i = 1:length(T)
    for j = 1:length(E)
        w(i,j) = w_de_P_vs(T(i))*E(j);
    end
end
alpha(0.5)
plot(T,w,'-k')
hold on

plot(temperature,Absolute_humidity,'.m')

% Tracer les températures
w = 0*T;
for i = 2:2:length(T)
    w(i) = w_de_P_vs(T(i));
    plot([T(i),T(i)],[0,w(i)],'-k')
end

% Tracer les humidités absolues
w = 0.002:0.002:w_de_P_vs(T_max);
T = 0*w;
for i = 1:length(w)
    T(i) = T_rosee_de_w(w(i));
    plot([T(i),T_max],[w(i),w(i)],'-k')
end
T = T_min+1:T_max;

% Tracer les pressions partielles
P_ticks_labels = 0:1000:P_H2O_de_w(w(end));
P_ticks = 0*P_ticks_labels;
for i = 1:length(P_ticks)
    P_ticks(i) = w_de_P_H2O(P_ticks_labels(i));
end

% Calculer et tracer les courbes de l'enthalpie
H_G_min = ceil(H_G_de_w(T_min,w_de_P_vs(T_min)));
H_G_max = floor(H_G_de_w(T_max,w_de_P_vs(T_max)));
H_G = H_G_min:2:H_G_max;
for i=1:length(H_G)
    [T_H,w_H] = droite_H_G(H_G(i),T_min,T_max);
    plot(T_H,w_H,'-r')
end
plot([T_min,T_max],[w_de_P_vs(T_min),w_de_P_vs(T_max)],'-r')

% Calculer et tracer les courbes du volume spécifique
v_min = ceil(v_de_w(T_min,w_de_P_vs(T_min))*100)/100;
v_max = floor(v_de_w(T_max,w_de_P_vs(T_max))*100)/100;
v=v_min:0.01:v_max;
v_x_ticks = 0*v;
v_y_ticks = 0*v;
for i=1:length(v)
    [T_v,w_v] = droite_v(v(i),T_min,T_max);
    plot(T_v,w_v,'-c')
    v_x_ticks(i) = T_v(end);
    v_y_ticks(i) = w_v(end);
end
v_x_ticks = unique(sort(v_x_ticks));
v_y_ticks = unique(sort(v_y_ticks));

% Calculer et tracer les courbes de la température humide
for i=1:2:length(T)
    [T_h,w_h] = droite_T_h(T(i),T_max);
    T_h = T_h(T_h<=T_max); w_h = w_h(1:length(T_h));
    plot(T_h,w_h,'-b')
end

% Tracer le demicircle pour gamma
x_gamma = (T_max-T_min)*0.25+T_min;
if exist('w_max','var'), y_gamma = w_max*0.95; R_y_gamma = w_max*0.15;
else, y_gamma = w_de_P_vs(T_max)*0.95; R_y_gamma = w_de_P_vs(T_max)*0.15; end
R_x_gamma = (T_max-T_min)*0.15;
gamma = -5000:100:5000;
gamma_labels = [-4000,-1000,-500,-200,0,200:1000,1200,1500,2000,4000];
Gamma(x_gamma,y_gamma,R_x_gamma,R_y_gamma,gamma,gamma_labels);

for i=1:length(E)-1
    T_annotate = T_max-4-i;
    w_annotate = w_de_P_vs(T_annotate)*(E(i)+0.1);

    % Calculez la coordonnée y au-dessus du point où vous souhaitez placer l'annotation
    w_text = w_annotate + (w_annotate - min(w)) * 0.05; % 5% spacing from the curve

    a=10*i;
    b=num2str(a);
    c=['ε = ',b,'%'];
    % Ajouter un commentaire à l'emplacement spécifié
    text(T_annotate, w_text, c, ...
        'VerticalAlignment', 'bottom', ...
        'HorizontalAlignment', 'left', ...
        'FontSize',8,'Clipping','on');
end

%Droit de graduation de H_G
    function y = y(T)
        p=(w_de_P_vs(T_max)-w_de_P_vs(T_min))/(T_max-T_min);
        w_min=w_de_P_vs(T_min);
        y=p*(T+15)+w_min;
    end


%Ajouter une marque H_G
for i=1:length(H_G)
    T_annotate = T_max-((T_max-T_min)/(length(H_G)-1))*(i-1);
    y_annotate = y(T_annotate);

    % Calculez la coordonnée y au-dessus du point où vous souhaitez placer l'annotation
    T_text = T_annotate - 1;
    y_text = y_annotate + 0.0005;

    a=H_G(length(H_G)-i+1);
    b=num2str(a);
    % Ajouter un commentaire à l'emplacement spécifié
    text(T_text, y_text, b, 'VerticalAlignment', 'bottom', ...
        'HorizontalAlignment', 'left', ...
        'Color','r','Clipping','on');
end

x_h = (T_max-T_min)*0.3+T_min;
if exist('w_max','var'), y_h = w_max*0.6;
else, y_h = w_de_P_vs(T_max)*0.6; end
text(X1,x_h,y_h,'Air enthalpy','Color','r','HorizontalAlignment','right')
text(X1,x_h,y_h*0.95,'(kcal/kg)','Color','r','HorizontalAlignment','right')

% Définir les autres proprietés du diagramme
hold off
xlabel(X1,'Dry temperature T (°C)')
ylabel(X1,"Absolute humidity ω (kg/kg_{as})")
xlim([T_min,T_max])
set(gca,'YAxisLocation','right')
set(X1,'FontSize',8)
title('Psychrometric chart','FontSize',16)

if exist('w_max','var'), ylim([0,w_max]), end
if exist('Taille','var')
    fig.Units = 'pixels';
    fig.OuterPosition = [0 0 Taille(1) Taille(2)];
end

%Définir les axes
X2=axes('Position',[0.13,0.05,0.84,0.0001],'XColor',[0,0.5,0.5]);
Y2=axes('Position',[0.97,0.05,0.0001,0.855],'YColor',[0,0.5,0.5]);
Y3=axes('Position',[0.13,0.11,0.0001,0.815],'YColor',[1,0.5,0]);
linkaxes([X1, X2, Y2, Y3], 'xy')
xlim(X1,[T_min,T_max]); ylim(X1,[0,w_max]);

% Volume
set(Y2, 'YAxisLocation', 'right');
xticks(X2,v_x_ticks(1:end-1))
xticklabels(X2,v(1:length(v_x_ticks)-1))
yticks(Y2,v_y_ticks)
yticklabels(Y2,v(length(v_x_ticks):end))
xlabel(X2,'Specific volume (m³/kg)')

% Pressure
set(Y3, 'YAxisLocation', 'left');
yticks(Y3,P_ticks)
yticklabels(Y3,P_ticks_labels)
ylabel(Y3,'Water partial pressure (Pa)')

% % Enregistrer la fonction de rappel des mouvements de la souris
% set(gcf, 'WindowButtonDownFcn', @mouseClicked);
% 
%     function mouseClicked(~, ~)
%         % Obtenir la position de la souris
%         mousePos = get(gca, 'CurrentPoint');
%         T = mousePos(1,1);
%         w = mousePos(1,2);
%         P = P_H2O_de_w(w);
%         H_G = H_G_de_w(T,w);
%         v = v_de_w(T,w);
%         T_r = T_rosee_de_w(w);
%         T_h = T_h_de_w(T,w);
%         E = E_de_w(T,w);
% 
%         % Afficher la valeur correspondant à la position de la souris
%         if w < w_de_P_vs(T)
%             info = ['T = ',   num2str(T),     '°C, ',       ...
%                 'ω = ',   num2str(w),     ' kg/kg, ',   ...
%                 'P = ',   num2str(P),     ' Pa, ',      ...
%                 'H_G = ', num2str(H_G),   ' kcal/kg, ', ...
%                 'v = ',   num2str(v),     ' m³/kg, ',   ...
%                 'T_r = ', num2str(T_r),   '°C, ',       ...
%                 'T_h = ', num2str(T_h),   '°C, ',       ...
%                 'E = ',   num2str(E*100), '%'];
%             disp(info)
%         end
%     end

end

%% Calculs avec P

% P_vs avec la regression polynomiale
function P_vs = P_vs_reg(T)
Courbe = donnees_P_vs();
coeff_reg = polyfit(Courbe(:,1),Courbe(:,2),5);
P_vs = 0;
for n = 1:length(coeff_reg)
    P_vs = P_vs + coeff_reg(n)*T.^(length(coeff_reg)-n);
end

end

% P_H2O à partir de w
function P_H2O = P_H2O_de_w(w)
P_tot = 101325;
P_H2O = (w.*P_tot)./(0.622 + w);
end

%% Calculs avec w

% w à partir de P_vs
function w = w_de_P_vs(T)
P_tot = 101325;
w = 0.622.*P_vs_reg(T)/(P_tot-P_vs_reg(T));
end

% w à partir de P_H2O
function w = w_de_P_H2O(P_H2O)
P_tot = 101325;
w = 0.622*P_H2O/(P_tot-P_H2O);
end

%% Calculs avec H_G

% H_G à partir de T et w
function H_G = H_G_de_w(T,w)
C_p = 4.1858518 ;% kJ/kcal
H_G = ((1.003+w*1.964)*T+w*2487)/C_p; %kJ/kg → kcal/kg
end

% w à partir de T et H_G
function w = w_de_H_G(T,H_G)
C_p = 4.1858518 ;% kJ/kcal
w = (H_G*C_p-1.003*T)/(1.964*T+2487);
end

% T à partir de w et H_G
function T = T_de_H_G(w,H_G)
C_p = 4.1858518 ;% kJ/kcal
T = (H_G*C_p-2487*w)/(1.003+1.964*w);
end

% Tracer la droite pour une valeur de H_G
function [T,w] = droite_H_G(H_G,T_min,T_max)
T = fzero(@(T) w_de_P_vs(T)-w_de_H_G(T,H_G),T_min);
T = linspace(T,T_max,101);
w = 0*T;
for i=1:length(T)
    w(i) = w_de_H_G(T(i),H_G);
end
w = w(w>=0);
T = T(1:length(w));
if T<T_max
    w = [w,0];
    T = [T,T_de_H_G(0,H_G)];
end
pente_H_G = (w(2)-w(1))/(T(2)-T(1));
pente_P_vs = (w_de_P_vs(T_max)-w_de_P_vs(T_min))/(T_max-T_min);
T_echelle = (pente_P_vs*T_min-pente_H_G*T(1)+w(1)-w_de_P_vs(T_min))/...
    (pente_P_vs-pente_H_G); T_echelle = T_echelle-0.5;
w_echelle = pente_H_G*(T_echelle-T(1))+w(1);
T = [T_echelle,T];
w = [w_echelle,w];
end

% Calculer la pente de la droite de H_G pour une valeur de T
function pente = pente_droite_H_G(T)
T1 = T;
w1 = w_de_P_vs(T);
H_G = H_G_de_w(T1,w1);
T2 = T+1;
w2 = w_de_H_G(T2,H_G);
pente = (w2-w1)/(T2-T1);
end

%% Calculs avec v

% v à partir de T et w
function v = v_de_w(T,w)
R = 8.3145*1000 ;% J/kmol/K
MM_AS = 28.9647; %https://www.engineeringtoolbox.com/air-composition-d_212.html
P_tot = 101325;
v = R*(T+273.15)/(MM_AS*(P_tot-P_H2O_de_w(w)));
end

% T à partir de w et v
function T = T_de_v(w,v)
R = 8.3145*1000 ;% J/kmol/K
MM_AS = 28.9647;
P_tot = 101325;
T = v*(MM_AS*(P_tot-P_H2O_de_w(w)))/R - 273.15;
end

% w à partir de T et v
function w = w_de_v(T,v)
R = 8.3145*1000; % J/kmol/K
MM_AS = 28.9647; % 28.966 avec livre (p. 16)
P_tot = 101325;
P_H2O = P_tot- R*(T+273.15)/(v*MM_AS);
w = w_de_P_H2O(P_H2O);
end

% Tracer la droite pour une valeur de v
function [T,w] = droite_v(v,T_min,T_max)
T = fzero(@(T) w_de_P_vs(T)-w_de_v(T,v),T_min);
T = linspace(T,T_max,101);
w = 0*T;
for i=1:length(T)
    w(i) = w_de_v(T(i),v);
end
w = w(w>=0);
T = T(1:length(w));
if T<T_max
    w = [w,0];
    T = [T,T_de_v(0,v)];
end
end

%% Calculs avec T_rosee

% T_rosee à partir de w
function T_rosee = T_rosee_de_w(w)
T_rosee = fzero(@(T_rosee) w_de_P_vs(T_rosee)-w,0);
end


%% Calculs avec T_h

% T_h à partir de w
function T_h = T_h_de_w(T,w)
T_h = fzero(@(T_h) pente_droite_T_h(T_h)-(w_de_P_vs(T_h)-w)/(T_h-T),T/2);
end

% Calculer la pente de la droite pour une valeur de T
function pente = pente_droite_T_h(T)
h = 0.026*0.71^0.31;        % diapo 32
k_eau = 2.92e-5*0.57^0.31;  % diapo 32
coeff_psychro = h/k_eau;    % diapo 32
pente_H_G = pente_droite_H_G(T);

% Cp_air   = 1.006 ;% kJ/kg/K, livre (p.29)
% Cp_eau   = 4.186 ;% kJ/kg/K, livre (p.29)
%
% cond1 = T>0;
% cond2 = T<0;
%
% if isAlways(cond1)
%     Cp_air_h = 945;%Cp_air+Cp_eau;
% elseif isAlways(cond2)
%     Cp_air_h = 945+0;%Cp_air+Cp_eau+Cp_glace;
% else
%     Cp_air_h = 945;%[Cp_air+Cp_eau,Cp_air+Cp_eau+Cp_glace];
% end
% w = w_de_P_vs(T)/2;
% Cp_air_h = Cp_air+w*Cp_eau;
% rho = 945/1040; % seulement pour maint    enant
% Cp_air_h = Cp_air_h*rho*1000;
% Cp_air_h = 962.6; % seulement pour maintenant

donnees = donnees_Cp();

if T > 0
    donnees = donnees(donnees(:,1)>0,:);
elseif T < 0
    donnees = donnees(donnees(:,1)<0,:);
end
coeff_reg = polyfit(donnees(:,1),donnees(:,2),1);
Cp_air_h = 0;
for n = 1:length(coeff_reg)
    Cp_air_h = Cp_air_h + coeff_reg(n)*T.^(length(coeff_reg)-n);
end
pente = pente_H_G*Cp_air_h./coeff_psychro;
end

% Tracer la droite pour une valeur de T
function [T_h,w_h] = droite_T_h(T,T_max)

if T == 0
    [T_h_neg,w_h_neg] = droite_T_h(T-0.0001,T_max);
    [T_h_pos,w_h_pos] = droite_T_h(T+0.0001,T_max);
    T_h = [flip(T_h_neg),T_h_pos];
    w_h = [flip(w_h_neg),w_h_pos];
else

    if ~exist('pente','var')
        pente = pente_droite_T_h(T);
    end
    T_h = linspace(T,T_max,101);
    w_h = 0*T_h; w_h(1) = w_de_P_vs(T);
    for i=2:length(T_h)
        w_h(i) = w_h(i-1) + pente.*(T_h(i)-T_h(i-1));
    end
    w_h = w_h(w_h>=0);
    T_h = T_h(1:length(w_h));
    if T_h<T_max
        w_h = [w_h,0];
        T_h = [T_h,T_h(end)-w_h(end-1)./pente];
    end
end
end

%% Calculs avec E

% E à partir de T et w
function E = E_de_w(T,w)
w_courbe = w_de_P_vs(T);
E = w./w_courbe;
end

%% Calculs avec Gamma

% Tracer Gamma
function [T_g,w_g] = Gamma(x,y,R_x,R_y,gamma,gamma_labels)
T_g = x + R_x*cos(linspace(0,pi,101));
w_g = y - R_y*sin(linspace(0,pi,101));
plot([x-R_x,x+R_x],[y,y],'-m',T_g,w_g,'-m')
hold on
text(x,y*1.02,'ɣ=Δq/Δω','Color','magenta','HorizontalAlignment','center','Clipping','on')
text(x+R_x*1.05,y,'+∞','Color','magenta','HorizontalAlignment','left','Clipping','on')
text(x-R_x*1.05,y,'-∞','Color','magenta','HorizontalAlignment','right','Clipping','on')
x_label = @(theta) x - R_x*1.15*cos(deg2rad(theta));
y_label = @(theta) y - R_y*1.1*sin(deg2rad(theta));
for i=1:length(gamma)
    theta = theta_de_Gamma(gamma(i),R_x,R_y);
    plot([x,x-R_x*cos(deg2rad(theta))],[y,y-R_y*sin(deg2rad(theta))],'-m')
    if ismember(gamma(i),gamma_labels)
        text(x_label(theta),y_label(theta),string(gamma(i)),...
            'Color','magenta','HorizontalAlignment','center','Clipping','on')
    end
end
end

function gamma = gamma_de_H_G_et_w(w1,w2,H_G1,H_G2)
gamma = (H_G2-H_G1)/(w2-w1);
end

function theta = theta_de_Gamma(gamma, R_x_gamma, R_y_gamma)
T1 = 40;
w1 = w_de_P_vs(T1/2);
H_G1 = H_G_de_w(T1,w1);
w2 = @(theta) w1-sin(deg2rad(theta))*R_y_gamma/R_x_gamma;
T2 = @(theta) T1+cos(deg2rad(theta));
H_G2 = @(theta) H_G_de_w(T2(theta),w2(theta));
theta = fzero(@(theta) gamma_de_H_G_et_w(w1,w2(theta),H_G1,H_G2(theta))-gamma,90);
end

%% Données

function Courbe = donnees_P_vs()
P_tot = 101325 ;% Pa
Courbe_T_w = [-15,    0.001;
    -10.5,  0.0015;
    - 7.5,  0.002;
    - 5,    0.0025;
    - 2.75, 0.003;
    - 0.75, 0.0035;
    0.75, 0.004;
    2.5,  0.0045;
    4,    0.005;
    5.25, 0.0055;
    6.5,  0.006;
    7.75, 0.0065;
    8.75, 0.007;
    9.75, 0.0075;
    10.75, 0.008;
    11.75, 0.0085;
    12.5,  0.009;
    13.25, 0.0095];
Courbe_T_Pvs = [Courbe_T_w(:,1) Courbe_T_w(:,2).*P_tot./(Courbe_T_w(:,2)+0.622)];
Courbe_T_PvsA = [14:60;10.^(10.23-1750./((14:60)+235))]';
Courbe = [Courbe_T_Pvs;Courbe_T_PvsA];
end

function Donnees = donnees_Cp()
Donnees = [-10, 825.6;
    - 5, 837.3;
    14, 957.5;
    35, 983.5;
    25, 974.8;
    30, 985.4;
    19, 962.6];
end

% Fix in the future:
% - gamma with 2 clicks,
% - axes showing properly,
% - C_p with formula instead of regression