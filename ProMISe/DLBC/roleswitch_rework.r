#roleswitch rework

setwd('/home/node05/바탕화면/miRNA target performance/ProMISe/DLBC')

library(PBE)
library(ROCR)
library(preprocessCore)
library(Roleswitch)

#function for calculate raw values of ROC
draw_AUC = function(table,val,method_type,miR)
{
  #ROC and AUC calculated
  gpval = val[intersect(getGoldPositive(miR),rownames(sq_mean))]
  gnval = val[intersect(getGoldNegative(miR),rownames(sq_mean))]
  val = c(gpval, gnval)
  label = array(0, dim = length(val))
  label[1:length(gpval)]=1
  label = factor(label)
  if(method_type=='negative')
  {
    pred = prediction(predictions = 1-val, labels = label)
  }
  else if(method_type=='positive')
  {
    pred = prediction(predictions = val, labels = label)
  }
  perf1 = performance(pred, 'tpr', 'fpr')
  X_FPR = as.numeric(perf1@x.values[[1]])
  Y_TPR = as.numeric(perf1@y.values[[1]])
  perf2 = performance(pred, 'auc')
  AUC = perf2@y.values[[1]]
  
  #data extracted to global vector
  # BIG_X <<- c(BIG_X,X_FPR)
  # BIG_Y <<- c(BIG_Y,Y_TPR)
  # BIG_AUC <<- c(BIG_AUC,AUC)
  # BIG_METHODS <<- c(BIG_METHODS,rep(name,length(X_FPR)))
  roleswitch_test = list(perf1=perf1,X_FPR = X_FPR, Y_TPR = Y_TPR,perf2 = perf2,AUC=AUC)
  
}

getGoldPositive = function (miRNA) 
{
  data(mtb)
  seqtar = getBindingTarget(miRNA)
  GP1 = mtb$Target.Gene[which(mtb$miRNA == miRNA & mtb$Support.Type == "Functional MTI")]
  GP1 = intersect(seqtar, GP1)
  GP2 =mtb$Target.Gene[which(mtb$miRNA == miRNA & mtb$Support.Type == "Non-Functional MTI")]
  GP2 = intersect(seqtar, GP2)
  GP = unique(c(GP1, GP2))
  return(GP)
}

getNewGoldPositive = function(miRNA)
{
  GP = as.character(read.table(paste('/home/node05/바탕화면/miRNA target performance/ProMISe/new_Golds/',miRNA,'_GoldPositives.txt',sep = ''))[,1])
  return(GP)
}
getNewGoldNegative = function(miRNA)
{
  GN = as.character(read.table(paste('/home/node05/바탕화면/miRNA target performance/ProMISe/new_Golds/',miRNA,'_GoldNegatives.txt',sep = ''))[,1])
  return(GN)
}

mRNA_data = read.delim(file = '/home/node05/바탕화면/miRNA target performance/ProMISe/DLBC/RSEM_genes_normalized__data/RSEM_genes_normalized_data.txt',sep = '\t')
edit_table = mRNA_data[2:length(mRNA_data[,1]),]
Gene.Symbol = as.character(edit_table$Hybridization.REF)

A=strsplit(Gene.Symbol[1], split = "|", fixed = T)
A[[1]][1]
GeneSymbol=sapply(Gene.Symbol, FUN = function(x){A=strsplit(x, split = "|", fixed = T); A[[1]][1]}, simplify = T, USE.NAMES = F)
edit_table=cbind(GeneSymbol,edit_table[,2:length(edit_table[1,])])
edit_table = edit_table[!(edit_table$GeneSymbol=="?"),]
GeneSymbol = as.character(edit_table$GeneSymbol)
edit_table_1 = subset(x = edit_table, select = -1)
edit_table_2 = apply(edit_table_1, 2, as.numeric)
rownames(edit_table_2) = GeneSymbol
colnames(edit_table_2) = gsub(".","-",colnames(edit_table_2),fixed = T) #find and change
edit_table_2 = edit_table_2[, order(colnames(edit_table_2))]

miRNA_body = read.delim(file = "mature_miRNA_exp.txt",header = F)
miRNA_col = readLines("sampleID.txt")
miRNA_row = readLines("miRNAID.txt")
miRNA_body = data.matrix(miRNA_body)

rownames(miRNA_body) = miRNA_row
colnames(miRNA_body) = miRNA_col
miRNA_body = miRNA_body[, order(colnames(miRNA_body))]



a = unlist(sapply(colnames(edit_table_2), function(x) unlist(strsplit(x,split="-"))[3],simplify = T,USE.NAMES = F))
b = unlist(sapply(colnames(miRNA_body), function(x) unlist(strsplit(x,split="-"))[3],simplify = T,USE.NAMES = F))
edit_table_2 = edit_table_2[,-29]

id_convert = read.delim("miRNAid_convert.txt",header = F)
rownames(miRNA_body)

MIMAT = as.character(id_convert$V1)
miR = as.character(id_convert$V2)

MIMAT2MIR = function(x)
{
  idx = which(MIMAT == x)
  if(length(idx)==0){return(x)}
  return(miR[idx])
}

newRow = unlist(sapply(rownames(miRNA_body), function(x){MIMAT2MIR(x)}, simplify = T, USE.NAMES = F))
rownames(miRNA_body) = newRow

novel_miRs = c("155-5p", "29a-3p", "34a-5p", "125a-5p","145-5p","29b-3p","1-3p", "21-5p","29c-3p","221-3p","204-5p")
novel_miRs = paste("hsa-miR-",novel_miRs,sep = "")
novel_miR_table = miRNA_body[novel_miRs,]

Gold_Positives = c()
Gold_Negatives = c()
NG_Positives = c()
NG_Negatives = c()
for(i in novel_miRs)
{
  Gold_Positives = c(Gold_Positives,getGoldPositive(i))
  Gold_Negatives = c(Gold_Negatives,getGoldNegative(i))
  NG_Positives = c(NG_Positives,getNewGoldPositive(i))
  NG_Negatives = c(NG_Negatives,getNewGoldNegative(i))
}
Gold_Positives = unique(Gold_Positives)
Gold_Negatives = unique(Gold_Negatives)
NG_Positives = unique(NG_Positives)
NG_Negatives = unique(NG_Negatives)

PARTmiR = t(novel_miR_table)
PARTGP = t(edit_table_2[intersect(Gold_Positives,rownames(edit_table_2)),])
PARTGN = t(edit_table_2[intersect(Gold_Negatives,rownames(edit_table_2)),])
PARTNP = t(edit_table_2[intersect(NG_Positives,rownames(edit_table_2)),])
PARTNN = t(edit_table_2[intersect(NG_Negatives,rownames(edit_table_2)),])
PARTmRNA = cbind(PARTGP,PARTGN)
PARTmRNA = PARTmRNA[,unique(colnames(PARTmRNA))]
PARTmRNA_News = cbind(PARTNP,PARTNN)
PARTmRNA_News = PARTmRNA_News[,unique(colnames(PARTmRNA_News))]
#quantile normalize data
QN_miR = normalize.quantiles(t(PARTmiR)) # Sora: Must be transposed
QN_miR = t(QN_miR) # Sora: Added by Sora
colnames(QN_miR) = colnames(PARTmiR)
rownames(QN_miR) = rownames(PARTmiR)
QN_mRNA = normalize.quantiles(t(PARTmRNA)) # Sora: Must be transposed
QN_mRNA = t(QN_mRNA) # Sora: Added by Sora
colnames(QN_mRNA) = colnames(PARTmRNA)
rownames(QN_mRNA) = rownames(PARTmRNA)
QN_mRNA_News = normalize.quantiles(t(PARTmRNA_News)) # Sora: Must be transposed
QN_mRNA_News = t(QN_mRNA_News) # Sora: Added by Sora
colnames(QN_mRNA_News) = colnames(PARTmRNA_News)
rownames(QN_mRNA_News) = rownames(PARTmRNA_News)

c = matrix(0,nrow = ncol(QN_mRNA),ncol = ncol(QN_miR))
colnames(c) = colnames(QN_miR)
rownames(c) = colnames(QN_mRNA)

c_New = matrix(0,nrow = ncol(QN_mRNA_News),ncol = ncol(QN_miR))
colnames(c_New) = colnames(QN_miR)
rownames(c_New) = colnames(QN_mRNA_News)

for(mir in colnames(c))
{
  c[intersect(c(getGoldPositive(mir),getGoldNegative(mir)),rownames(c)),mir] = 1
}

for(mir in colnames(c_New))
{
  c_New[intersect(c(getNewGoldPositive(mir),getNewGoldNegative(mir)),rownames(c_New)),mir] = 1
}

#require perfect gene list to work(exact seed match table)
# site_numbers = read.table("target_number_count.txt")
# site_numbers = site_numbers[which(site_numbers[,2]%in%rownames(c)),]
# for(i in novel_miRs)
# {
#   for(j in site_numbers[,2])
#   {
#     if(length(intersect(which(site_numbers[,1]==i,arr.ind = T),which(site_numbers[,2]==j,arr.ind = T)))>0)
#     {
#       c[j,i] = site_numbers[intersect(which(site_numbers[,1]==i,arr.ind = T),which(site_numbers[,2]==j,arr.ind = T)),3]
#     }
#   }
# }

#codes worked for genmir++ relation matrix
# mirna_targets = readLines("miRNA_target_list.txt")
# mirna_list = readLines('miRNA_list.txt')
# gene_list = readLines('gene_list.txt')

# for(i in 1:nrow(c))
# {
#   miR = colnames(QN_miR)[i]
#   miridx = which(mirna_list == miR)
#   gene_idx = as.numeric(unlist(strsplit(mirna_targets[miridx], split = "\t")))
#   if(length(gene_idx)==0){next
#   }else{
#     targets = genelist[gene_idx]
#     c[i, which(colnames(c)%in%targets)] = 1
#   }
# }
# c = t(c)
rownames(c) = c(1:length(colnames(QN_mRNA)))
colnames(c) = c(1:length(colnames(QN_miR)))
rownames(c_New) = c(1:length(colnames(QN_mRNA_News)))
colnames(c_New) = c(1:length(colnames(QN_miR)))

#test seed matrix (all 1, like in mirlab)
#c = matrix(1,nrow = ncol(QN_mRNA),ncol = ncol(QN_miR))

mother_list = list()
log_mother_list = list()
new_mother_list = list()
new_log_mother_list = list()

for(i in 1:length(rownames(QN_miR)))
{
  x.o = matrix(QN_mRNA[i,],dimnames = list(c(1:length(colnames(QN_mRNA))),'mRNA'))
  z.o = matrix(QN_miR[i,],dimnames = list(c(1:length(colnames(QN_miR))),'miRNA'))
  mother_list[[substr(rownames(QN_miR)[i],1,25)]] = roleswitch(x.o,z.o,c)$p.xz
  x.o = log2(x.o+1) # Sora: Add pseudocount 1
  z.o = log2(z.o+1)
  log_mother_list[[substr(rownames(QN_miR)[i],1,25)]] = roleswitch(x.o,z.o,c)$p.xz
  
  nx.o = matrix(QN_mRNA_News[i,],dimnames = list(c(1:length(colnames(QN_mRNA_News))),'mRNA'))
  nz.o = matrix(QN_miR[i,],dimnames = list(c(1:length(colnames(QN_miR))),'miRNA'))
  new_mother_list[[substr(rownames(QN_miR)[i],1,25)]] = roleswitch(nx.o,nz.o,c_New)$p.xz
  nx.o = log2(nx.o+1) # Sora: Add pseudocount 1
  nz.o = log2(nz.o+1)
  new_log_mother_list[[substr(rownames(QN_miR)[i],1,25)]] = roleswitch(nx.o,nz.o,c_New)$p.xz
}

mother_names = names(mother_list)
log_mother_names = names(log_mother_list)
new_mother_names = names(new_mother_list)
new_log_mother_names = names(new_log_mother_list)

sq_mean = matrix(0,length(rownames(c)),length(colnames(c)))
log_sq_mean = matrix(0,length(rownames(c)),length(colnames(c)))
new_sq_mean = matrix(0,length(rownames(c_New)),length(colnames(c_New)))
new_log_sq_mean = matrix(0,length(rownames(c_New)),length(colnames(c_New)))

for(i in mother_names)
{
  sq_mean = sq_mean + log2(mother_list[[i]]+1.0e-08)
  log_sq_mean = log_sq_mean + log2(log_mother_list[[i]]+1.0e-08)
  new_sq_mean = new_sq_mean + log2(new_mother_list[[i]]+1.0e-08)
  new_log_sq_mean = new_log_sq_mean + log2(new_log_mother_list[[i]]+1.0e-08)
}
sq_mean = 2^(sq_mean/length(mother_names))
rownames(sq_mean) = colnames(QN_mRNA)
colnames(sq_mean) = colnames(QN_miR)

log_sq_mean = 2^(log_sq_mean/length(log_mother_names))
rownames(log_sq_mean) = colnames(QN_mRNA)
colnames(log_sq_mean) = colnames(QN_miR)

new_sq_mean = 2^(new_sq_mean/length(new_mother_names))
rownames(new_sq_mean) = colnames(QN_mRNA_News)
colnames(new_sq_mean) = colnames(QN_miR)

new_log_sq_mean = 2^(new_log_sq_mean/length(new_log_mother_names))
rownames(new_log_sq_mean) = colnames(QN_mRNA_News)
colnames(new_log_sq_mean) = colnames(QN_miR)


val_list = list()
log_val_list = list()
new_val_list = list()
new_log_val_list = list()

for(i in 1:11)
{
  val_list[[i]] = sq_mean[intersect(c(getGoldPositive(novel_miRs[i]),getGoldNegative(novel_miRs[i])),rownames(sq_mean)),i]
  log_val_list[[i]] = log_sq_mean[intersect(c(getGoldPositive(novel_miRs[i]),getGoldNegative(novel_miRs[i])),rownames(sq_mean)),i]
  new_val_list[[i]] = new_sq_mean[intersect(c(getNewGoldPositive(novel_miRs[i]),getNewGoldNegative(novel_miRs[i])),rownames(new_sq_mean)),i]
  new_log_val_list[[i]] = new_log_sq_mean[intersect(c(getNewGoldPositive(novel_miRs[i]),getNewGoldNegative(novel_miRs[i])),rownames(new_sq_mean)),i]
}


AUCs = c()
log_AUCs = c()
new_AUCs = c()
new_log_AUCs = c()

for(i in 1:11)
{
  A = draw_AUC(sq_mean,val_list[[i]],'positive',novel_miRs[i])
  B = draw_AUC(log_sq_mean,log_val_list[[i]],'positive',novel_miRs[i])
  C = draw_AUC(new_sq_mean,new_val_list[[i]],'positive',novel_miRs[i])
  D = draw_AUC(new_log_sq_mean,new_log_val_list[[i]],'positive',novel_miRs[i])
  
  png(paste(novel_miRs[i],'_ROC.png',sep = ''))
  plot(A$perf1)
  abline(0,1)
  AUCs = c(AUCs,A$AUC)
  title(main = paste(novel_miRs[i],' ROC',sep = ''))
  text(0.2,1,paste('AUC: ',round(A$AUC,digits = 6),sep = ''))
  dev.off()
  
  png(paste(novel_miRs[i],'_ROC_log2.png',sep = ''))
  plot(B$perf1)
  abline(0,1)
  log_AUCs = c(log_AUCs,B$AUC)
  title(main = paste('log2 ',novel_miRs[i],' ROC',sep = ''))
  text(0.2,1,paste('AUC: ',round(B$AUC,digits = 6),sep = ''))
  dev.off()
  
  png(paste(novel_miRs[i],'_ROC_New_Golds.png',sep = ''))
  plot(C$perf1)
  abline(0,1)
  new_AUCs = c(new_AUCs,C$AUC)
  title(main = paste(novel_miRs[i],' ROC (New Golds)',sep = ''))
  text(0.2,1,paste('AUC: ',round(C$AUC,digits = 6),sep = ''))
  dev.off()
  
  png(paste(novel_miRs[i],'_ROC_New_Golds_log2.png',sep = ''))
  plot(D$perf1)
  abline(0,1)
  new_log_AUCs = c(new_log_AUCs,D$AUC)
  title(main = paste('log2 ',novel_miRs[i],' ROC (New Golds)',sep = ''))
  text(0.2,1,paste('AUC: ',round(D$AUC,digits = 6),sep = ''))
  dev.off()
  
}
max(AUCs)
min(AUCs)

max(log_AUCs)
min(log_AUCs)

max(new_AUCs)
min(new_AUCs)

max(new_log_AUCs)
min(new_log_AUCs)

AUC_Grade = function(X)
{
  Y = c()
  for(i in 1:length(X))
  {
    if(X[i]>0.9){Y[i] = 'A'}
    else if(X[i]>0.8&&X[i]<=0.9){Y[i] = 'B'}
    else if(X[i]>0.7&&X[i]<=0.8){Y[i] = 'C'}
    else if(X[i]>0.6&&X[i]<=0.7){Y[i] = 'D'}
    else{Y[i] = 'F'}
  }
  return(Y)
}
AUC_Grade(AUCs)
AUC_Grade(log_AUCs)
