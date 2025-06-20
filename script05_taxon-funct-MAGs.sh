#! /bin/bash

# -------------------------------------------------------------------------------------------- #
# PHYLOGENOMIC INFERENCE AND FUNCTIONAL ANNOTATION OF MAGs FROM ANTARCTIC SPONGES AND SEAWATER #
# -------------------------------------------------------------------------------------------- #

# NOTES:
## MSA: Multiple Sequence Alignment
## Input file "list-bins.txt" contains a list of the file names corresponding to all MAGs.
## GTDB-Tk output files "gtdbtk.bac120.user_msa_*.fasta" and "gtdbtk.ar53.user_msa_sw.fasta" were used to make MSA in the IQ-TREE web server and further plot phylogenomic trees of "Figure 3" in the iTOL web tool.
## GTDB-Tk output files "gtdbtk.bac120_*.summary.tsv" and "gtdbtk.ar53_sponge.summary.tsv" were adapted with the MAGs metadata file "metadata-bins.tsv" to add annotations and datasets to the phylogenomic trees of "Figure 3" made in iTOL.
## nohup command was used for each new execution, making a backup of each resulting "nohup.out" file to avoid overwriting. Execution: $ nohup ./{script} &


#--- Gene prediction of MAGs using Prodigal:

for file in *.fa
do
        prodigal -i ${file} -o ${file}_cds.gbk -a ${file}_prot.faa
done

# Modify the resulting file names:
rename 's/.fa_prot/_prot/g' *.faa
rename 's/.fa_cds/_cds/g' *


#--- Functional annotation of MAGs using eggNOG database and eggNOG-mapper:

for file in *_prot.faa
do
	python ../eggnog-mapper-2.1.11/emapper.py -i ${file} -m diamond -o ${file}_func --go_evidence all --cpu 38 --output_dir ./func_out
done


#--- Assessing the gene number of selected functional groups: 

# Cold adaptation functions:
echo -e "ID\tfunction\tcount" > table-adapt-count-MAGs.txt
while IFS= read -r line
do
	paste -d "\t" <(echo -e "$line\tCold shock proteins\t$(grep -v "^#" $line\_func.annotations | grep -v -i "eukaryota" | grep -i "cold" | cut -f2 | sort | uniq -c | awk '{sum+=$1} END {print sum}' )") >> table-adapt-count-MAGs.txt
	paste -d "\t" <(echo -e "$line\tChaperones\t$(grep -v "^#" $line\_func.annotations| grep -E -v -i "eukaryota|ABC transporter|MsrPQ|MeaI" | grep -i "chaperone" | cut -f8 | sort | uniq -c | awk '{sum+=$1} END {print sum}' )") >> table-adapt-count-MAGs.txt
	paste -d "\t" <(echo -e "$line\tOsmoprotectant-related proteins\t$(grep -v "^#" $line\_func.annotations | grep -v -i "eukaryota" | grep -i "osmoprotectant" | cut -f9 | sort | uniq -c | awk '{sum+=$1} END {print sum}' )") >> table-adapt-count-MAGs.txt
	paste -d "\t" <(echo -e "$line\tAntioxidants\t$(grep -v "^#" $line\_func.annotations | grep -v -i "eukaryota" | grep -i "antioxidant" | cut -f9 | sort | uniq -c | awk '{sum+=$1} END {print sum}' )") >> table-adapt-count-MAGs.txt
	paste -d "\t" <(echo -e "$line\tAntifreeze proteins\t$(grep -v "^#" $line\_func.annotations | grep -v -i "eukaryota" | grep -i "antifreeze" | cut -f8 | sort | uniq -c | awk '{sum+=$1} END {print sum}' )") >> table-adapt-count-MAGs.txt
	paste -d "\t" <(echo -e "$line\tFatty acid desaturases\t$(grep -v "^#" $line\_func.annotations | grep -v -i "eukaryota" | grep -E -i "acid desaturase|Phytoene desaturase|acyl-CoA desaturase|Sphingolipid Delta4-desaturase|squalene-associated FAD-dependent desaturase" | cut -f8 | sort | uniq -c | awk '{sum+=$1} END {print sum}' )") >> table-adapt-count-MAGs.txt
	paste -d "\t" <(echo -e "$line\tHeat shock proteins\t$(grep -v "^#" $line\_func.annotations | grep -E -v -i "eukaryota|chaperone|S1P" | grep -E -i "heat shock" | cut -f8 | sort | uniq -c | awk '{sum+=$1} END {print sum}' )") >> table-adapt-count-MAGs.txt
	paste -d "\t" <(echo -e "$line\tNucleotide repair proteins\t$(grep -v "^#" $line\_func.annotations | grep -v -i "eukaryota" | grep -E -i "DNA repair|RNA repair|repair protein|repair response|repair endonuclease|repair exonuclease|mismatch repair|photorepair protein|base-excision repair|DNA alkylation repair|damage repair|double-strand break repair|repair of stalled replication forks|repairing DNA|DNA damage lesion repair|base excision repair|double-strand break (DSB) repair|repair of damaged DNA|DNA-repair|UvrABC repair|repair of mismatches in DNA|DNA damage recognition|patch repair" | cut -f8 | sort | uniq -c | awk '{sum+=$1} END {print sum}' )") >> table-adapt-count-MAGs.txt
done < list_bins.txt

# Metabilic functions:
grep -v "^#" *_func.annotations | grep -v -i "eukaryota" | cut -f7 | grep "I" | sort | uniq > list-lipid-cogs.txt
grep -v "^#" *_func.annotations | grep -v -i "eukaryota" | cut -f7 | grep "C" | sort | uniq > list-energ-cogs.txt
grep -v "^#" *_func.annotations | grep -v -i "eukaryota" | cut -f7 | grep "E" | sort | uniq > list-amino-cogs.txt
grep -v "^#" *_func.annotations | grep -v -i "eukaryota" | cut -f7 | grep "G" | sort | uniq > list-carbo-cogs.txt

for categ in lipid energ amino carbo
do
	echo -e "\t$categ"
	for file in *_func.annotations
	do
		a=$( grep -v "^#" $file | grep -v -i "eukaryota" | cut -f 1,2,7 | grep -wf list-$categ-cogs.txt | wc -l ) #>> $file.$categ
		echo -e "$file\t$a" | sed "s/_func.annotations//g"
	done
done

# Resistance functions:
echo -e "\tresis"
for file in *_func.annotations
do
	a=$( grep -Evi "^#|eukaryota" $file | grep -iE "resistance|antibiotic|drug|antimicrobial|heavy metal|heavy-metal" | grep -Ev "bacteriophage resistance|PhoQ|Antitoxin|nucleosome-like|oxidative stress|low-pH|cold resistance|resistance to hypoosmotic shock|stress resistance|macrophage|phage-resistance|extreme acid resistance|Toll-Interleukin 1-resistance|Serum resistance|TraT complement|Ultraviolet light resistance|Ultra-violet resistance" | cut -f8 | wc -l)
	echo -e "$file\t$a" | sed "s/_func.annotations//g"
done

# Conjugation functions:
echo -e "\tices"
for file in *.annotations
do
	b=$( grep -Evi "^#|eukaryota|CRISPR|phage" $file | grep -iE "integrase|relaxase|relaxosome|conjugative|Type IV secretion|Type-IV|Type IV secretory|T4SS|tyrosine recombinase|ice cds17|TrbI-like|TrbI family|TraG family|unidirectional conjugation|Tra gene|TraG-like|TraB family|TraC-like" | cut -f8 | wc -l )
	echo -e "$file\t$b" | sed "s/_func.annotations//g"
done


#--- Counting genes from MAGs:

# Count total genes annotated:
grep -viEc "^#|eukaryota" *_func.annotations | sed "s/_func.annotations:/\t/g"


#--- Taxonomy classification of MAGs using GTDB-Tk:

# For MAGs from Antarctic sponges (MSA includes MAGs with ANI reference and those inferred from LCA):
gtdbtk classify_wf --genome_dir ./input_bins_sponge --out_dir ./output_gtdb_nomash_sponge --skip_ani_screen --cpus 35 --pplacer_cpus 35 --extension fa 

# For MAGs from Antarctic seawater (MSA includes MAGs with ANI reference and those inferred from LCA):
gtdbtk classify_wf --genome_dir ./input_bins_sw --out_dir ./output_gtdb_nomash_sw --skip_ani_screen --cpus 35 --pplacer_cpus 35 --extension fa 

# For MAGs from Antarctic sponges (MSA includes only MAGs inferred from LCA)
gtdbtk classify_wf --genome_dir ./input_bins_sponge --out_dir ./output_gtdb_sponge --mash_db /home/laboratorio/anaconda3/envs/gtdb-env/share/gtdbtk-2.3.2/db/mash/my_mash.msh --cpus 35 --pplacer_cpus 35 --extension fa 

# For MAGs from Antarctic seawater (MSA includes only MAGs inferred from LCA)
gtdbtk classify_wf --genome_dir ./input_bins_sw --out_dir ./output_gtdb_sw --mash_db /home/laboratorio/anaconda3/envs/gtdb-env/share/gtdbtk-2.3.2/db/mash/my_mash.msh --cpus 35 --pplacer_cpus 35 --extension fa


