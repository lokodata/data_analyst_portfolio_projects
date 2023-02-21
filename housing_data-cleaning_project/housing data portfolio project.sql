/*

cleaning the data of nashville housing data

generalzition: this project shows how I clean data and make it more useable for data analytics
- the following sql code shows
	1. deleting rows that are all null
	2. standardize date format
	3. populate property address data
	4. breaking out property address into individual columns (address, city, state)
	5. breaking out owner address into individual columns (address, city, state)
		using parsename
	6. change Y and N to Yes and No in "Sold as Vacant" field
	7. deleting unused columns
	8. deleting duplicates

*/


select *
from portfolioproject_housing..nashville_housingdata


-- delete when all rows is null
delete 
from portfolioproject_housing..nashville_housingdata
where [UniqueID ] is null
and ParcelID is null


-- standardize date format
alter table portfolioproject_housing..nashville_housingdata
alter column saledate date

select saledate
from portfolioproject_housing..nashville_housingdata


-- populate property address data
select *
from portfolioproject_housing..nashville_housingdata
where PropertyAddress is null
order by ParcelID

select t1.ParcelID, t1.PropertyAddress, t2.ParcelID, t2.PropertyAddress, isnull(t1.PropertyAddress, t2.PropertyAddress) --ifnull(check, change)
from portfolioproject_housing..nashville_housingdata t1
join portfolioproject_housing..nashville_housingdata t2
on t1.ParcelID = t2.ParcelID
and t1.[UniqueID ] != t2.[UniqueID ]
where t1.PropertyAddress is null

update t1
set t1.PropertyAddress = isnull(t1.PropertyAddress, t2.PropertyAddress)
from portfolioproject_housing..nashville_housingdata t1
join portfolioproject_housing..nashville_housingdata t2
on t1.ParcelID = t2.ParcelID
and t1.[UniqueID ] != t2.[UniqueID ]


-- breaking out property address into individual columns (address, city, state)
select PropertyAddress
from portfolioproject_housing..nashville_housingdata

select
substring(propertyaddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address,
substring(propertyaddress, CHARINDEX(',', PropertyAddress) +1, len(propertyaddress)) as City
from portfolioproject_housing..nashville_housingdata

alter table portfolioproject_housing..nashville_housingdata
add PropertySplitAddress nvarchar(255)

update portfolioproject_housing..nashville_housingdata
set propertysplitaddress = substring(propertyaddress, 1, CHARINDEX(',', PropertyAddress) -1) 

alter table portfolioproject_housing..nashville_housingdata
add PropertySplitCity nvarchar(255)

update portfolioproject_housing..nashville_housingdata
set propertysplitcity= substring(propertyaddress, CHARINDEX(',', PropertyAddress) +1, len(propertyaddress))

select PropertyAddress, propertysplitaddress, propertysplitcity 
from portfolioproject_housing..nashville_housingdata


-- breaking out owner's address into individual columns (address, city, state)
-- using parsename (easier way)
select OwnerAddress
from portfolioproject_housing..nashville_housingdata

insert into portfolioproject_housing..nashville_housingdata (OwnerAddressSplitAddress, OwnerAddressSplitCity, OwnerAddressSplitState)
select
parsename(replace(OwnerAddress, ',', '.'), 3) OwnerAddressSplitAddress,
parsename(replace(OwnerAddress, ',', '.'), 2) OwnerAddressSplitCity,
parsename(replace(OwnerAddress, ',', '.'), 1) OwnerAddressSplitState
from portfolioproject_housing..nashville_housingdata
order by 1 desc

alter table portfolioproject_housing..nashville_housingdata
add OwnerAddressSplitAddress nvarchar(255),
OwnerAddressSplitCity nvarchar(255),
OwnerAddressSplitState nvarchar(255)

update portfolioproject_housing..nashville_housingdata
set OwnerAddressSplitAddress = parsename(replace(OwnerAddress, ',', '.'), 3)

update portfolioproject_housing..nashville_housingdata
set OwnerAddressSplitCity = parsename(replace(OwnerAddress, ',', '.'), 2)

update portfolioproject_housing..nashville_housingdata
set OwnerAddressSplitState = parsename(replace(OwnerAddress, ',', '.'), 1)

select OwnerAddress, OwnerAddressSplitAddress, OwnerAddressSplitCity, OwnerAddressSplitState
from portfolioproject_housing..nashville_housingdata


-- Change Y and N to Yes and No in "Sold as Vacant" field
select distinct(SoldAsVacant), count(SoldAsVacant)
from portfolioproject_housing..nashville_housingdata
group by SoldAsVacant
order by 2

select SoldAsVacant,
case
	when SoldAsVacant = 'y' then 'Yes'
	when SoldAsVacant = 'n' then 'No'
	else SoldAsVacant
end 
from portfolioproject_housing..nashville_housingdata

update portfolioproject_housing..nashville_housingdata
set SoldAsVacant = case
	when SoldAsVacant = 'y' then 'Yes'
	when SoldAsVacant = 'n' then 'No'
	else SoldAsVacant
end 


-- Remove Duplicates (prefer use temp table before doing this)
with duplicates as
(select *,
ROW_NUMBER () over (partition by parcelid, propertyaddress, saleprice, saledate, legalreference order by parcelid) row_num
from portfolioproject_housing..nashville_housingdata)

delete 
from duplicates
where row_num > 1


-- Delete Unused Columns (do not use to raw data)
alter table portfolioproject_housing..nashville_housingdata
drop column  owneraddress, taxdistrict, propertyaddress, saledate

select *
from portfolioproject_housing..nashville_housingdata
