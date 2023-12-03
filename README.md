# R-DCM Retail Stores Traffic Analysis

This R script analyzes traffic data for Michaels stores and compares it with competitor stores (AC Moore, Hobby Lobby, JoAnn Fabrics) to derive insights into market share and proximity.

## Table of Contents
- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Code Structure](#code-structure)
- [License](#license)

## Introduction

This script is designed to perform traffic analysis for Michaels stores and their competitors. It leverages traffic data, sales data, and store information to calculate market share and analyze the proximity of Michaels stores to competitor stores.

## Prerequisites

Make sure you have R and RStudio installed on your system. Additionally, ensure that the required R packages are installed. You can install them by running the following command in R:

```R
install.packages(c("dplyr", "geosphere"))
```

## Installation

1. Clone the repository or download the provided R script.

```bash
git clone https://github.com/your-username/your-repository.git
```

2. Open the R script (`main_script.R`) in RStudio or any R-compatible environment.

3. Update the file paths in the script to point to your specific input files.

## Usage

Run the `main` function in the script to execute the entire workflow. The script will load necessary data, perform analysis, and print the results.

```R
source("main_script.R")
main()
```

## Code Structure

The code is organized into several functions for modularity and readability. Here is an overview of the functions:

- `load_store_lists`: Load Michaels and competitor store lists.
- `load_traffic_data`: Load traffic data, sales data, and competitor sales data.
- `merge_traffic_store_info`: Merge traffic data with Michaels store information.
- `merge_comp_store_traffic`: Merge competitor store data with traffic data.
- `calculate_distances`: Calculate distances between Michaels stores and competitor stores.
- `calculate_traffic_market_share`: Calculate traffic market share.
- `main`: Main function to run the entire analysis.

Feel free to explore each function for more details on its functionality.

## License

This project is licensed under the [MIT License](LICENSE).
```

Make sure to include a `LICENSE` file if applicable and replace placeholder information with actual details related to your project.
