% Precals Fermi function and its derivation for specific temperature
function projekt_precalc(Temp)
    global Settings;
    global dE ET FT dFT Emask_irng;
    global k T N;

    k=8.617347e-5;
    T=Temp;
    N=Settings.Npoints;
    Emax_rng=Settings.Emax_rng;

    dE=2*Emax_rng/N;
    ET=zeros([1 N]); % Tabulka dostupnych diskretnych energii
    FT=zeros([1 N]); % Tabulka fermiho funkcie od energie
    dFT=zeros([1 N]); % Tabulka derivacie fermiho funkcie 
    for i=1:N
        ET(i)=-Emax_rng+i*dE-dE/2; % dE/2 je kvoli tomu, aby tam nebola nulova energia (lebo by neskor doslo k deleniu nulou)
        FT(i)=FermiFun(ET(i));
        dFT(i)=FermiFunDeriv(ET(i),0);
    end;
    
    % zoberie iba cast f-cie, pod ktorou je 99% plochy
    th=0.01*max(dFT);
    tmp=(dFT>th);
    Emask_irng=0;
    for i=1:N
        if (~tmp(i))
            dFT(i)=0;
        else
            Emask_irng=Emask_irng+1; % pocet nenulovych hodnot masky
        end;
    end;
    
    % tych 99% normalizujem na 100%
    A=sum(dFT);
    dFT=dFT/A;

function [f]=FermiFun(E)
    global k T;
    x=E/(k*T);
    f=1/(1+exp(x));
    
function [df]=FermiFunDeriv(E,V)
    global k T;
    kT=k*T;
    ex=exp((E-V)/kT);
    f=1/(1+ex);
    df=f*f*ex/kT;
