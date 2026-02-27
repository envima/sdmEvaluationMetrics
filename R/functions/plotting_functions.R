#' @name plotting_functions.R
#' @description Creates a standardized ggplot2 boxplot for Absolute Error metrics,
#' including bold median labels and specific outlier styling.
#' 
#' @param data Dataframe containing the metrics and grouping variables.
#' @param y_var String. The name of the AE column to plot.
#' @param plot_labels Dataframe. Must contain 'metric' and 'label' columns for titles.
#' @param facet_var String (optional). Column name to facet the plots by.
#' 
#' @return A ggplot object.

create_ae_boxplot <- function(data, y_var, facet_var = NULL) {
  # Get the math-formatted label for the title
  title_text <- plot_labels$label[plot_labels$metric == y_var]
  
  p <- ggplot(data, aes(x = method, y = .data[[y_var]], fill = method)) +
    # 1. Boxplot with your specific outlier settings
    geom_boxplot(outlier.size = 1.7, 
                 outlier.shape = 1, 
                 outlier.color = "darkgrey",
                 color = "black") + 
    
    # 2. Re-adding your median text labels
    stat_summary(fun = median, 
                 geom = "text", 
                 aes(label = round(after_stat(y), 2)), 
                 vjust = -0.5, 
                 color = "black", 
                 fontface = "bold",
                 size = 3.5) + # Size adjusted for faceted plots
    
    # 3. Colors and Labels
    scale_fill_manual(values = c("PA" = "#4285f4", 
                                 "PBG" = "#cb6ce6", 
                                 "PAA" = "#aad93a")) +
    labs(title = parse(text = title_text),
         y = "Absolute Error",
         x = "") +
    
    # 4. Theme settings
    theme_minimal() +
    theme(legend.position = "none",
          text = element_text(size = 13),
          plot.title = element_text(hjust = 0.5, size = 13),
          panel.grid.major.x = element_blank()) # Optional: cleans up the x-axis
  
  # Add faceting if requested (class or points)
  if (!is.null(facet_var)) {
    p <- p + facet_wrap(vars(.data[[facet_var]]))
  }
  
  return(p)
}


#' Scatterplot für Metrik vs. True Correlation
#' @description Erstellt Scatterplots mit 1:1 Linie und MAE-Annotation.
create_scatter_plot <- function(data, m_scaled, method_name, labels_df) {
  
  # MAE berechnen
  mae_val <- median(abs(data[[m_scaled]] - data$trueCor_scaled), na.rm = TRUE)
  
  # Label für die x-Achse holen
  x_label <- labels_df$label[labels_df$metric_names == paste0("AE_",m_scaled)]
  
  p <- ggplot(data, aes(x = .data[[m_scaled]], y = trueCor_scaled)) +
    # Punkte (shape="." für große Datenmengen)
    geom_point(shape = ".", colour = "cornflowerblue") +
    # 1:1 Linie (Idealfall)
    geom_abline(slope = 1, intercept = 0, color = "deeppink3", 
                linetype = "dashed", linewidth = 1) +
    facet_wrap(vars(method)) +
    # MAE Box/Text
    annotate("rect", xmin = 0.01, xmax = 0.45, ymin = 0.88, ymax = 0.99, 
             fill = "white", alpha = 0.8) +
    annotate("text", x = 0.05, y = 0.94, label = paste0("MAE = ", round(mae_val, 2)), 
             size = 5, hjust = 0) +
    xlim(0, 1) + ylim(-0.01, 1) +
    xlab(parse(text = x_label)) +
    ylab("") +
    theme_minimal(base_size = 20) +
    theme(legend.position = "none",
          plot.margin = margin(5, 5, 5, 5))
  
  return(p)
}

#' Plot Tolerance Intervals and Density
#' @description Visualizes the density of Absolute Error and the 95% tolerance limit.
create_tolerance_plot <- function(data, ae_var, labels_df) {
  library(tolerance)
  
  # 1. Calculate the tolerance limits per method
  # We use the non-parametric nptol.int for a 1-sided upper bound
  tol_table <- data %>%
    group_by(method) %>%
    summarise(
      Upper_Limit = as.numeric(nptol.int(.data[[ae_var]], 
                                         alpha = 0.05, P = 0.95, 
                                         side = 1)$`1-sided.upper`),
      .groups = "drop"
    ) %>%
    mutate(staggered_y = seq(2, 5, length.out = n())) # Dynamic heights for labels
  
  # 2. Extract Title
  metric_key <- gsub("AE_", "", ae_var)
  title_text <- labels_df$label[labels_df$metric_names == metric_key]
  
  # 3. Create Plot
  p <- ggplot(data, aes(x = .data[[ae_var]], after_stat(density), fill = method)) +
    geom_density(alpha = 0.5) +
    # Vertical lines for upper limits
    geom_vline(data = tol_table, aes(xintercept = Upper_Limit, color = method), 
               linetype = "dashed", linewidth = 0.8) +
    # Text labels for the limit values
    geom_text(data = tol_table, 
              aes(x = Upper_Limit, 
                  y = staggered_y, 
                  label = round(Upper_Limit, 2), 
                  color = method), 
              hjust = 1.5, 
              #angle = 90, 
              show.legend = FALSE, 
              nudge_x = 0.02) +
    scale_fill_manual(values = c("PA" = "#4285f4", "PBG" = "#cb6ce6", "PAA" = "#aad93a")) +
    scale_color_manual(values = c("PA" = "#4285f4", "PBG" = "#cb6ce6", "PAA" = "#aad93a")) +
    labs(title = parse(text = title_text),
         x = "Absolute Error",
         y = "Density") +
    theme_minimal() +
    theme(plot.title = element_text(hjust = 0.5)
          #legend.position = "bottom"
          )
  
  return(p)
}
