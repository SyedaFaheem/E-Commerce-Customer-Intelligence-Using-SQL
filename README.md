# E-Commerce-Customer-Intelligence-Using-SQL
# E-Commerce Customer Intelligence Using SQL

## Overview

An end-to-end SQL analytics project using the Brazilian E-Commerce Public Dataset by Olist. The project investigates sales performance, customer purchasing behavior, retention, delivery performance, and customer satisfaction using relational database analysis.

The project also builds customer-level analytical features that can be used in downstream machine learning experiments.

## Business Objectives

- Analyze monthly sales and revenue trends.
- Identify repeat-purchase behavior and customer retention patterns.
- Segment customers using Recency, Frequency, and Monetary value (RFM).
- Evaluate delivery performance and its relationship with customer satisfaction.
- Build validated customer-level features for machine learning.
- Improve SQL query performance and document optimization results.

## Dataset

Source: [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

The dataset contains anonymized historical e-commerce records from 2016–2018, including orders, customers, products, sellers, payments, and reviews.

## Technology Stack

- PostgreSQL
- Tableau
- Git and GitHub
- Python and Jupyter Notebook for downstream feature validation

## SQL Techniques

- Relational database design and multi-table joins
- Common Table Expressions (CTEs) and subqueries
- Aggregations and conditional logic
- Window functions, ranking, and cohort analysis
- Date calculations and customer segmentation
- Data quality validation
- Indexing and execution-plan analysis
- Customer-level feature engineering

## Project Workflow

1. Inspect the dataset and define table relationships.
2. Create staging and analytical tables.
3. Validate data types, missing values, duplicate records, and join keys.
4. Perform revenue, retention, RFM, delivery, and satisfaction analyses.
5. Build a customer-level feature dataset.
6. Validate analytical results and export selected features for Python.
7. Evaluate query performance and document optimization results.
8. Summarize findings, limitations, and potential business actions.

## Repository Structure

- `sql/`: Database setup, analysis, data quality, feature engineering, and optimization scripts.
- `docs/`: Schema documentation, data dictionary, business findings, and performance measurements.
- `outputs/`: Sample query results and screenshots.
- `python/`: Downstream feature validation and optional machine learning experiments.

## Results

Results, charts, validation checks, and performance comparisons will be documented here after the analysis has been executed and verified.

## Limitations

The dataset is historical rather than real-time. Customer segments are analytical groupings, not proof of future behavior. Any predictive modeling requires an explicitly defined target, appropriate observation windows, and safeguards against data leakage.

## Attribution

Dataset: Olist, Brazilian E-Commerce Public Dataset, available on Kaggle. Refer to the source page for license terms.

## Reproducibility

Follow the setup instructions and execute the SQL scripts in order. Configure database names and file paths for your local SQL Server environment before running the scripts.
