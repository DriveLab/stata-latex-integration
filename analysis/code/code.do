// Title: code.do
// Author: Fabian Gunzinger
// Description: Cleans the data and presents results
// Input: maindata.xlsx, townnames.xlsx
// Output: data.dta, table.tex, figure.pdf
// Version: 13.1


log close _all
clear all
set maxvar 5000
set matsize 1000
set more off
pause on


cd "/Users/fabiangunzinger/Library/Mobile Documents/com~apple~CloudDocs/fab/guides/stata-latex/analysis"




///////////
// Setup //
///////////


// Specify directories
global root_dir "`c(pwd)'"						// Root directory
global data_input_dir "$root_dir/data/input"	// Raw data
global data_output_dir "$root_dir/data/output"	// Final data
global output_dir "$root_dir/output"			// Figures and tables
global log_dir "$root_dir/log"			 		// Log files


// Options
set scheme burd


// Start log and timer
global currentdate = date("$S_DATE", "DMY")
local stringdate : di %td_CY.N.D date("$S_DATE", "DMY")
global stamp = trim("`stringdate'")
log using "$log_dir/stata-latex_${stamp}.log", name(`c(username)') text replace
timer clear
timer on 1


// Customise program
global datacleaningflag = 1				// Clean data off/on
global tableflag = 1					// Produce table off/on
global figureflag = 1					// Produce figure off/on



///////////////////
// Data cleaning //
///////////////////


if $datacleaningflag {

	// A. Import raw data
	import excel using "$data_input_dir/maindata.xlsx", firstrow
	sum _all


	// B. Create polling booth ID variable ('unique' breaks ties arbitrarily)
	egen booth_id = rank(-turnout_total), unique by(town_id)


	// C. Recode "-999" as missing values
	mvdecode registered_*, mv(-999=.)
	sum _all


	// "-998" inadvertently entered for missing data too - recode also.
	mvdecode registered_*, mv(-998=.)
	sum _all


	// D. Generate dummies for town_id (uses -dummieslab- from SSC.)
	dummieslab town_id


	// E. Add town names (option 'keep(match master)' retains matched towns as well as unmatched towns from the master dataset. Merge output shows that all towns from master were matched to a name.)
	preserve
		import excel using "$data_input_dir/townnames.xlsx", clear firstrow
		rename TownID town_id
		rename TownName town_name
		tempfile tempTownNames
		save `tempTownNames', replace
	restore
	merge m:1 town_id using `tempTownNames', nogen keep(match master)


	// F. Label variables
	foreach v of varlist town_id* booth_id town_name {
		label var `v' "ID variable"
	}

	foreach v of varlist turnout_* registered_* {
		label var `v' "Electoral data"
	}
	
	foreach v of varlist treatment {
		label var `v' "Intervention"
	}


	// G. Label values of treatment variable
	label define UntreatTreat 0 "Untreated" 1 "Treated"
	label values treatment UntreatTreat
	tab treatment


	// Save data
	save "$data_output_dir/stata-test", replace

}



/////////////////////////////
// Produce table for LaTeX //
/////////////////////////////

if $tableflag {

	use "$data_output_dir/stata-test", clear

	label var registered_total "Registered voters"

	quiet eststo reg1: reg turnout_total treatment i.town_id
	quiet sum turnout_total if treatment==0
	eststo reg1, addscalars(mean_untreated r(mean))

	quiet eststo reg2: reg turnout_total treatment i.town_id registered_total
	quiet sum turnout_total if treatment==0
	eststo reg2, addscalars(mean_untreated r(mean))

	loc footnote "The columns present results from regressing total turnout on an intervention dummy and different sets of control variables. The coefficient on the intervention variable is an estimate of the average treatment effect. Values in parenteses are t statistics. * denotes significance at 10 pct., ** at 5 pct., and *** at 1 pct. level."
	loc prehead "\begin{table}[h]\centering \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} \caption{Average treatment effect} \label{tab:results} \maxsizebox*{\textwidth}{\textheight}{ \begin{threeparttable} \begin{tabular}{lcc} \toprule"
	loc postfoot "\bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item @note \end{tablenotes} \end{threeparttable} } \end{table}"
	
	esttab using "$output_dir/tab-results.tex", title(Average treatment effects) nomtitles label indicate(Town fixed-effects = *.town_id) stats(mean_untreated N, labels("Mean turnout untreated" "Observations")) note("`footnote'") prehead("`prehead'") postfoot("`postfoot'") replace

}


	
/////////////////////
// Produce figures //
/////////////////////


if $figureflag {

	use "$data_output_dir/stata-test", clear

	// Histograms of electoral variables
	local populations total male female
	foreach p of local populations {
		twoway (hist turnout_`p', color(blue) title("Number of `p' individuals per voting booth")) (hist registered_`p', fcolor(none) lcolor(red)), legend(order(1 "Turnout" 2 "Registered"))
		graph export "$output_dir/fig-hist-`p'.pdf", replace
	}


	// Bar graph of female voteshare
	local populations total male female
	foreach pop of local populations {
		gen voteshare_`pop' = turnout_`pop' / registered_`pop' * 100
	}
	bysort treatment: sum voteshare_female

	graph bar voteshare_female, over(treatment) ytitle("Average female vote share")
	graph export "$output_dir/fig-bars.pdf", replace

}



//////////
/* Notes /
//////////

You can write notes here.