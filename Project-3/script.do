use delay_final.dta, clear

gen age_group = 1 
replace age_group = 2 if age>29
replace age_group = 3 if age>39
replace age_group = 4 if age>49
replace age_group = 5 if age>59
replace age_group = 6 if age>69

label define age_group 1 "<=29" 2 "30-39" 3 "40-49" 4 "50-59" 5 "60-69" 6 ">=70"
label values age_group age_group


replace Education = 5 if Education == 6
replace marital = 2 if marital == 3

* Table 1
sum age
tab age_group
tab Education
tab Occupation
tab marital
tab Comor
tab SLT
tab Income

* Table 2
tab symptoms



* Table 3
tab firstdoc

gen sympseek_cat = 1
replace sympseek_cat = 2 if sympseek>1
replace sympseek_cat = 3 if sympseek>3
replace sympseek_cat = 4 if sympseek>6
replace sympseek_cat = 5 if sympseek>12
label define sympseek_cat 1 "0-1 months" 2 "1-3 months" 3 "3-6 months" 4 "6-12 months" 5 ">12 months"
label values sympseek_cat sympseek_cat
tab sympseek_cat


* Table 4
tab delayedstartrx
tab causesdelayedrx

tab delayedseeking
tab causesdelayed


* Table 5
tab familybreastchistory delayedstartrx, col chi2 exact
tab firstsymptoms delayedstartrx, col chi2 exact

tab symp_lump delayedstartrx, col chi2 exact
tab symp_pain delayedstartrx, col chi2 exact
tab symp_swelling delayedstartrx, col chi2 exact
tab symp_axila delayedstartrx, col chi2 exact
tab symp_pulling delayedstartrx, col chi2 exact

tabi 28 175 \ 1 23 \ 1 1 \ 0 1 \ 0 2, col chi2


* Table 6
tab seek_homeopathy delayedstartrx, col chi2 exact
tab seek_nothing_serious delayedstartrx, col chi2 exact
tab seek_financial delayedstartrx, col chi2 exact
tab seek_stigma delayedstartrx, col chi2 exact
tab seek_relief delayedstartrx, col chi2 exact
tab seek_fear delayedstartrx, col chi2 exact
tab seek_others delayedstartrx, col chi2 exact

tabi 12 83 \ 4 25 \ 2 4 \ 3 0 \ 2 8 \ 0 1 \ 0 2, col chi2
tab staging delayedstartrx, col chi2 exact

* Table 7
tab staging delayeddiagnosis, col chi2 exact



* Table 8
tab  Income delayedstartrx, col chi2 exact
tab  Education delayedstartrx, col chi2 exact
tab  Occupation delayedstartrx, col chi2 exact
tab  age_group delayedstartrx, col chi2 exact

 
* Table 9
tab Comor staging, col chi2 exact
tab surgery staging, col chi2 exact
tab metastasis staging, col chi2 exact


recode delayedstartrx (2=0)
label define delayedstartrx 1 "Yes" 0 "No", replace

logit delayedstartrx i.age_group 

recode metastasis (2=0)
label define metastasis 1 "Yes" 0 "No", replace

recode familybreastchistory (2=0)
label define familybreastchistory 1 "Yes" 0 "No", replace

logistic delayedstartrx i.age_group i.Residence i.Education i.Income i.familybreastchistory i.firstdoc agemenarche i.staging i.metastasis, or


















logistic delayedstartrx i.age_group i.Sex i.Residence i.marital i.Education i.Occupation i.Smoking i.Income i.familybreastchistory i.firstdoc agemenarche i.staging i.metastasis


i.symptoms 


