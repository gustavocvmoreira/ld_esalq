* UNEQUAL CRIME REPORTING: TRUST IN THE POLICE AND RACIAL DISPARITIES IN PROPERTY CRIME REPORTING IN BRAZIL
* Author: Gustavo C Moreira
* Esalq-USP
* Brazil 

clear all
set more off

********************************************************************************
* 0) IMPORTAR DADOS (FIXED WIDTH)
********************************************************************************
* Observacao
* Firearm no roubo aparece no dicionario com:
*  S100343 pos 833 tam 1
*  S100423 pos 879 tam 1
*  S100503 pos 925 tam 1
*  S100573 pos 939 tam 1
*  S100653 pos 1061 tam 1

#delimit ;
infix uf 6-7
     urb 33-33
     sexo 95-95
     raca 107-107
     idade 104-106
     peso 50-64
     trabalha 136-136
     educ 1052-1052
     rdpct 1207-1214

     confia_policia 555-555
     assalto_roubo_redondeza 543-543

     proc1 617-617   prevreg1 623-623
     proc2 626-626   prevreg2 632-632
     proc3 635-635   prevreg3 641-641
     proc4 651-651   prevreg4 657-657

     theft_cell 752-752
     theft_doc  754-754

     proc5 809-809   prevreg5 815-815
     proc6 855-855   prevreg6 861-861
     proc7 901-901   prevreg7 907-907
     proc8 932-932   prevreg8 938-938

     robbery_cell 1037-1037
     robbery_doc  1039-1039

     S100343 833-833
     S100423 879-879
     S100503 925-925
     S100573 939-939
     S100653 1061-1061

using "C:\Users\gusta\OneDrive\Repositório Artigos\Iluminação e medo\PNAD 2021\PNADC_2021_trimestre4_20221207\PNADC_2021_trimestre4.txt", clear ;
#delimit cr

********************************************************************************
* 1) CRIME TYPE, OUTCOMES POR MODULO, E VARIAVEIS POR TIPO
********************************************************************************

* contagem de vitimizacoes por tipo (proc==1 ou 2)
gen n_theft = 0
foreach j in 1 2 3 4 {
    replace n_theft = n_theft + inlist(proc`j',1,2)
}

gen n_robbery = 0
foreach j in 5 6 7 8 {
    replace n_robbery = n_robbery + inlist(proc`j',1,2)
}

gen victim_theft   = (n_theft>0)
gen victim_robbery = (n_robbery>0)

* outcomes por tipo: registrou BO ao menos uma vez no modulo
gen reported_theft = .
replace reported_theft = 0 if victim_theft==1
replace reported_theft = 1 if victim_theft==1 & ///
    (inlist(prevreg1,1) | inlist(prevreg2,1) | inlist(prevreg3,1) | inlist(prevreg4,1))

gen reported_robbery = .
replace reported_robbery = 0 if victim_robbery==1
replace reported_robbery = 1 if victim_robbery==1 & ///
    (inlist(prevreg5,1) | inlist(prevreg6,1) | inlist(prevreg7,1) | inlist(prevreg8,1))

* previously victimized por tipo (revitimizacao no periodo)
gen previously_victimized_theft = .
replace previously_victimized_theft = 0 if victim_theft==1 & n_theft==1
replace previously_victimized_theft = 1 if victim_theft==1 & n_theft>1

gen previously_victimized_robbery = .
replace previously_victimized_robbery = 0 if victim_robbery==1 & n_robbery==1
replace previously_victimized_robbery = 1 if victim_robbery==1 & n_robbery>1

* vehicle-related por tipo (carro ou moto) conforme seu criterio
gen vehicle_theft = 0
replace vehicle_theft = 1 if inlist(proc1,1,2) | inlist(proc2,1,2)

gen vehicle_robbery = 0
replace vehicle_robbery = 1 if inlist(proc5,1,2) | inlist(proc6,1,2)

* documents or cellphone taken por tipo
foreach v in theft_cell theft_doc robbery_cell robbery_doc {
    replace `v' = 0 if `v'==2
    replace `v' = . if inlist(`v',3,9)
}

gen docs_cell_taken_theft = .
replace docs_cell_taken_theft = 0 if victim_theft==1
replace docs_cell_taken_theft = 1 if victim_theft==1 & (theft_cell==1 | theft_doc==1)

gen docs_cell_taken_robbery = .
replace docs_cell_taken_robbery = 0 if victim_robbery==1
replace docs_cell_taken_robbery = 1 if victim_robbery==1 & (robbery_cell==1 | robbery_doc==1)

* firearm no roubo em varios quesitos: indicador consolidado (qualquer roubo com arma)
foreach v in S100343 S100423 S100503 S100573 S100653 {
    replace `v' = 0 if `v'==2
    replace `v' = . if inlist(`v',3,9)
}

gen firearm_robbery_any = .
replace firearm_robbery_any = 0 if victim_robbery==1
replace firearm_robbery_any = 1 if victim_robbery==1 & ///
    (S100343==1 | S100423==1 | S100503==1 | S100573==1 | S100653==1)

label define fire_lbl 0 "No firearm" 1 "Firearm involved"
label values firearm_robbery_any fire_lbl
label var firearm_robbery_any "Firearm involved (robbery)"

********************************************************************************
* 2) CONTROLES (LABELS EM INGLES)
********************************************************************************

* trust binaria: high trust = (1,2), low trust = (3,4)
recode confia_policia (9=.)
gen high_trust = .
replace high_trust = 1 if inlist(confia_policia,1,2)
replace high_trust = 0 if inlist(confia_policia,3,4)
label define trustb_lbl 0 "Low trust" 1 "High trust"
label values high_trust trustb_lbl
label var high_trust "High trust"

* sexo
recode sexo (2=0) (9=.)
label define male_lbl 0 "Female" 1 "Male"
label values sexo male_lbl
label var sexo "Male"

* raca
recode raca (9=.)
recode raca (1=0) (2 3 4 5=1)
label define nonwhite_lbl 0 "White" 1 "Non-white"
label values raca nonwhite_lbl
label var raca "Non-white"

* educacao
recode educ (1 2 3 4 5 6=0) (7=1) (9=.)
label define he_lbl 0 "No higher education" 1 "Higher education"
label values educ he_lbl
label var educ "Higher education"

* trabalha
recode trabalha (2=0) (9=.)
label define emp_lbl 0 "Not employed" 1 "Employed"
label values trabalha emp_lbl
label var trabalha "Employed"

* renda em quartis (base Q1)
replace rdpct = rdpct/1000
astile income_q = rdpct, nq(4)
label define incq_lbl 1 "Income Quartile Q1" 2 "Income Quartile Q2" 3 "Income Quartile Q3" 4 "Income Quartile Q4"
label values income_q incq_lbl
label var income_q "Income quartile"

* urbano
recode urb (2=0) (9=.)
label define urb_lbl 0 "Rural" 1 "Urban"
label values urb urb_lbl
label var urb "Urban"

* neighborhood crime
recode assalto_roubo_redondeza (2=0) (9=.)
label define neighcrime_lbl 0 "No neighborhood crime" 1 "Neighborhood crime"
label values assalto_roubo_redondeza neighcrime_lbl
label var assalto_roubo_redondeza "Neighborhood crime"

* regiao macro (base North)
gen region = .
replace region=1 if uf<=17
replace region=2 if uf>=21 & uf<=29
replace region=3 if uf>=31 & uf<=35
replace region=4 if uf>=41 & uf<=43
replace region=5 if uf>=50
label define region_lbl 1 "North" 2 "Northeast" 3 "Southeast" 4 "South" 5 "Center-West"
label values region region_lbl
label var region "Region"

label var idade "Age"

********************************************************************************
* 3) ESTIMACAO
********************************************************************************
capture which eststo
capture which esttab
capture which estadd
eststo clear

* =========================
* THEFT: S1 S2 S3 (sem S4)
* =========================
preserve
keep if victim_theft==1
drop if missing(reported_theft)

gen reported = reported_theft
gen previously_victimized = previously_victimized_theft
gen vehicle_crime = vehicle_theft
gen docs_cell_taken = docs_cell_taken_theft

label define prev_lbl 0 "First-time victimization" 1 "Previously victimized"
label values previously_victimized prev_lbl
label define veh_lbl 0 "Non-vehicle crime" 1 "Vehicle-related crime"
label values vehicle_crime veh_lbl
label define loot_lbl 0 "No documents/cellphone taken" 1 "Documents or cellphone taken"
label values docs_cell_taken loot_lbl

label var reported "Reported to the police"
label var previously_victimized "Previously victimized"
label var vehicle_crime "Vehicle-related crime"
label var docs_cell_taken "Documents or cellphone taken"

* S1
quietly probit reported i.high_trust i.raca i.sexo ib1.income_q i.educ c.idade i.trabalha i.previously_victimized [iw=peso]
local N1 = e(N)
local ll1 = e(ll)
local k1  = e(rank)
local AIC1 = -2*`ll1' + 2*`k1'
local BIC1 = -2*`ll1' + ln(`N1')*`k1'
quietly margins, dydx(*) post
eststo theft_S1
estadd scalar Obs = `N1'
estadd scalar AIC = `AIC1'
estadd scalar BIC = `BIC1'

* S2
quietly probit reported i.high_trust i.raca i.sexo ib1.income_q i.educ c.idade i.trabalha i.previously_victimized ///
    i.assalto_roubo_redondeza i.urb ib1.region [iw=peso]
local N2 = e(N)
local ll2 = e(ll)
local k2  = e(rank)
local AIC2 = -2*`ll2' + 2*`k2'
local BIC2 = -2*`ll2' + ln(`N2')*`k2'
quietly margins, dydx(*) post
eststo theft_S2
estadd scalar Obs = `N2'
estadd scalar AIC = `AIC2'
estadd scalar BIC = `BIC2'

* S3
quietly probit reported i.high_trust i.raca i.sexo ib1.income_q i.educ c.idade i.trabalha i.previously_victimized ///
    i.assalto_roubo_redondeza i.urb ib1.region ///
    i.vehicle_crime i.docs_cell_taken [iw=peso]
local N3 = e(N)
local ll3 = e(ll)
local k3  = e(rank)
local AIC3 = -2*`ll3' + 2*`k3'
local BIC3 = -2*`ll3' + ln(`N3')*`k3'
quietly margins, dydx(*) post
eststo theft_S3
estadd scalar Obs = `N3'
estadd scalar AIC = `AIC3'
estadd scalar BIC = `BIC3'
restore

* =========================
* ROBBERY: S1 S2 S3 S4 (S4 antes de S3 na tabela)
* =========================
preserve
keep if victim_robbery==1
drop if missing(reported_robbery)

gen reported = reported_robbery
gen previously_victimized = previously_victimized_robbery
gen vehicle_crime = vehicle_robbery
gen docs_cell_taken = docs_cell_taken_robbery
gen firearm = firearm_robbery_any

label values previously_victimized prev_lbl
label values vehicle_crime veh_lbl
label values docs_cell_taken loot_lbl
label values firearm fire_lbl

label var reported "Reported to the police"
label var previously_victimized "Previously victimized"
label var vehicle_crime "Vehicle-related crime"
label var docs_cell_taken "Documents or cellphone taken"
label var firearm "Firearm involved"

* S1
quietly probit reported i.high_trust i.raca i.sexo ib1.income_q i.educ c.idade i.trabalha i.previously_victimized [iw=peso]
local RN1 = e(N)
local Rll1 = e(ll)
local Rk1  = e(rank)
local RAIC1 = -2*`Rll1' + 2*`Rk1'
local RBIC1 = -2*`Rll1' + ln(`RN1')*`Rk1'
quietly margins, dydx(*) post
eststo robbery_S1
estadd scalar Obs = `RN1'
estadd scalar AIC = `RAIC1'
estadd scalar BIC = `RBIC1'

* S2
quietly probit reported i.high_trust i.raca i.sexo ib1.income_q i.educ c.idade i.trabalha i.previously_victimized ///
    i.assalto_roubo_redondeza i.urb ib1.region [iw=peso]
local RN2 = e(N)
local Rll2 = e(ll)
local Rk2  = e(rank)
local RAIC2 = -2*`Rll2' + 2*`Rk2'
local RBIC2 = -2*`Rll2' + ln(`RN2')*`Rk2'
quietly margins, dydx(*) post
eststo robbery_S2
estadd scalar Obs = `RN2'
estadd scalar AIC = `RAIC2'
estadd scalar BIC = `RBIC2'

* S3 (com firearm)
quietly probit reported i.high_trust i.raca i.sexo ib1.income_q i.educ c.idade i.trabalha i.previously_victimized ///
    i.assalto_roubo_redondeza i.urb ib1.region ///
    i.vehicle_crime i.docs_cell_taken ///
    i.firearm [iw=peso]
local RN3 = e(N)
local Rll3 = e(ll)
local Rk3  = e(rank)
local RAIC3 = -2*`Rll3' + 2*`Rk3'
local RBIC3 = -2*`Rll3' + ln(`RN3')*`Rk3'
quietly margins, dydx(*) post
eststo robbery_S3
estadd scalar Obs = `RN3'
estadd scalar AIC = `RAIC3'
estadd scalar BIC = `RBIC3'

* S4 (sem firearm)
quietly probit reported i.high_trust i.raca i.sexo ib1.income_q i.educ c.idade i.trabalha i.previously_victimized ///
    i.assalto_roubo_redondeza i.urb ib1.region ///
    i.vehicle_crime i.docs_cell_taken [iw=peso]
local RN4 = e(N)
local Rll4 = e(ll)
local Rk4  = e(rank)
local RAIC4 = -2*`Rll4' + 2*`Rk4'
local RBIC4 = -2*`Rll4' + ln(`RN4')*`Rk4'
quietly margins, dydx(*) post
eststo robbery_S4
estadd scalar Obs = `RN4'
estadd scalar AIC = `RAIC4'
estadd scalar BIC = `RBIC4'
restore

********************************************************************************
* 3C) POOLED (theft + robbery)
* Interacao: trust x crime type
* Sem firearm
********************************************************************************
preserve

* manter apenas vitimas com outcome observado
keep if (victim_theft==1 & reported_theft!=.) | ///
        (victim_robbery==1 & reported_robbery!=.)

tempfile basepooled
save `basepooled', replace

* =========================
* THEFT stack
* =========================
use `basepooled', clear
keep if victim_theft==1 & reported_theft!=.

gen robbery = 0
gen reported = reported_theft
gen previously_victimized = previously_victimized_theft
gen vehicle_crime = vehicle_theft
gen docs_cell_taken = docs_cell_taken_theft

tempfile pooled_theft
save `pooled_theft', replace

* =========================
* ROBBERY stack
* =========================
use `basepooled', clear
keep if victim_robbery==1 & reported_robbery!=.

gen robbery = 1
gen reported = reported_robbery
gen previously_victimized = previously_victimized_robbery
gen vehicle_crime = vehicle_robbery
gen docs_cell_taken = docs_cell_taken_robbery

tempfile pooled_robbery
save `pooled_robbery', replace

* =========================
* COMBINAR BASES
* =========================
use `pooled_theft', clear
append using `pooled_robbery'

* labels
label define robbery_lbl 0 "Theft" 1 "Robbery"
label values robbery robbery_lbl
label var robbery "Robbery"

label values previously_victimized prev_lbl
label values vehicle_crime veh_lbl
label values docs_cell_taken loot_lbl

label var reported "Reported to the police"
label var previously_victimized "Previously victimized"
label var vehicle_crime "Vehicle-related crime"
label var docs_cell_taken "Documents or cellphone taken"


********************************************************************************
* 4) EXPORTAR TABELAS
********************************************************************************

* tabela principal (AME)
* ordem do robbery foi trocada: S4 antes de S3
esttab theft_S1 theft_S2 theft_S3 ///
       robbery_S1 robbery_S2 robbery_S4 robbery_S3 ///
using "Table_Main_NoPolicePresence_RobberySwapS4S3.rtf", replace ///
label ///
cells(b(star fmt(3)) se(par fmt(3))) ///
starlevels(** 0.05 * 0.01) ///
collabels("Theft S1" "Theft S2" "Theft S3" ///
          "Robbery S1" "Robbery S2" "Robbery S4" "Robbery S3") ///
nobaselevels nonumbers nodepvars ///
stats(Obs AIC BIC, fmt(0 2 2) labels("Observations" "AIC" "BIC")) ///
varlabels( ///
    1.high_trust "High trust" ///
    1.raca "Non-white" ///
    1.sexo "Male" ///
    2.income_q "Income Quartile Q2" ///
    3.income_q "Income Quartile Q3" ///
    4.income_q "Income Quartile Q4" ///
    1.educ "Higher education" ///
    idade "Age" ///
    1.trabalha "Employed" ///
    1.previously_victimized "Previously victimized" ///
    1.assalto_roubo_redondeza "Neighborhood crime" ///
    1.urb "Urban" ///
    2.region "Northeast" ///
    3.region "Southeast" ///
    4.region "South" ///
    5.region "Center-West" ///
    1.vehicle_crime "Vehicle-related crime" ///
    1.docs_cell_taken "Documents or cellphone taken" ///
    1.firearm "Firearm involved" ///
    _cons "Constant" ///
) ///
addnotes("* p<0.01, ** p<0.05. Average marginal effects from probit models. Weights: [iw=peso].")


********************************************************************************


********************************************************************************
*RUN TABLE A1 (no restore)
********************************************************************************
capture program drop make_tableA1
program define make_tableA1
    version 15.1
    capture confirm variable crime
    if _rc {
        di as error "Variable crime not found. Build the pooled dataset first."
        exit 111
    }
    capture confirm variable peso
    if _rc {
        di as error "Weight variable peso not found."
        exit 111
    }

    * dummies for income quartiles and region
    capture drop inc_q2 inc_q3 inc_q4 reg_ne reg_se reg_s reg_cw
    gen inc_q2 = income_q==2 if !missing(income_q)
    gen inc_q3 = income_q==3 if !missing(income_q)
    gen inc_q4 = income_q==4 if !missing(income_q)
    label var inc_q2 "Income Quartile Q2"
    label var inc_q3 "Income Quartile Q3"
    label var inc_q4 "Income Quartile Q4"

    gen reg_ne = region==2 if !missing(region)
    gen reg_se = region==3 if !missing(region)
    gen reg_s  = region==4 if !missing(region)
    gen reg_cw = region==5 if !missing(region)
    label var reg_ne "Region Northeast"
    label var reg_se "Region Southeast"
    label var reg_s  "Region South"
    label var reg_cw "Region Center-West"

    local vars ///
        reported ///
        high_trust ///
        raca ///
        sexo ///
        idade ///
        educ ///
        trabalha ///
        inc_q2 inc_q3 inc_q4 ///
        previously_victimized ///
        urb ///
        assalto_roubo_redondeza ///
        vehicle_crime ///
        docs_cell_taken ///
        firearm ///
        reg_ne reg_se reg_s reg_cw

    tempname H
    postfile `H' str60 label str32 varname ///
        double mean_all sd_all N_all ///
        double mean_theft sd_theft N_theft ///
        double mean_rob sd_rob N_rob ///
        using tableA1_results, replace

    foreach v of local vars {
        local vl : variable label `v'
        if "`vl'"=="" local vl "`v'"

        quietly summarize `v' [aw=peso] if !missing(`v')
        local m_all = r(mean)
        local sd_all = r(sd)
        quietly count if !missing(`v')
        local n_all = r(N)

        quietly summarize `v' [aw=peso] if crime==0 & !missing(`v')
        local m_t = r(mean)
        local sd_t = r(sd)
        quietly count if crime==0 & !missing(`v')
        local n_t = r(N)

        quietly summarize `v' [aw=peso] if crime==1 & !missing(`v')
        local m_r = r(mean)
        local sd_r = r(sd)
        quietly count if crime==1 & !missing(`v')
        local n_r = r(N)

        post `H' ("`vl'") ("`v'") ///
            (`m_all') (`sd_all') (`n_all') ///
            (`m_t') (`sd_t') (`n_t') ///
            (`m_r') (`sd_r') (`n_r')
    }
    postclose `H'

    use tableA1_results, clear
    format mean_* sd_* %9.3f
    format N_* %9.0f

    putexcel set "Table_A1_Descriptives.xlsx", replace
    putexcel A1 = "Table A1. Descriptive statistics (weighted means and SDs; aweights=peso)"
    putexcel A3 = ("Variable")  B3=("Overall mean") C3=("Overall SD") D3=("N") ///
            E3=("Theft mean")   F3=("Theft SD")   G3=("N") ///
            H3=("Robbery mean") I3=("Robbery SD") J3=("N")

    local r = 4
    quietly count
    local N = r(N)
    forvalues i = 1/`N' {
        putexcel A`r' = label[`i'] ///
                B`r' = mean_all[`i']  C`r' = sd_all[`i']  D`r' = N_all[`i'] ///
                E`r' = mean_theft[`i'] F`r' = sd_theft[`i'] G`r' = N_theft[`i'] ///
                H`r' = mean_rob[`i']  I`r' = sd_rob[`i']  J`r' = N_rob[`i']
        local ++r
    }
    di as txt "Saved: Table_A1_Descriptives.xlsx"
end

