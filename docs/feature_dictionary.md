# Customer Feature Dictionary

## 1. Dataset Overview

The `analytics.vw_customer_ml_features` view contains customer level analytical features derived from the Olist Brazilian E Commerce dataset.

| Attribute | Description |
|---|---|
| Dataset name | Customer ML Features |
| Source | Olist Brazilian E Commerce dataset |
| Source database | PostgreSQL |
| Source view | `analytics.vw_customer_ml_features` |
| Export file | `outputs/customer_ml_features.csv` |
| Total records | 96,096 |
| Total columns | 20 |
| Record granularity | One row per unique customer |

Each record represents one customer, identified by `customer_unique_id`.

## 2. Feature Definitions

### Customer Identification

| Column | Data type | Definition |
|---|---|---|
| `customer_unique_id` | object | Unique identifier representing a customer across orders. |
| `customer_id_count` | int64 | Number of distinct customer ID records associated with the unique customer ID. |

### Customer Geography

| Column | Data type | Definition |
|---|---|---|
| `customer_city` | object | City associated with the customer record. |
| `customer_state` | object | Brazilian state associated with the customer record. |

### Order Activity

| Column | Data type | Definition |
|---|---|---|
| `total_orders` | int64 | Total number of orders associated with the customer. |
| `delivered_orders` | int64 | Number of orders with delivered status. |
| `canceled_orders` | int64 | Number of orders with canceled status. |
| `unavailable_orders` | int64 | Number of orders with unavailable status. |

### Financial Features

| Column | Data type | Definition |
|---|---|---|
| `delivered_item_revenue` | float64 | Total product item revenue from delivered orders. |
| `delivered_freight` | float64 | Total freight charges associated with delivered orders. |
| `delivered_item_count` | int64 | Total number of delivered order items associated with the customer. |
| `average_delivered_order_value` | float64 | Average delivered order value for the customer. Missing when the customer has no delivered orders. |

### Purchase History

| Column | Data type | Definition |
|---|---|---|
| `first_purchase_date` | datetime64[ns] | Date of the customer's first recorded purchase. |
| `last_purchase_date` | datetime64[ns] | Date of the customer's most recent recorded purchase. |
| `recency_days` | int64 | Number of days between the customer's last purchase and the feature reference date. |
| `feature_reference_date` | datetime64[ns] | Reference date used to calculate customer recency. The dataset reference date is October 18, 2018. |

### Delivery and Customer Satisfaction

| Column | Data type | Definition |
|---|---|---|
| `average_delivery_days` | float64 | Average delivery duration for the customer's delivered orders. Missing when delivery duration cannot be calculated. |
| `average_review_score` | float64 | Average review score recorded for the customer's reviewed orders. Missing when no reviewed orders exist. |
| `reviewed_orders` | int64 | Number of orders with an associated customer review. |

### Customer Classification

| Column | Data type | Definition |
|---|---|---|
| `repeat_customer` | int64 | Binary customer classification. A value of 1 indicates more than one order. A value of 0 indicates one order. |

## 3. Missing Value Analysis

The dataset contains missing values in three numerical features.

| Feature | Missing records | Explanation |
|---|---:|---|
| `average_delivered_order_value` | 2,738 | Customers without delivered orders. |
| `average_delivery_days` | 2,746 | 2,738 customers without delivered orders and 8 customers with missing delivery timestamps. |
| `average_review_score` | 716 | Customers without reviewed orders. |

Missing values were retained as null rather than replaced with zero or estimated values.

This preserves the distinction between unavailable information and an actual numerical value of zero.

## 4. Data Validation Results

The dataset was validated using PostgreSQL and Python with Pandas.

| Validation | Result |
|---|---:|
| Unique customer records | 96,096 |
| Total orders | 99,441 |
| Delivered orders | 96,478 |
| Duplicate customer IDs | 0 |
| Duplicate complete records | 0 |
| Delivered product revenue | R$13,221,498.11 |
| Delivered freight | R$2,198,275.64 |
| Repeat customers | 2,997 |
| Failed final validation checks | 0 |

Order counts and financial totals reconciled between PostgreSQL and Python.

## 5. Feature Engineering Notes

The dataset was designed to summarize customer purchasing activity, financial contribution, delivery experience, and review behavior.

Important feature considerations:

1. `customer_unique_id` identifies the customer and should not be used as a numerical predictive feature.
2. `customer_id_count` describes the number of customer ID records associated with a unique customer.
3. Revenue and freight features include delivered orders only.
4. `repeat_customer` is derived from the customer's total order count.
5. `recency_days` uses the fixed feature reference date of October 18, 2018.

## 6. Machine Learning Considerations

This dataset is currently a descriptive customer feature dataset. It has not yet been approved as a leakage free predictive modeling dataset.

Before predictive modeling:

1. Define a prediction date and target variable.
2. Exclude features that contain information from after the prediction date.
3. Review `average_review_score` and `average_delivery_days` for potential target leakage.
4. Exclude customer identifiers from model training.
5. Evaluate missing value treatment based on the selected modeling objective.

## 7. Final Outcome

The customer feature dataset contains 96,096 unique customer records and 20 analytical columns.

It passed the defined SQL and Python validation checks, with documented source data limitations.

The dataset is ready for further exploratory analysis and feature preparation. Predictive modeling requires a separately defined target and appropriate prevention of data leakage.