
* Setting
$eolcom //


$if not set LOADDATA     $set LOADDATA          1
$if not set START        $set START             1
$if not set END          $set END               306817
$if not set FIXEDVRE     $set FIXEDVRE          0
$if not set COSTVRE      $set COSTVRE           default
$if not set COSTSTO      $set COSTSTO           default
$if not set NOLOSS       $set NOLOSS            0
$if not set NOCHARGELIM  $set NOCHARGELIM       0
$if not set FLEXBIO      $set FLEXBIO           0


SET

allt                     all possible hours     /1*306817/
alltec                   all possible techs     /pv,on,off,bio,ror,hydro,bat,h2,bioflex/
allyear                  all possible years     /1982*2016/

t(allt)                  hour of the 35 years   /%START%*%END%/

tec(alltec)              used techs             /pv,on,off,bio,ror,hydro,bat,h2,bioflex/
tec_vre(tec)             VRE techs              /pv,on,off/
tec_exo(tec)             exogenous techs        /bio,ror/
tec_sto(tec)             storage techs          /hydro,bat,h2,bioflex/
tec_sto_bi(tec_sto)      biderectional storage  /hydro,bat,bioflex/

;


PARAMETER

* Input parameters read in from excel (i_)
i_ts(allt,*)
i_tec(alltec,*)

* Model Parameters (no prefix)
load(t)                     hourly load                         (GW)       
profile(t,tec_vre)          hourly vre profiles                 (GW per GW installed)
gene_exo(t,tec_exo)         exogenous generation                (GW)
natural_inflow(t,tec_sto)   natural inflow to (hydro) storage   (GW)

capa0(tec)                  exogenous generation capacity       (GW)
capa_charge0(tec_sto)       exogenous charge capacity           (GW)
capa_sto0(tec_sto)          exogenous energy capacity           (TWh)

afc(tec)                    annualized fixed cost               (EUR per kWa = MEUR per GWa)
afc_charge(tec_sto)         annualized fixed cost per charging  (EUR per kWa) - if not included in afc (electrolyzers)
afc_sto(tec_sto)            annualized fixed cost per energy    (EUR per kWh)
eff(tec_sto)                storage discharge efficiency        (1)
eff_charge(tec_sto)         storage charge efficiency           (1)

* Scalars
th                          /1000/
little                      /0.000001/
;


* READ EXCEL

$onecho > input_time_series.txt
par=i_ts                    rng=ts!a1:h306818       rdim=1 cdim=1
$offecho

$IF %LOADDATA% == '1'       $CALL GDXXRW.exe        input_time_series.xlsx      @input_time_series.txt

$GDXIN input_time_series.gdx
$LOADdc i_ts



$onecho > input_scalars.txt
par=i_tec                   rng=tec!a4:j13          rdim=1 cdim=1
$offecho

$IF %LOADDATA% == '1'       $CALL GDXXRW.exe        input_scalars.xlsx          @input_scalars.txt

$GDXIN input_scalars.gdx
$LOADdc i_tec


* DEFINE MODEL PARAMETERS

load(t)                   = i_ts(t,"load") / th;
gene_exo(t,tec_exo)       = i_ts(t,tec_exo) / th;
profile(t,tec_vre)        = i_ts(t,tec_vre);
natural_inflow(t,tec_sto) = i_ts(t,tec_sto) / th;

capa0(tec)                = i_tec(tec,"capa");
capa_charge0(tec_sto)     = i_tec(tec_sto,"capa_charge");
capa_sto0(tec_sto)        = i_tec(tec_sto,"capa_sto");
                          
afc(tec)                  = i_tec(tec,"afc");
afc_charge(tec_sto)       = i_tec(tec_sto,"afc_charge");
afc_sto(tec_sto)          = i_tec(tec_sto,"afc_sto");
                          
eff(tec_sto)              = i_tec(tec_sto,"eff");
eff_charge(tec_sto)       = i_tec(tec_sto,"eff_charge");

* Alternative cost scenarios

$IF %COSTVRE%=='high' afc(tec_vre)          = 1.2 * i_tec(tec_vre,"afc");
$IF %COSTVRE%=='low'  afc(tec_vre)          = 0.8 * i_tec(tec_vre,"afc");
$IF %COSTSTO%=='high' afc(tec_sto)          = 1.2 * i_tec(tec_sto,"afc");
$IF %COSTSTO%=='high' afc_charge(tec_sto)   = 1.2 * i_tec(tec_sto,"afc_charge");
$IF %COSTSTO%=='high' afc_sto(tec_sto)      = 1.2 * i_tec(tec_sto,"afc_sto");

* Simplified storage scenarios

$IF %NOLOSS%=='1'       eff(tec_sto)        = 1;
$IF %NOLOSS%=='1'       eff_charge(tec_sto) = 1;
$IF %NOCHARGELIM%=='1'  afc_charge(tec_sto) = 0;


display load, tec_exo, profile, capa0, capa_charge0, capa_sto0, afc, eff, eff_charge


POSITIVE VARIABLES
* Investment (and other yearly variables)
CAPA(tec)                   Installed capacity          (GW)
CAPA_CHARGE(tec_sto)        Installed charging capa     (GW)
CAPA_STO(tec_sto)           Installed energy capa       (GWh)

* Dispatch (and other hourly variables)
GENE(t,tec_vre)             generation                  (GW)
CURTAIL(t)                  curtailment                 (GW)
LEVEL(t,tec_sto)            storage level               (GWh)
CHARGE(t,tec_sto)           storage charge              (GW)
DISCHARGE(t,tec_sto)        storage discharge           (GW)
;


VARIABLES
COST                        total system cost           (MEUR)
;


EQUATION
E
C
S1, S2, S3, S4, S5
O
;

* Energy balance
E(t)..              load(t)                 =E= sum(tec_vre, GENE(t,tec_vre))
                                              + sum(tec_exo, gene_exo(t,tec_exo))
                                              + sum(tec_sto, DISCHARGE(t,tec_sto) - CHARGE(t,tec_sto)) - CURTAIL(t);

* Availability
C(t,tec_vre)..      GENE(t,tec_vre)         =E= profile(t,tec_vre) * CAPA(tec_vre);

* Storage
S1(t,tec_sto)..     LEVEL(t,tec_sto)        =E= LEVEL("%END%",tec_sto)$(ord(t)=1)
                                              + LEVEL(t-1,tec_sto)$(ord(t)>1)
                                              + natural_inflow(t,tec_sto) / eff(tec_sto)
                                              + eff_charge(tec_sto) * CHARGE(t,tec_sto)
                                              - DISCHARGE(t,tec_sto) / eff(tec_sto);
                                              
S2(t,tec_sto)..     DISCHARGE(t,tec_sto)    =L= CAPA(tec_sto) + capa0(tec_sto);
S3(t,tec_sto)..     CHARGE(t,tec_sto)       =L= CAPA_CHARGE(tec_sto) + capa_charge0(tec_sto);
S4(t,tec_sto_bi)..  CAPA(tec_sto_bi)        =E= CAPA_CHARGE(tec_sto_bi);   
S5(t,tec_sto)..     LEVEL(t,tec_sto)        =L= CAPA_STO(tec_sto) + capa_sto0(tec_sto);

* Total system costs
O..                 COST                    =E= sum(tec, CAPA(tec) * afc(tec))
                                              + sum(tec_sto, CAPA_CHARGE(tec_sto) * afc_charge(tec_sto)
                                                           + CAPA_STO(tec_sto)    * afc_sto(tec_sto))
                                              - sum(t, CURTAIL(t) * little);


MODEL RE100 /
E
C
S1, S2, S3, S4, S5
O
/;


* Fixed varaibles

CAPA.FX("hydro") = 0;
CAPA_CHARGE.FX("hydro") = 0;
CAPA_STO.FX("hydro") = 0;

CAPA.FX("bioflex")        = 0;
CAPA_CHARGE.FX("bioflex") = 0;

$IF not %FLEXBIO%=='0' CAPA.FX("bioflex") = capa0(tec) - gene_exo("1","bio");
$IF not %FLEXBIO%=='0' CAPA_CHARGE.FX("bioflex") = gene_exo("1","bio");

CAPA_STO.FX("bioflex") = %FLEXBIO% * 2000;

$IF %FIXEDVRE%=='1' CAPA.FX(tec_vre) = i_tec(tec_vre,"optimal");


RE100.optfile=1;                   // 1 is rendered as solvername.opt i.e. cplex.opt
RE100.reslim=50000;                // limits solving time to 14h

RE100.threads=-1;



SOLVE RE100 USING LP minimizing COST;

display CAPA.L, CAPA_CHARGE.L, CAPA_STO.L, E.M;


PARAMETER
o_stats(*)
output(*,*)
o_ts(t,*,*)
;

o_stats("modelstatus")                                      = RE100.modelstat;
o_stats("minutes")                                          = RE100.resusd / 60;

output(tec_vre, "Mean energy supply (GW)")                  = sum(t, GENE.L(t,tec_vre)) / card(t);
output(tec_sto, "Mean energy supply (GW)")                  = sum(t, DISCHARGE.L(t,tec_sto)) / card(t);
output(tec_exo, "Mean energy supply (GW)")                  = sum(t, gene_exo(t,tec_exo)) / card(t);

output("load",  "Mean energy consumption (GW)")             = sum(t, load(t)) / card(t);
output("curt",  "Mean energy consumption (GW)")             = sum(t, CURTAIL.L(t)) / card(t);
output(tec_sto, "Mean energy consumption (GW)")             = sum(t, CHARGE.L(t,tec_sto)) / card(t);

output(tec,     "Supply capacity (GW)")                     = CAPA.L(tec) + capa0(tec) + eps;
output("load",  "Consumption capacity (GW)")                = smax(t, load(t));
output("curt",  "Consumption capacity (GW)")                = smax(t, CURTAIL.L(t));
output(tec_sto, "Consumption capacity (GW)")                = CAPA_CHARGE.L(tec_sto) + capa_charge0(tec_sto);
output(tec_sto, "Storage capacity (TWh)")                   = (CAPA_STO.L(tec_sto) + capa_sto0(tec_sto)) / th;

output(tec,     "Generation cost per load (€/MWh)")         = CAPA.L(tec) * afc(tec) / sum(t, load(t)) * th;
output(tec_sto, "Charging capacity cost per load (€/MWh)")  = CAPA_CHARGE.L(tec_sto) * afc_charge(tec_sto) / sum(t, load(t)) * th;
output(tec_sto, "Storage capacity cost per load (€/MWh)")   = CAPA_STO.L(tec_sto) * afc_sto(tec_sto) / sum(t, load(t)) * th;
output("load",  "System cost per load (€/MWh)")             = COST.L / sum(t, load(t)) * th;

o_ts(t,"prices","") = -E.M(t) * th;

o_ts(t,"supply",tec_vre) = GENE.L(t,tec_vre);
o_ts(t,"supply",tec_sto) = DISCHARGE.L(t,tec_sto);
o_ts(t,"supply",tec_exo) = gene_exo(t,tec_exo);

o_ts(t,"consumption","load") = load(t);
o_ts(t,"consumption","curt") = CURTAIL.L(t);
o_ts(t,"consumption",tec_sto) = CHARGE.L(t,tec_sto);

o_ts(t,"soc",tec_sto) = LEVEL.L(t,tec_sto);

display output, o_ts;

* To gdx

execute_unload 'output.gdx'
o_stats
output
o_ts
;

* To excel

$onEcho > output.txt
epsOut=0
par=o_stats             rng=modelstats!a2                   intAsText=N
par=output              rng=output!a2                       intAsText=N
par=o_ts                rng=ts!a2      cDim=2               intAsText=N
$offEcho

execute 'move output.xlsx trash'
execute 'move output_%START%_%END%_FIXEDVRE%FIXEDVRE%_COSTVRE%COSTVRE%_COSTSTO%COSTSTO%_NOLOSS%NOLOSS%_NOCHARGELIM%NOCHARGELIM%_BIOFLEX%BIOFLEX%.xlsx trash'

execute 'copy output_template.xlsx output.xlsx'

execute 'gdxxrw.exe output.gdx output=output.xlsx @output.txt'

execute 'ren output.xlsx output_%START%_%END%_FIXEDVRE%FIXEDVRE%_COSTVRE%COSTVRE%_COSTSTO%COSTSTO%_NOLOSS%NOLOSS%_NOCHARGELIM%NOCHARGELIM%_FLEXBIO%FLEXBIO%.xlsx'
