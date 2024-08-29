
#!/bin/bash
############### BASH SCRIPT FOR FASTER FASTQ DOWNLOAD WITH OPTIONAL GZIPING ##################
source /mnt/programs/anaconda3/etc/profile.d/conda.sh           #sourcing conda path for the subshell
conda activate smenv

lp_nbr=0    #defining varibles controlling the run of if loops controlling the background jobs number 
lp_nbr2=0
lp_nbr3=0
bkgrd_nbr=5  #defining the default number of jobs for backgrounding
        #defining the 3 functions for prefetch/conversion/gziping
    prefetch_func(){
    prefetch -O ~/sra_download/  --max-size 1t:1terabytes $i
    }
    fasterq_func(){
    fasterq-dump --outdir ~/fq_download/ -p -e 12 $i   #-p is for progress -e for thread number
    }
    gzip_func(){
    pigz -v -6 -p 10 ~/fq_download/$i*.fastq   #-6 = default compression -p defines the thread number
    }

    # reading command line arguments using getopts bash function
while getopts "p:f:gd:h" OPTION 
do
case "${OPTION}" in
h)         #help argument
    
    echo -e "\nscript usage:fq-down -p < background_job_number(default 4) > -f <sra_text_file_path> -g #for gziping -d <directory suffix>"
    
    echo -e "\nexample: bash fq-down -p 2 -f ~/SRR_list.txt -g -d SRR\n"
;;
p)       #user passed bachground job number
    bkgrd_nbr=${OPTARG}
;;
f)          #f argument passed to the command line containing the file list
    sra_list=$(< ${OPTARG})
    echo -e "\n######################  STARTING PREFETCH  ####################\n"
    for i in $sra_list
    do
        lp_nbr=$((lp_nbr+1))  #incrementing the varible with each run of for loop
        if [[ $lp_nbr -le 15 ]]  #prefetch will launch 15 jobs in the background, prefetch is limited by network speed
            then
            prefetch_func $i &
            else
                wait                      ##wait for the prefetch batch process in the background to finish
                prefetch_func $i &                   # submit the pending job
                echo -e "\n>>>>>>>>>>>>>>>>>  starting next prefetch batch <<<<<<<<<<< <<<<<<<<<\n"
                lp_nbr=0                  #resetting the varible
        fi
    done
    wait  #wait for all the child process intiated by for loop(prefetch) to end


    echo -e "\n###################    STARTING SRA TO FASTQ CONVERSION   #######################\n"
    for i in $(find ~/sra_download/*.sra -type f)   #returnsfull path of sra downloaded(in temporary sra dir)
    do
    
        lp_nbr2=$((lp_nbr2+1))
    
        if [[ $lp_nbr2 -lt $bkgrd_nbr ]]  #launch 4 jobs with12 threads(4X12=48 jobs) medium(< 20) cpu resource intensive
        then
            fasterq_func $i &
        else
            wait
            fasterq_func $i &
            echo -e "\n>>>>>>>>>>>>>>>>  starting next fasterq batch <<<<<<<<<<<< <<<<<<<<<<\n"
            lp_nbr2=0
        fi
    done
    wait #wait for the fasterq for loop to end
    echo -e "\n##########################  fastq-dump completed  #########################\n"
    #removing temp sra directory
    rm -r ~/sra_download/
    
    # renaming fastqs downloaded(removing .sra from the flename)
    
    for i in $sra_list   #make sure only the currently downloaded files are renamed
    do
        
        rename 's/.sra//' ~/fq_download/$i*{.fastq,.gz}  #make sure all fastq or gz gets renamed
    done


;;  #mandatory f argument statement ends here

g)      # gzip argument
    wait   #wait for all the background process to end before begining gzip as gzip is cpu resource intensive
        echo -e "\n############ STARTING GZIP ########################\n"
        for i in $sra_list   #make sure that only the cuurently downloaded files are gziped
        do
            
            
            lp_nbr3=$((lp_nbr3+1))
            
            if [[ $lp_nbr3 -lt $bkgrd_nbr ]]  #launch gzip with 4 jobs10threads(4X10=40) highly cpu resource intensive
            then
                gzip_func $i &
            else
                wait
                gzip_func $i &
                echo -e "\n>>>>>>>>>>>>>>>> starting next gzip batch <<<<<<<<<<<<<<\n"
                lp_nbr3=0
            fi
        done
        wait
    
        echo -e "\n############ gzip completed #####################\n"


;;  # g argument for gzinping ends here
d)   # -d directory making argument will work only for paired end files
    dir_prefix=${OPTARG}     # storing the user passed argument for generating the prefix of the directory
    cd ~/fq_download/

    dir_nbr=$(ls -l |grep "^-"|echo $(($(wc -l)/2))) # dir number decides the iteration of the move command(moving r1 and r2 to one dir)
    suffix=1
        #making directories (half the numer of files as two reads R1 and R2 goes in one dir)
    eval mkdir $dir_prefix{1..$(ls -l |grep "^-"| echo $(($(wc -l)/2)))}

    for ((i = 1 ; i <= $dir_nbr ; i++))
    do
                #move first two reads to one directory after sorting them
        mv $(sort < <(find ~/fq_download/ -maxdepth 1 -type f -name "*.fast*")|awk 'NR <= 2') -t ~/fq_download/$dir_prefix$suffix/

        suffix=$((suffix+1))
    done
    echo -e "\n######### PLEASE FIND THE fastq IN fq_download CONTAINING DIRECTORY STRUCTURE STARTING WITH $dir_prefix  #############\n"

;;  # -d argument for directory making ends here
?)
    #print option error
    echo "script usage: fq-down -p <background_job_number> -f <sra_text_file_path> -g #for gziping -d <directory suffix>" >&2
    exit 1
;;

:)
    #prints argument error
    echo "Option -$OPTARG requires an argument." >&2
        exit 1
;;
esac
done
 
shift "$(($OPTIND -1))"
