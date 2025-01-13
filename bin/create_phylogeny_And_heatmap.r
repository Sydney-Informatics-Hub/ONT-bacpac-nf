#!/usr/bin/env Rscript

# Load R libraries 
library(phytools)
library(tidyverse)
library(ggtree)
library(ape)
library(conflicted)

Sys.setenv(FONTCONFIG_CACHE = "~/.cache/fontconfig")

# Get command-line arguments
args <- commandArgs(trailingOnly = TRUE)

phylogeny_tree_base_path <- args[1]
amrfinderplus_gene_matrix <- args[2]
abricate_gene_matrix <- args[3]


# Open a PNG graphics device
png(filename = "combined_plot_mqc.png", width = 2000, height = 800)


## Read Phylogeny tree
relative_path_to_tree <- "Results_tree/Species_Tree/SpeciesTree_rooted.txt"
## Contruct full path to tree
full_path <- file.path(phylogeny_tree_base_path, relative_path_to_tree)

#tree <- read.tree("results/phylogeny/output/Results_tree/Species_Tree/SpeciesTree_rooted.txt")
tree <- read.tree(full_path)

## Heatmap for AMR genes
# Read first heatmap data 
heatmap_data1 <- read.table(amrfinderplus_gene_matrix, header = TRUE, sep = "\t", row.names = 1, quote = "")

# Read second heatmap data
heatmap_data2 <- read.table(abricate_gene_matrix, header = TRUE, sep = "\t", row.names = 1)

# Format ids
format_row_names <- function(data) {
  rownames(data) <- gsub("\\s+", "_", rownames(data))
  rownames(data) <- gsub(",", "_", rownames(data))
  rownames(data) <- gsub("\\(", "", rownames(data))
  rownames(data) <- gsub("\\)", "", rownames(data))
  rownames(data) <- trimws(rownames(data), which = "right", whitespace = "_")
  return(data)
}

# Format row names for both heatmaps
heatmap_data1 <- format_row_names(heatmap_data1)
heatmap_data2 <- format_row_names(heatmap_data2)

# Reorder both heatmaps according to the tree's tip labels
heatmap_data1 <- heatmap_data1[tree$tip.label, ]
heatmap_data2 <- heatmap_data2[tree$tip.label, ]

# Check if the heatmap data frames have any columns
has_data1 <- ncol(heatmap_data1) > 0
has_data2 <- ncol(heatmap_data2) > 0

if (has_data1 && has_data2) {
  # Merge the two heatmap data frames by row names
  heatmap_data <- cbind(heatmap_data1, NA, heatmap_data2)
  colnames(heatmap_data)[ncol(heatmap_data1) + 1] <- "Separator"
} else if (has_data1) {
  heatmap_data <- heatmap_data1
} else if (has_data2) {
  heatmap_data <- heatmap_data2
} else {
  # Plot only the tree with labels
  plotTree(tree, plot=FALSE)
  obj <- get("last_plot.phylo", envir=.PlotPhyloEnv)
  plotTree(tree, lwd=1, ylim=c(0, obj$y.lim[2]*1.05), xlim=c(0, obj$x.lim[2]*1.1), ftype="off")
  
  # Retrieve the plotting details
  obj <- get("last_plot.phylo", envir=.PlotPhyloEnv)
  h <- max(obj$xx)
  fsize <- 0.8
  
  # Add tip labels to the right of the tree without any gap
  for (i in 1:Ntip(tree)) {
    text(h, obj$yy[i], tree$tip.label[i], cex = fsize, pos = 4, font = 3, offset = 0)
  }
  
  # Close the graphics device
  dev.off()
  stop("Both heatmap data files contain no gene columns. Plotting only the phylogeny tree with labels.")
}

## Generate a combined Plot

# Reorder the tree and heatmap data (already reordered above)

# Plot the tree without tip labels
plotTree(tree, plot=FALSE)
obj <- get("last_plot.phylo", envir=.PlotPhyloEnv)
#plotTree(tree, lwd=1, ylim=c(0, obj$y.lim[2]*1.05), xlim=c(0, obj$x.lim[2]*1.2), ftype="off")
xlim_adjusted <- max(obj$x.lim) * 2.5  # Increase xlim to ensure space for heatmap
ylim_adjusted <- max(obj$y.lim) * 1.3  # Increase ylim to ensure space for column labels

plotTree(tree, lwd=1, ylim=c(0, ylim_adjusted), xlim=c(0, xlim_adjusted), ftype="off")


# Retrieve the plotting details
obj <- get("last_plot.phylo", envir=.PlotPhyloEnv)
h <- max(obj$xx)
fsize <- 0.8

# Calculate the start position for the heatmap closer to the tree
s <- max(fsize * strwidth(tree$tip.label))
gap <- 0.1 * s  # Define a small gap between the tree and the heatmap
start.x <- h + gap  # Reduced space between tree and heatmap
cols <- setNames(c("red", "blue", "white"), c(0, 1, NA))  # Red for 0, Blue for 1, White for NA

# Calculate aspect ratio
asp <- (par()$usr[2] - par()$usr[1]) / (par()$usr[4] - par()$usr[3]) * par()$pin[2] / par()$pin[1]

# Draw the heatmap next to the tree
for (i in 1:ncol(heatmap_data)) {
  if (!(has_data1 && has_data2) || i != (ncol(heatmap_data1) + 1)) {  # Skip label for separator column if both heatmaps present
    text(start.x + (i - 1) * asp, max(obj$yy) + 1, colnames(heatmap_data)[i], pos = 4, srt = 45, cex = 0.9, offset = 0)
  }
  for (j in 1:nrow(heatmap_data)) {
    xy <- c(start.x + (i - 1) * asp, obj$yy[j])
    y <- c(xy[2] - 0.5, xy[2] + 0.5, xy[2] + 0.5, xy[2] - 0.5)
    x <- c(xy[1] - 0.5 * asp, xy[1] - 0.5 * asp, xy[1] + 0.5 * asp, xy[1] + 0.5 * asp)
    
    # Adjusted endpoint for the dotted lines
    if (i == 1) {
      line_end_x <- start.x - 0.5 * asp
      # Remove the dotted lines and adjust the x-coordinates to avoid gap
      lines(c(obj$xx[j], line_end_x), rep(obj$yy[j], 2), lty = "solid", col = "gray")
    }
    
    # Check for NA and set color accordingly
    if (is.na(heatmap_data[j, i])) {
      polygon(x, y, col = "white", border = "white")
    } else {
      polygon(x, y, col = cols[as.character(heatmap_data[j, i])], border = "white")
    }
  }
}

# Add tip labels to the right of the heatmap
label_start_x <- start.x + ncol(heatmap_data) * asp
for (i in 1:Ntip(tree)) {
  text(label_start_x, obj$yy[i], tree$tip.label[i], cex = fsize, pos = 4, font = 3, offset = 0)
}

# Add labels for heatmap sections if both heatmaps are present
if (has_data1 && has_data2) {
  section_label_y <- -1  # Position below the heatmap
  text(start.x + (ncol(heatmap_data1) - 1) * asp / 2, section_label_y, "AMR-genes", cex = 1.2, col = "black")
  text(start.x + (ncol(heatmap_data1) + 1 + (ncol(heatmap_data2) - 1) * asp / 2), section_label_y, "Virulence-genes", cex = 1.2, col = "black")
  
  # Add colored bars for heatmap sections
  rect(start.x - asp / 2, section_label_y - 0.5, start.x + (ncol(heatmap_data1) - 1) * asp + asp / 2, section_label_y - 0.1, col = "lightblue", border = NA)
  rect(start.x + (ncol(heatmap_data1) + 1) * asp - asp / 2, section_label_y - 0.5, start.x + (ncol(heatmap_data1) + 1 + (ncol(heatmap_data2) - 1) * asp) + asp / 2, section_label_y - 0.1, col = "lightgreen", border = NA)
}

# Close the graphics device
dev.off()
