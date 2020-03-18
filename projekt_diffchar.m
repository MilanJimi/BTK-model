% Calculates derivation of I-V characteristic of PCS according to BTK theory
function [X,Y]=projekt_diffchar(BTKParams)
    global Ecmp_rng Settings;                   % rozsah, na ktorom sa vypocita dif.charakteristika (v mV)
    Eint_rng=Settings.Eint_rng;                 % rozsah, na ktorom sa integruje cez energie (v mV) - musi byt vacsi, 
                                                    % ako vysledny rozsah, aby sa odstranili okrajove efekty
    global N ET dE;                             % rovnomerne vzdialene (dE) diskretne hodnoty energii (ET), 
                                                    % cez ktore sa integruje a ktorych pocet je N (N je vzdy parne!)
    global D1 D2 W G1 G2 Z1 Z2 TT1 TT2 P;         % lokalne premenne v ramci tohoto suboru

    D1=BTKParams.Delta1.Value;
    D2=BTKParams.Delta2.Value;
    W=BTKParams.Weight.Value;
    P=BTKParams.Polarization.Value;
    G1=BTKParams.Gamma1.Value;
    G2=BTKParams.Gamma2.Value;
    Z1=BTKParams.Zparam1.Value;
    Z2=BTKParams.Zparam2.Value;

    N=Settings.Npoints;
    
    [m,n]=size(ET);
    TT1=zeros([m,n]);
    TT2=zeros([m,n]);
    Eint_irng=floor(Eint_rng/dE);
    for i=(N/2-Eint_irng):(N/2)
        TT1(i)=TransferProbability(ET(i),D1,G1,Z1);
        TT2(i)=TransferProbability(ET(i),D2,G2,Z2);
    end;
    % druha polovicka je symetricka
    for i=(N/2+1):(N/2+Eint_irng)
        TT1(i)=TT1(N-i+1);
        TT2(i)=TT2(N-i+1);
    end;

    idx=1;
    X=zeros([1 round(2*Ecmp_rng/dE)]);
    Y=zeros([1 round(2*Ecmp_rng/dE)]);
    for i=1:n
        if ((ET(i)>=-Ecmp_rng)&&(ET(i)<0))
            X(idx)=ET(i);
            Y(idx)=CurrentDeriv(ET(i));
            idx=idx+1;
        end;
    end;
    midx=idx;               % druha polovicka je zrkadlovy obraz => uz to netreba ratat
    for i=1:n
        if ((ET(i)>0)&&(ET(i)<=Ecmp_rng))
            midx=midx-1;    % musi sa znizit, pretoze posledne sa idx zvysil a nevyuzilo sa to
            X(idx)=ET(i);
            Y(idx)=Y(midx);
            idx=idx+1;
        end;
    end;

function [Nsin,Ncos]=DensOfStates(E,D,G)
    E2=E*E;
    G2=G*G;
    D2=D*D;
    E=abs(E);
    Fi=atan2(-G,E) - atan2(-2*G*E,E2-G2-D2)/2;
    N=sqrt((E2+G2)/sqrt((E2-G2-D2)^2 + 4*E2*G2));
    Ncos=cos(Fi)/N;
    Nsin=sin(Fi)/N;
    
function [TP]=TransferProbability(E,D,G,Z)
    [b,c]=DensOfStates(E,D,G);
    a1=(1+c)/2;
    a2=(1-c)/2;
    b=-b/2; 
    Z2=Z*Z;
    gam=(a1+Z2*c)^2 + (b*(2*Z2+1))^2;
    A=sqrt((a1*a1+b*b)*(a2*a2+b*b));
    B=(Z2*c-2*Z*b)^2 + (Z*(2*Z*b+c))^2;
    TP=1+(A-B)/gam;

function [dI]=CurrentDeriv(V)
    global N; global dE;    % celkovy pocet bodov funkcie dFT zavislej od energie a vzdielenost jednotlivych hodnot energii
    global dFT;             % predratana derivacia fermiho funkcie normovanej na fermiho plochu - maximum je v dFT(N/2), pricom ET(N/2)=0
    global Emask_irng;      % pocet diskretnych energii, na ktorych predstavuje integral z dFT 99% plochy 
                                % z celkovehej plochy ziskanej z integrovania celej funkcie dFT cez vsetky hodnoty energii
    global TT1 TT2 W Z1 Z2 P; % lokalne premenne v ramci tohoto suboru
    
    Vi=floor(V/dE);
    part1=0; part2=0;
    for i=(N/2-Emask_irng/2):(N/2+Emask_irng/2)
        part1=part1+dFT(i)*TT1(i+Vi);
        part2=part2+dFT(i)*TT2(i+Vi);
    end;
    dI=(1+Z1*Z1)*W*part1+(1+Z2*Z2)*(1-W)*part2;
