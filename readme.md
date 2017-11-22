# Stata-LaTeX integration

Hi. The idea of this directory is to serve as a starting point for you to use Stata ouput in LaTeX documents. You should be able to use this directory as the basis for your own project and adjust it as you see fit by adding more directories and filling the files with your own content.


## Key files

**code.do** (located in /analysis/code) runs all the analysis. The only thing you need to do is to change the path to the analysis directory. The code then reads in the raw data from data/input, cleans it, and produces a table and a couple figures, which it saves into /output. It also saves the cleaned dataset into /data/output. 

**text.do** (located in /text) is where you write up your results. The file automatically imports the table and figures from /output and retrieves citations from bibliography.bib.


## Contact

This tutorial is very much work in progress. Please [let me know](fa.gunzi@gmail.com "fa.gunzi@gmail.com") is something is unclear or doesn't work. 
