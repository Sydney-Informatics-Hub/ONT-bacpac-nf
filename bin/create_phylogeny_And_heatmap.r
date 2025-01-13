#!/usr/bin/env Rscript

# Load R libraries 
library(phytools)
library(tidyverse)
library(ggtree)
library(ape)
library(aplot) # For aligning plots

Sys.setenv(FONTCONFIG_CACHE = "~/.cache/fontconfig")

# Get command-line arguments
args <- commandArgs(trailingOnly = TRUE)

tree_path <- args[1]
amrfinderplus_gene_matrix <- args[2]
abricate_gene_matrix <- args[3]

# Read in tree and heatmap files ----
tree <- ggtree::read.tree(tree_path)

heatmap_data1 <- read.table(amrfinderplus_gene_matrix, header = TRUE, sep = "\t", row.names = 1, quote = "")
heatmap_data2 <- read.table(abricate_gene_matrix, header = TRUE, sep = "\t", row.names = 1)

rm(abricate_gene_matrix, amrfinderplus_gene_matrix, tree_path)

if (ncol(heatmap_data1) + ncol(heatmap_data2) == 0) {
  # Plot only the tree if no amr data
  WIDTH = 800
  HEIGHT = 100 + length(tree$tip.label) * 30
  png("combined_plot_mqc.png", width = WIDTH, height = HEIGHT)
  ggtree(tree, size = 1) + 
    theme_tree2() +
    geom_tiplab(align = T, as_ylab = T, size = 12)
  dev.off()
  stop("No AMR genes detected, plotting phylogeny only")
}

# Match labels ----
# Find names that already match across data. These are likely the reference seqs. 
# IDing here will ensure matching labels are not manipulated. Also to prevent
# messy matches with duplicate prefixes
l <- list(tree$tip.label, row.names(heatmap_data1), row.names(heatmap_data2))
matching_names <- Reduce(intersect, l)

add_prefix <- function(names) {
  # Create a dataframe with the original sequence names and an extra column 
  # with the prefix. Prefix will be used to match names across datasets
  names %>%
    as.data.frame() %>%
    mutate(prefix = gsub("_.+", "", .))
}

# Create dataframes to replace row.names of heatmap data
tree_names <- 
  add_prefix(tree$tip.label) %>%
  rename(tip_name = ".")

heatmap1_names <- 
  add_prefix(row.names(heatmap_data1)) %>%
  rename(name = ".") %>%
  # Omit names that do not need modifying
  dplyr::filter(!name %in% matching_names) %>%
  left_join(tree_names)

heatmap2_names <- 
  add_prefix(row.names(heatmap_data2)) %>%
  rename(name = ".") %>%
  # Omit names that do not need modifying
  dplyr::filter(!name %in% matching_names) %>%
  left_join(tree_names)

# Rename files ----
# Bit messy, sorry
idx <- match(rownames(heatmap_data1), heatmap1_names$name)
row.names(heatmap_data1) <- ifelse(
  is.na(idx), 
  row.names(heatmap_data1), 
  heatmap1_names$tip_name[idx]
)

idx <- match(rownames(heatmap_data2), heatmap2_names$name)
row.names(heatmap_data2) <- ifelse(
  is.na(idx), 
  row.names(heatmap_data2), 
  heatmap2_names$tip_name[idx]
)

# Doesn't matter if either heatmap have null results. If no data in total,
# plot tree only above
combined_heatmap <- cbind(heatmap_data1, heatmap_data2)
rm(heatmap_data1, heatmap_data2, heatmap1_names, heatmap2_names, tree_names)

# Prepare separate plots ----
p_heat <- 
  combined_heatmap %>%
  rownames_to_column("Sample") %>%
  pivot_longer(-Sample, names_to = "Gene", values_to = "Presence") %>%
  ggplot(aes(Gene, Sample, fill = as.factor(Presence))) +
  geom_tile(color = "white") +
  scale_fill_manual(values = c("#D6E4F0", "#F28C8C")) +
  scale_x_discrete(position = "top") + # display gene name
  theme_void(base_size = 10) + # strip most theming, set font size
  theme(
    axis.text.x.top = element_text(angle = 55, hjust = 0, vjust = 0), # gene names positioning
    legend.position = "none"
  )

# labels should be displayed, but the theme overwrites it. Gives the align = T
# dots, but labels are in the next geom_text
p_tree <- ggtree(tree, size = 1) +
  geom_tiplab(align = T, as_ylab = T) + 
  theme_tree2() 

p_names <- tree$tip.label %>%
  as.data.frame() %>%
  ggplot(aes(x = 1, y = ., label = .)) +
  geom_text(size = 5) +
  theme_void() +
  coord_cartesian(clip = "off")

# Generate plot ----
# Set plot size dynamically
n <- ncol(combined_heatmap)
l <- length(tree$tip.label)

# used linear eq. (mx + b) to find scaling factor between nrow 17 and 87, where
# x is the number of genes
name_width <- -9/560 * n + 993/560
tree_width <- -3/560 * n + 331/560
  
# Align tree, names, and heatmap with aplot  
main <-
  p_heat %>% 
  aplot::insert_left(p_names, width = name_width) %>%
  aplot::insert_left(p_tree, width = tree_width)

# Save to file ----
WIDTH = 800 + (n * 10) # tree and names = 800px + dynamic based on genes
HEIGHT = 100 + l * 30 # dynamic padding for gene names at the top

png("combined_plot_mqc.png", width = WIDTH, height = HEIGHT)
main
dev.off()
