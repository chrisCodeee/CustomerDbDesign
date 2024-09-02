-- Creating the Customer table
CREATE TABLE Customer (
    CustomerID VARCHAR(10) PRIMARY KEY,
    CustomerName VARCHAR(50),
    LoanID VARCHAR(10),
    Amount DECIMAL(15, 2),
    InterestRate DECIMAL(5, 2),
    StateID INT
);

-- Inserting data into the Customer table
INSERT INTO Customer (CustomerID, CustomerName, LoanID, Amount, InterestRate, StateID) VALUES
('C01', 'Alice Johnson', 'L01', 50000.00, 5.50, 101),
('C02', 'Bob Smith', 'L02', 75000.00, 6.00, 102),
('C03', 'Carol White', 'L03', 60000.00, 4.80, 103),
('C04', 'Dave Williams', 'L04', 85000.00, 5.20, 104),
('C05', 'Emma Brown', 'L05', 55000.00, 4.50, 105),
('C06', 'Frank Miller', 'L06', 40000.00, 6.50, 106),
('C07', 'Grace Davis', 'L07', 95000.00, 5.80, 107),
('C08', 'Henry Wilson', 'L08', 30000.00, 6.20, 108),
('C09', 'Irene Moore', 'L09', 70000.00, 5.00, 109),
('C10', 'Jack Taylor', 'L10', 80000.00, 5.70, 110);

-- Creating the Loan table
CREATE TABLE Loan (
    LoanID VARCHAR(10) PRIMARY KEY,
    LoanType VARCHAR(50),
    LoanAmount DECIMAL(15, 2),
    CustomerID VARCHAR(10)
);

-- Inserting data into the Loan table
INSERT INTO Loan (LoanID, LoanType, LoanAmount, CustomerID) VALUES
('L01', 'Home Loan', 50000.00, 'C01'),
('L02', 'Auto Loan', 75000.00, 'C02'),
('L03', 'Personal Loan', 60000.00, 'C03'),
('L04', 'Education Loan', 85000.00, 'C04'),
('L05', 'Business Loan', 55000.00, 'C05'),
('L06', 'Home Loan', 40000.00, 'C06'),
('L07', 'Auto Loan', 95000.00, 'C07'),
('L08', 'Personal Loan', 30000.00, 'C08'),
('L09', 'Education Loan', 70000.00, 'C09'),
('L10', 'Business Loan', 80000.00, 'C10');

-- Creating the StateMaster table
CREATE TABLE CustomerStateMaster (
    StateID INT PRIMARY KEY,
    StateName VARCHAR(50)
);

-- Inserting data into the StateMaster table
INSERT INTO CustomerStateMaster (StateID, StateName) VALUES
(101, 'Lagos'),
(102, 'Abuja'),
(103, 'Kano'),
(104, 'Delta'),
(105, 'Ido'),
(106, 'Ibadan'),
(107, 'Enugu'),
(108, 'Kaduna'),
(109, 'Ogun'),
(110, 'Anambra');

-- Creating the BranchMaster table
CREATE TABLE BranchMaster (
    BranchID VARCHAR(10) PRIMARY KEY,
    BranchName VARCHAR(50),
    Location VARCHAR(50)
);

-- Inserting data into the BranchMaster table
INSERT INTO BranchMaster (BranchID, BranchName, Location) VALUES
('B01', 'MainBranch', 'Lagos'),
('B02', 'EastBranch', 'Abuja'),
('B03', 'WestBranch', 'Kano'),
('B04', 'NorthBranch', 'Delta'),
('B05', 'SouthBranch', 'Ido'),
('B06', 'CentralBranch', 'Ibadan'),
('B07', 'PacificBranch', 'Enugu'),
('B08', 'MountainBranch', 'Kaduna'),
('B09', 'SouthernBranch', 'Ogun'),
('B10', 'GulfBranch', 'Anambra');

-------------------------------- (1) Fetch customers with the same loan amount. -----------------------------------
SELECT CustomerName, LoanAmount
FROM Loan L
JOIN Customer C ON L.LoanID = C.LoanID
GROUP BY LoanAmount, CustomerName
HAVING COUNT(*) > 1;

------------------------- (2) Find the second highest loan amount and the customer and branch associated with it. --------------------
WITH RankedLoans AS (
    SELECT L.LoanAmount, C.CustomerName, B.BranchName,
           RANK() OVER (ORDER BY L.LoanAmount DESC) AS Rank
    FROM Loan L
    JOIN Customer C ON L.CustomerID = C.CustomerID
    JOIN BranchMaster B ON B.Location = (SELECT StateName FROM StateMaster WHERE StateID = C.StateID)
)
SELECT CustomerName, BranchName, LoanAmount
FROM RankedLoans
WHERE Rank = 2;

-------------------------- (3) Get the maximum loan amount per branch and the customer name. -------------------------------------
WITH BranchLoans AS (
    SELECT B.BranchName, C.CustomerName, L.LoanAmount,
           ROW_NUMBER() OVER (PARTITION BY B.BranchName ORDER BY L.LoanAmount DESC) AS RowNum
    FROM Loan L
    JOIN Customer C ON L.CustomerID = C.CustomerID
    JOIN BranchMaster B ON B.Location = (SELECT StateName FROM StateMaster WHERE StateID = C.StateID)
)
SELECT BranchName, CustomerName, LoanAmount
FROM BranchLoans
WHERE RowNum = 1;

---------------------- (4) Branch-wise count of customers sorted by count in descending order. -------------------------------------
SELECT B.BranchName, COUNT(C.CustomerID) AS CustomerCount
FROM Customer C
JOIN BranchMaster B ON B.Location = (SELECT StateName FROM StateMaster WHERE StateID = C.StateID)
GROUP BY B.BranchName
ORDER BY CustomerCount DESC;

------------------------ (5) Fetch only the first name from the CustomerName and append the loan amount.------------------------

SELECT CONCAT(LEFT(CustomerName, CHARINDEX(' ', CustomerName)-1), '_', LoanAmount) AS CustomerName_LoanAmount
FROM Loan L
JOIN Customer C ON L.LoanID = C.LoanID;

-------------------------- (6) Fetch loans with odd amounts. ----------------------------------
SELECT LoanID, LoanType, LoanAmount
FROM Loan
WHERE LoanAmount % 2 != 0;

---------------- (7) Create a view to fetch loan details with an amount greater than $50,000.-----------------------
CREATE VIEW HighValueLoans AS
SELECT L.LoanID, L.LoanType, L.LoanAmount, C.CustomerName, B.BranchName
FROM Loan L
JOIN Customer C ON L.CustomerID = C.CustomerID
JOIN BranchMaster B ON B.Location = (SELECT StateName FROM StateMaster WHERE StateID = C.StateID)
WHERE L.LoanAmount > 50000;

SELECT * FROM HighValueLoans

------------------- (8) Create a procedure to update the loan interest rate by 2% where the loan type is 'Home Loan' and the branch is not 'MainBranch'.--
CREATE PROCEDURE UpdateHomeLoanInterestRate
AS
BEGIN
    UPDATE Customer
    SET InterestRate = InterestRate + 2
    WHERE LoanID IN (
        SELECT L.LoanID
        FROM Loan L
        JOIN BranchMaster B ON B.Location = (SELECT StateName FROM StateMaster WHERE StateID = (SELECT StateID FROM Customer WHERE LoanID = L.LoanID))
        WHERE L.LoanType = 'Home Loan' AND B.BranchName != 'MainBranch'
    );
END;

EXEC UpdateHomeLoanInterestRate

----------------------- (9) Create a stored procedure to fetch loan details along with the customer, branch, and state, including error handling. ----
CREATE PROCEDURE GetLoanDetails
AS
BEGIN
    BEGIN TRY
        SELECT L.LoanID, L.LoanType, L.LoanAmount, C.CustomerName, SM.StateName, B.BranchName
        FROM Loan L
        JOIN Customer C ON L.CustomerID = C.CustomerID
        JOIN StateMaster SM ON C.StateID = SM.StateID
        JOIN BranchMaster B ON B.Location = SM.StateName;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000);
        SET @ErrorMessage = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 16, 1);
    END CATCH
END;

EXEC GetLoanDetails






