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
amrfinderplus_report_dir <- args[2]
abricate_report_dir <- args[3]

# Read in phylogenetic tree
tree <- ggtree::read.tree(tree_path)

# Find all amrfinder reports
amrfinderplus_report_files <- dir(amrfinderplus_report_dir, pattern = "\\.tsv$", full.names = TRUE)

# Find all abricate reports
abricate_report_files <- dir(abricate_report_dir, pattern = "\\.tsv$", full.names = TRUE)

# Read in all amrfinder reports
amrfinder_reports <- lapply(amrfinderplus_report_files, function(f) {
  read_tsv(f, col_types = "ccccccccccciiddicccc")
})

# Read in all abricate reports
abricate_reports <- lapply(abricate_report_files, function(f) {
  read_tsv(f, col_types = "cciicccccddcccccc")
})

# Concatenate all amrfinder reports
amrfinder_report <- bind_rows(amrfinder_reports)

# Concatenate all abricate reports
abricate_report <- bind_rows(abricate_reports)

# Create gene matrices from amrfinder and abricate reports
amrfinder_heatmap_data <- amrfinder_report %>%
  dplyr::select(Sample, `Gene symbol`) %>%
  rename(sampleID = Sample, Gene = `Gene symbol`) %>%
  mutate(Count = 1) %>%
  group_by(sampleID, Gene) %>%
  summarise(Count = sum(Count)) %>%
  mutate(Count = case_when(Count > 0 ~ 1, .default = 0)) %>%
  pivot_wider(names_from = Gene, values_from = Count, values_fill = 0)

abricate_heatmap_data <- abricate_report %>%
  dplyr::select(SAMPLE, GENE) %>%
  rename(sampleID = SAMPLE, Gene = GENE) %>%
  mutate(Count = 1) %>%
  group_by(sampleID, Gene) %>%
  summarise(Count = sum(Count)) %>%
  mutate(Count = case_when(Count > 0 ~ 1, .default = 0)) %>%
  pivot_wider(names_from = Gene, values_from = Count, values_fill = 0)

if (ncol(amrfinder_heatmap_data) + ncol(abricate_heatmap_data) == 2) {
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

# Convert to dataframes and set the row names
amrfinder_heatmap_data <- amrfinder_heatmap_data %>%
  column_to_rownames(var = sampleID)

abricate_heatmap_data <- abricate_heatmap_data %>%
  column_to_rownames(var = sampleID)

# Match labels ----
# Find names that already match across data. These are likely the reference seqs. 
# IDing here will ensure matching labels are not manipulated. Also to prevent
# messy matches with duplicate prefixes
l <- list(tree$tip.label, row.names(amrfinder_heatmap_data), row.names(abricate_heatmap_data))
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
  add_prefix(row.names(amrfinder_heatmap_data)) %>%
  rename(name = ".") %>%
  # Omit names that do not need modifying
  dplyr::filter(!name %in% matching_names) %>%
  left_join(tree_names)

heatmap2_names <- 
  add_prefix(row.names(abricate_heatmap_data)) %>%
  rename(name = ".") %>%
  # Omit names that do not need modifying
  dplyr::filter(!name %in% matching_names) %>%
  left_join(tree_names)

# Rename files ----
# Bit messy, sorry
idx <- match(rownames(amrfinder_heatmap_data), heatmap1_names$name)
row.names(amrfinder_heatmap_data) <- ifelse(
  is.na(idx), 
  row.names(amrfinder_heatmap_data), 
  heatmap1_names$tip_name[idx]
)

idx <- match(rownames(abricate_heatmap_data), heatmap2_names$name)
row.names(abricate_heatmap_data) <- ifelse(
  is.na(idx), 
  row.names(abricate_heatmap_data), 
  heatmap2_names$tip_name[idx]
)

# Doesn't matter if either heatmap have null results. If no data in total,
# plot tree only above
combined_heatmap <- cbind(amrfinder_heatmap_data, abricate_heatmap_data)
rm(amrfinder_heatmap_data, abricate_heatmap_data, heatmap1_names, heatmap2_names, tree_names)

# Prepare separate plots ----
p_heat <- 
  combined_heatmap %>%
  rownames_to_column("Sample") %>%
  pivot_longer(-Sample, names_to = "Gene", values_to = "Presence") %>%
  ggplot(aes(Gene, Sample, fill = as.factor(Presence))) +
  geom_tile(color = "white") +
  scale_fill_manual(values = c("#D6E4F0", "#F28C8C"), breaks = c(0, 1)) +  # matrix will only ever have 0 and 1 values, always set 0 to grey blue, 1 to red
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
