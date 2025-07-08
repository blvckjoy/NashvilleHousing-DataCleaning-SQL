CREATE DATABASE NashvilleHousingDB;

USE NashvilleHousingDB;


-- Copying The Original Database Into A New Table For Cleaning
DROP TABLE IF EXISTS Nashville_Housing_Clean;
SELECT *
INTO Nashville_Housing_Clean
FROM Nashville_Housing;


-- Populating Property Address Data
SELECT
    nv1.ParcelID,
    nv1.PropertyAddress,
    nv2.ParcelID,
    nv2.PropertyAddress
FROM Nashville_Housing_Clean nv1
    JOIN Nashville_Housing_Clean nv2
    ON nv1.ParcelID = nv2.ParcelID
        AND nv1.UniqueID != nv2.UniqueID
WHERE 
    nv1.PropertyAddress IS NULL AND
    nv2.PropertyAddress IS NOT NULL;


UPDATE nv1
SET nv1.PropertyAddress = nv2.PropertyAddress
FROM Nashville_Housing_Clean nv1
    INNER JOIN Nashville_Housing_Clean nv2
    ON nv1.ParcelID = nv2.ParcelID
        AND nv1.UniqueID != nv2.UniqueID
WHERE 
    nv1.PropertyAddress IS NULL AND
    nv2.PropertyAddress IS NOT NULL;



-- Standardize Data --
--Split Property Address
SELECT PropertyAddress
FROM Nashville_Housing_Clean

SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address, SUBSTRING(PropertyAddress,  CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS City
FROM Nashville_Housing_Clean


ALTER TABLE Nashville_Housing_Clean
ADD PropertySplitAddress NVARCHAR(100)

UPDATE Nashville_Housing_Clean
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1);


ALTER TABLE Nashville_Housing_Clean
ADD PropertySplitCity NVARCHAR(50);

UPDATE Nashville_Housing_Clean
SET PropertySplitCity = SUBSTRING(PropertyAddress,  CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress));


-- Split Owner Address
SELECT OwnerAddress
FROM Nashville_Housing_Clean

SELECT
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM Nashville_Housing_Clean


ALTER TABLE Nashville_Housing_Clean
ADD OwnerSplitAddress NVARCHAR(100)

UPDATE Nashville_Housing_Clean
SET OwnerSplitAddress =  PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)


ALTER TABLE Nashville_Housing_Clean
ADD OwnerSplitCity NVARCHAR(50);

UPDATE Nashville_Housing_Clean
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)


ALTER TABLE Nashville_Housing_Clean
ADD OwnerSplitState NVARCHAR(50);

UPDATE Nashville_Housing_Clean
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)


-- Change 'Y' and 'N' to 'Yes' and 'No'
SELECT
    DISTINCT(SoldAsVacant),
    COUNT(SoldAsVacant)
FROM Nashville_Housing_Clean
GROUP BY SoldAsVacant
ORDER BY 2;


SELECT SoldAsVacant,
    CASE 
        WHEN SoldAsVacant = 'Y' THEN 'Yes'
        WHEN SoldAsVacant = 'N' THEN 'No'
        ELSE SoldAsVacant
    END
FROM Nashville_Housing_Clean;

UPDATE Nashville_Housing_Clean
SET SoldAsVacant = CASE 
        WHEN SoldAsVacant = 'Y' THEN 'Yes'
        WHEN SoldAsVacant = 'N' THEN 'No'
        ELSE SoldAsVacant
    END;


-- Remove Duplicates
WITH
    CTE_Duplicates
    AS
    (
        SELECT *,
            ROW_NUMBER() OVER (
            PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
        ORDER BY UniqueID
        ) AS row_num
        FROM Nashville_Housing_Clean
    )
-- DELETE FROM CTE_Duplicates
-- WHERE row_num > 1;
SELECT *
FROM CTE_Duplicates
WHERE row_num > 1;



-- Delete Unused Columns
ALTER TABLE Nashville_Housing_Clean
DROP COLUMN OwnerAddress;

ALTER TABLE Nashville_Housing_Clean
DROP COLUMN PropertyAddress;

ALTER TABLE Nashville_Housing_Clean
DROP COLUMN TaxDistrict;
