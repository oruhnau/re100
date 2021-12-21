
* Base case

execute "gams  RE100.gms --LOADDATA=1"

* Sensitivities without losses and without charging limitation

execute "gams  RE100.gms --FIXEDVRE=1 --NOLOSS=1"
execute "gams  RE100.gms --FIXEDVRE=1 --NOLOSS=1 --NOCHARGELIM=1"

* Sensitivities with flexible bioenergy

execute "gams  RE100.gms --FIXEDVRE=0 --FLEXBIO=1"

execute "gams  RE100.gms --FIXEDVRE=0 --FLEXBIO=2"

execute "gams  RE100.gms --FIXEDVRE=0 --FLEXBIO=3"

execute "gams  RE100.gms --FIXEDVRE=0 --FLEXBIO=4"

execute "gams  RE100.gms --FIXEDVRE=0 --FLEXBIO=5"

* Sensitivities regarding VRE cost (not used in paper)

*execute "gams  RE100.gms --COSTVRE=high"

*execute "gams  RE100.gms --COSTVRE=low"
