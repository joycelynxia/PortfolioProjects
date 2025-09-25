SELECT * FROM project.nashvillehousing;

-- populate property address data
select a.parcelid, a.propertyaddress, b.ParcelID, b.propertyaddress, ifnull(a.propertyaddress, b.propertyaddress) as replacement
from project.nashvillehousing a
join project.nashvillehousing b
	on a.ParcelID = b.ParcelID
    and a.uniqueid <> b.uniqueid
where a.PropertyAddress is null;

update project.nashvillehousing a
join project.nashvillehousing b
	on a.ParcelID = b.ParcelID 
    and a.uniqueid <> b.uniqueid
set a.propertyaddress = ifnull(a.propertyaddress, b.propertyaddress)
where a.PropertyAddress is null;
-- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- --


-- break property address into individual columns (address, city, state)
select 
substring_index(propertyaddress, ',', 1) as address
from project.nashvillehousing;

select 
substring_index(propertyaddress, ',', -1) as city
from project.nashvillehousing;

ALTER TABLE project.nashvillehousing
ADD PropertySplitAddress text,
add PropertySplitCity text;

UPDATE project.nashvillehousing
SET PropertySplitAddress = substring_index(propertyaddress, ',', 1),
	PropertySplitCity = substring_index(propertyaddress, ',', -1)
WHERE propertyaddress is not null;
-- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- --


-- break owner address into individual columns (address, city, state)

ALTER TABLE project.nashvillehousing
ADD OwnerSplitAddress text,
ADD OwnerSplitCity text,
ADD OwnerSplitState text;

UPDATE project.nashvillehousing
SET OwnerSplitAddress = substring_index(owneraddress, ',', 1),
	OwnerSplitCity = trim(substring_index(substring_index(owneraddress, ',', 2), ',', -1)),
	OwnerSplitState = substring_index(owneraddress, ',', -1)
WHERE owneraddress is not null;

-- select 
-- substring_index(owneraddress, ',', 1) as OwnerSplitAddress,
-- trim(substring_index(substring_index(owneraddress, ',', 2), ',', -1)) as OwnerSplitCity,
-- substring_index(owneraddress, ',', -1) as OwnerSplitState
-- from project.nashvillehousing;

-- SELECT OwnerSplitAddress, OwnerSplitCity, OwnerSplitState
-- from project.nashvillehousing;

-- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- --

-- change Y and N to Yes and No in 'Sold as Vacant' field
SELECT DISTINCT(soldasvacant), count(soldasvacant)
from project.nashvillehousing
group by soldasvacant
order by 2;

UPDATE project.nashvillehousing
SET soldasvacant = CASE 
	WHEN SoldAsVacant = 'N' THEN 'No'
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
    ELSE soldasvacant
END;

-- REMOVE DUPLICATES
with RowNumCTE as (
select *,
row_number() over (
	partition by ParcelID,
				 PropertyAddress, 
				 SaleDate, 
				 SalePrice, 
				 LegalReference
                 Order By 
					UniqueID
				) row_num
from project.nashvillehousing
)

select * from RowNumCTE
where row_num > 1;

DELETE n
FROM project.nashvillehousing n
JOIN (
    SELECT 
        UniqueID,
        ROW_NUMBER() OVER (
            PARTITION BY ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference
            ORDER BY UniqueID
        ) AS row_num
    FROM project.nashvillehousing
) x ON n.UniqueID = x.UniqueID
WHERE x.row_num > 1;

-- drop unused columns 
alter table project.nashvillehousing
	drop column owneraddress,
	drop column taxdistrict, 
	drop column propertyaddress;

select * from project.nashvillehousing
 