# Function for computation of features of time series: min, max, median, sd, etc.
# The performed computations can be optimized slightly, however, it is not that
# necessary as they need to be performed only once.
extract_features <- function(dataset_file, filtering_window = 20){
  # Some auxiliary functions and a package:
  require("moments")
  quantiles <- function(x, values = c(0.01, 0.05, seq(0.1, 0.9, 0.1), 0.95, 0.99)){
    return(quantile(x, probs=values))
  }
  energy <- function(x){
    return(sum(x^2))
  }
  deriv1 <- function(x){
    dx <- diff(x)
    return(range(dx))
  }
  robot_features <- function(x, skip = 4){
    # Function to extract four experimental features for counting peaks in ts
    # and counting the number of times a series crosses 0 and its mean.
    m_x <- mean(x)
    sd_x <- sd(x)
    over_sd <- abs(x - m_x) > sd_x
    over_2sd <- abs(x - m_x) > 2 * sd_x
    rle_enc <- rle(over_sd)
    codes <- rle_enc$values[rle_enc$length > skip] # we ignore fragments equal in length or shorter than 'skip' parameter
    rle_enc2 <- rle(over_2sd)
    codes2 <- rle_enc2$values[rle_enc2$length > skip]
    rle_enc_0 <- rle(x > 0)
    rle_enc_m <- rle(x > m_x)
    return(c("over_sd" = sum(codes), "over_2sd" = sum(codes2), "zero" = sum(rle_enc_0$length > skip) - 1, "mean" = sum(rle_enc_m$length > skip) - 1))
  }
  feat_basic <-  c("sd", "q01", "q05", "q10", "q20", "q30", "q40", "q50", "q60", "q70", "q80", "q90", "q95", "q99", 
                   "deriv1min", "deriv1max", "amplitude", "abs_max_med_ratio", "skew",  "kurt", "ener",
                   "over1sd", "over2sd", "cross0", "crossM")
  feat_fft_re_im <- c("sd", "q01", "q05", "q10", "q20", "q30", "q40", "q50", "q60", "q70", "q80", "q90", "q95", "q99", 
                      paste0("coef", 1:5))
  feat_fft_mod <- c("sd", "q01", "q05", "q10", "q20", "q30", "q40", "q50", "q60", "q70", "q80", "q90", "q95", "q99")
  feat_period <- c("sd", "q01", "q05", "q10", "q20", "q30", "q40", "q50", "q60", "q70", "q80", "q90", "q95", "q99", "max_freq")
  # The number of different features
  n_feat_basic <- length(feat_basic)
  n_feat_fft_re_im <- length(feat_fft_re_im)
  n_feat_fft_mod <- length(feat_fft_mod)
  n_feat_period <- length(feat_period)
  n_feat <- n_feat_basic + 2 * n_feat_fft_re_im + n_feat_fft_mod + n_feat_period
  n_corrs <- 42 * 41 / 2 # or `choose(42, 2)`; 42 is the number of time series
  n_vital <- 42 # number of the features describing a firefighter's vital functions
  # Marix to store ts for computation of correlations
  all_series <- matrix(NA, ncol = 42, nrow = 401 - filtering_window)
  corrs_features_start <- n_feat * 42 + 1
  features <- matrix(NA, ncol=n_feat * 42 + n_corrs + n_vital, nrow = 2e4) 
  # Creating column names
  columns <- readLines(file.path("..", "data", "columns.txt")) # first one is timestamp
  feature_names <- paste(c(paste(feat_basic),  
                           paste("ReFFT", feat_fft_re_im, sep="."), 
                           paste("ImFFT", feat_fft_re_im, sep="."),
                           paste("ModFFT", feat_fft_mod, sep="."),
                           paste("Period", feat_period, sep=".")), rep(columns[44:length(columns)], each = n_feat), sep=".")
  feature_names <- c(feature_names, rep("", n_corrs), columns[1:42])
  colnames(features) <- feature_names
  l <- corrs_features_start
  for(i in 1:41){ # for every pair of series
    for(j in (i + 1):42){
      colnames(features)[l] <- paste("cor", columns[43 + i], columns[43 + j], sep = ".")
      l <- l + 1
    }
  }
  # Moving average filtering
  filter_coeff <- rep(1/filtering_window, filtering_window)
  keep_indexes <- floor((filtering_window + 1) / 2):(400 - floor(filtering_window / 2)) # to skip NA in front and at the end of time series
  # Main loop for feature extraction
  dataset <- file(file.path("..", "data", dataset_file), open="r"); on.exit(close(dataset))
  i <- 1
  while(length(x <- readLines(dataset, n = 1)) > 0){ # reads consecutive instances
    if(i %% 1000 == 0) print(i) # To track the progress
    x <- as.numeric(strsplit(x, ",")[[1]])
    for(j in 2:43){ # for every series in the event; skip the first one (timestamp)
      # Time series smoothing
      y <- x[42 + j + 43 * 0:399]
      y <- filter(y, filter = filter_coeff)[keep_indexes]
      fill <-  n_feat * (j - 2) + 1:n_feat # column index for features for the given time series
      # Basic features on raw data
      z <- c(sd(y), quantiles(y), deriv1(y), NA, NA, skewness(y), kurtosis(y), energy(y), robot_features(y))
      features[i, fill[1:n_feat_basic]] <- z
      features[i, fill[17]] <- z["99%"] - z["1%"] # amplitude
      features[i, fill[18]] <- max(abs(z[c("1%", "99%")]))/max(abs(z["50%"]), 1e-6) # 
      # Fourier transform features
      z <- fft(y)[-1] # Skip the first FFT coefficient == sum(y)
      mod_z <- Mod(z)
      re_z <- Re(z)
      im_z <- Im(z)
      features[i, fill[n_feat_basic + 1:n_feat_fft_re_im]] <- c(sd(re_z), quantiles(re_z), re_z[1:5])
      features[i, fill[n_feat_basic + n_feat_fft_re_im + 1:n_feat_fft_re_im]] <- c(sd(im_z), quantiles(im_z), im_z[1:5])
      features[i, fill[n_feat_basic + 2 * n_feat_fft_re_im + 1:n_feat_fft_mod]] <- c(sd(mod_z), quantiles(mod_z))
      # Periodogram features
      prdg <- spec.pgram(y, plot = FALSE)
      features[i, fill[n_feat_basic + 2 * n_feat_fft_re_im + n_feat_fft_mod + 1:n_feat_period]] <- c(sd(prdg$spec), quantiles(prdg$spec), prdg$freq[which.max(prdg$spec)])
      # Record series for correlation computations in a matrix
      all_series[, j - 1] <- y
    }
    l <- corrs_features_start
    for(j in 1:41){ # for every pair of serieses  
      for(k in (j + 1):42){
        features[i, l] <- cor(all_series[, j], all_series[, k])
        l <- l + 1
      }
    }
    features[i, l:ncol(features)] <- x[1:42]
    if(any(is.na(features[i, ]))){
      features[i, ][is.na(features[i, ])] <- 0
      # Some of the features values cannot be dertermined, e.g. skewness and kurthosis
      # for series 'acc_left_arm_x' for 5th row in test set or their correlation coefficients.
      # This is because there are some series that are constant.
    }
    i <- i + 1
  }
  dataset_file_processed <- paste0(substr(dataset_file, 1, nchar(dataset_file) - 4), "Features.csv")
  write.csv(features, file.path("..", "data", dataset_file_processed), row.names = FALSE, quote = FALSE)
  return(invisible(features))
}

# This takes about 2h per dataset, 4h in total
extract_features("trainingData.csv")
extract_features("testData.csv")
