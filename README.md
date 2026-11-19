# E-Commerce-Customer-Intelligence-Using-SQL

## Project Overview

An end to end e commerce analytics project using the Brazilian E Commerce Public Dataset by Olist. This project uses PostgreSQL, SQL, Tableau, and Python to investigate sales performance, customer purchasing behavior, repeat purchases, delivery performance, and customer satisfaction.

The project also includes customer feature engineering and Python based data validation to prepare a structured dataset for future machine learning experiments.

## Business Objectives

1. Analyze sales performance, revenue trends, and product category performance.
2. Understand customer purchasing behavior and repeat purchase patterns.
3. Evaluate customer retention and purchasing activity.
4. Investigate delivery performance and customer satisfaction.
5. Develop customer level analytical features using SQL.
6. Validate analytical results and financial metrics using Python and Pandas.

## Dataset

**Source:** [Brazilian E Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

The dataset contains anonymized historical e commerce transactions from 2016 to 2018. It includes information about customers, orders, products, sellers, payments, and reviews.

The original dataset is not included in this repository. Refer to the Kaggle source for dataset access and licensing information.

## Technology Stack

| Technology | Purpose |
|---|---|
| PostgreSQL | Relational database and analytical queries |
| SQL | Data cleaning, analysis, aggregations, and feature engineering |
| Tableau | Interactive dashboards and business reporting |
| Python | Data validation and analysis |
| Pandas | Feature validation and reconciliation |
| Jupyter Notebook | Documented Python workflow |
| Git and GitHub | Version control and project documentation |

## Project Workflow

### 1. Database and Data Preparation

Organized the Olist dataset into relational tables and developed analytical views using PostgreSQL.

Performed data quality checks, examined relationships between tables, and validated analytical calculations.

### 2. SQL Business Analysis

Developed SQL analyses covering:

1. Revenue and sales performance.
2. Customer purchasing activity and repeat purchases.
3. Customer retention metrics.
4. Delivery performance and customer satisfaction.
5. Customer level feature engineering.

### 3. Tableau Dashboards
[View My Tableau Public Portfolio](https://public.tableau.com/app/profile/faheemunnisa.syeda7/vizzes)


Developed three dashboards to explore different areas of e commerce performance.

**Dashboard 1: Sales Performance**

Examines revenue trends, orders, and product category performance.

**Dashboard 2: Customer Intelligence**

Explores customer purchasing activity, repeat purchases, and customer behavior.

**Dashboard 3: Delivery and Customer Experience**

Examines delivery performance, delivery outcomes, and customer satisfaction.

### 4. Customer Feature Engineering

Created the PostgreSQL analytical view:

`analytics.vw_customer_ml_features`

The view contains one row per unique customer and 20 analytical columns covering:

1. Customer identification and geography.
2. Order activity and purchasing history.
3. Delivered product revenue and freight.
4. Purchase recency.
5. Delivery duration and review scores.
6. Repeat customer classification.

Exported the resulting dataset to:

`outputs/customer_ml_features.csv`

### 5. Python Data Validation

Used Python and Pandas to validate the exported customer feature dataset against PostgreSQL results.

Validation included duplicate checks, missing value investigation, date consistency, business rules, and financial reconciliation.

**Validation results**

| Metric | Result |
|---|---:|
| Unique customers | 96,096 |
| Total orders | 99,441 |
| Delivered orders | 96,478 |
| Delivered product revenue | R$13,221,498.11 |
| Delivered freight | R$2,198,275.64 |
| Repeat customers | 2,997 |
| Validation checks passed | 14 of 14 |

All 14 final validation checks passed. PostgreSQL and Python financial and order totals reconciled.

## Repository Structure

```text
E-Commerce-Customer-Intelligence-Using-SQL/
│
├── sql/
│   ├── 04_revenue_analysis.sql
│   ├── 05_customer_retention.sql
│   ├── 07_delivery_satisfaction.sql
│   └── 08_ml_feature_engineering.sql
│
├── docs/
│   └── feature_dictionary.md
│
├── outputs/
│   └── customer_ml_features.csv
│
├── python/
│   └── feature_validation.ipynb
│
├── dashboard/
│   └── Tableau dashboard files and screenshots
│
└── README.md
```

The structure above highlights the confirmed analytical deliverables. Add other SQL scripts and dashboard files as they are finalized.

## Data Limitations

1. The dataset contains historical transactions from 2016 to 2018, not real time customer activity.
2. Average delivered order value is missing for 2,738 customers because they have no delivered orders.
3. Average review score is missing for 716 customers because they have no reviewed orders.
4. Average delivery duration is missing for 2,746 customers. Eight customers with delivered orders have missing delivery timestamps.
5. Customer recency uses a fixed reference date of October 18, 2018.

Missing values were retained as null rather than replaced with zero or estimated values.

## Future Improvements

1. Complete and document RFM customer segmentation.
2. Evaluate SQL query performance using execution plans and measured comparisons.
3. Define a prediction target and observation window for machine learning.
4. Address potential data leakage before predictive modeling.
5. Expand business findings with evidence from the completed dashboards.

## Reproducibility

To reproduce the project:

1. Download the Brazilian E Commerce Public Dataset from the Kaggle source.
2. Install PostgreSQL and create the project database.
3. Import the source CSV files into the appropriate database tables.
4. Create the required schemas and analytical views.
5. Execute the SQL analysis and feature engineering scripts after their dependencies are available.
6. Export `analytics.vw_customer_ml_features` to `outputs/customer_ml_features.csv`.
7. Open `python/feature_validation.ipynb` and run the notebook to reproduce the Python validation checks.
8. Open the Tableau workbook files to explore the dashboards, when included.

Refer to the SQL scripts and documentation for the specific table definitions and analytical logic.

## Attribution

Dataset: Olist, Brazilian E Commerce Public Dataset.

Available through [Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce). Please refer to the dataset source for licensing and usage terms.
