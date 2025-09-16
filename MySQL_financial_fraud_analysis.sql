SELECT * FROM bank.transactions;
Select count(*) from bank.transactions;
use bank;
CREATE TABLE transactions (
    step INT,
    type VARCHAR(20),
    amount DECIMAL(15,2),
    nameOrig VARCHAR(20),
    oldbalanceOrg DECIMAL(15,2),
    newbalanceOrig DECIMAL(15,2),
    nameDest VARCHAR(20),
    oldbalanceDest DECIMAL(15,2),
    newbalanceDest DECIMAL(15,2),
    isFraud TINYINT,
    isFlaggedFraud TINYINT
);













-- 1 Find the average transaction amount for fraudulent vs. non-fraudulent transactions.
Select isFraud, avg(amount) as avg_amount from transactions group by isFraud;

-- 2 Find the top 5 accounts (nameOrig) with the highest total transaction amount.
Select nameOrig, sum(amount) as total_transaction_amt from transactions group by nameOrig 
order by total_transaction_amt desc limit 5;

-- 3 Find the percentage of fraudulent transactions out of total transactions.
With CTE as (Select count(*) as total_transactions,
 sum(isFraud) as fraud_transactions from transactions)
 Select (fraud_transactions  * 100 / total_transactions) as fraud_percentage from CTE;
 
 -- 4 Detect Transactions with Zero Balance Before or After
Select nameOrig, nameDest, oldbalanceDest, newbalanceDest, amount from transactions 
where oldbalanceDest = 0 
OR  newbalanceDest = 0;

-- 5 Write me a query that checks if the computed new_updated_Balance is the same as the actual newbalanceDest in the table.
--  If they are equal, it returns those rows.
With CTE as (Select amount, nameOrig, oldbalanceDest, newbalanceDest, (amount+oldbalanceDest) as new_updated_balance from transactions)
Select * from CTE where new_updated_balance = newbalanceDest;

-- 6 Detecting Recursive Fraudulent Transactions
WITH RECURSIVE fraud_chain AS (SELECT nameOrig AS initial_account, nameDest AS next_account, step, amount
FROM transactions where isFraud = 1 AND type = 'TRANSFER'
     UNION ALL
SELECT fc.initial_account, t.nameDest, t.step, t.amount FROM fraud_chain fc
JOIN transactions t 
ON fc.next_account = t.nameOrig AND fc.step < t.step WHERE t.isFraud = 1 AND t.type = 'TRANSFER')
SELECT * FROM fraud_chain;

-- 7 Analyzing Fraudulent Activity over Time
With rolling_fraud as (
Select nameOrig, step, sum(isFraud) over(Partition by nameOrig order by STEP Rows
 BETWEEN 4 preceding and current row) as fraud_rolling from transactions)
Select * from rolling_fraud where fraud_rolling > 0;

-- 8. Complex Fraud Detection Using Multiple CTEs
With large_transfers as(Select nameOrig, step, amount from transactions where type = 'TRANSFER' and amount > 500000),
no_balance_change as(Select nameOrig, step, oldbalanceOrg, newbalanceOrig FROM transactions where oldbalanceOrg = newbalanceOrig),
flagged_transactions as(Select nameOrig, step from transactions where isFlaggedFraud = 1)
SELECT 
    lt.nameOrig FROM large_transfers lt JOIN no_balance_change nbc ON lt.nameOrig = nbc.nameOrig AND lt.step = nbc.step
JOIN flagged_transactions ft ON lt.nameOrig = ft.nameOrig AND lt.step = ft.step;
 
 
 